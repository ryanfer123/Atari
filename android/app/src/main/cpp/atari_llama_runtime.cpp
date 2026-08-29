#include <android/log.h>
#include <jni.h>
#include <unistd.h>

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

#include "ggml-backend.h"
#include "llama.h"

namespace {

constexpr char kLogTag[] = "AtariLlama";
constexpr int kBatchSize = 512;
constexpr int kMinThreads = 2;
constexpr int kMaxThreads = 4;

std::mutex g_mutex;
llama_model* g_model = nullptr;
llama_context* g_context = nullptr;
llama_sampler* g_sampler = nullptr;
bool g_backend_initialized = false;
int64_t g_load_ms = 0;
int64_t g_generation_ms = 0;
int64_t g_ttft_ms = 0;
int g_generated_tokens = 0;
uint32_t g_context_tokens = 0;
std::string g_model_path;

void log_message(ggml_log_level level, const char* text, void*) {
    const int priority = level >= GGML_LOG_LEVEL_ERROR ? ANDROID_LOG_ERROR
        : level == GGML_LOG_LEVEL_WARN ? ANDROID_LOG_WARN
        : ANDROID_LOG_INFO;
    __android_log_write(priority, kLogTag, text);
}

std::string from_jstring(JNIEnv* env, jstring value) {
    if (value == nullptr) return {};
    const char* chars = env->GetStringUTFChars(value, nullptr);
    const std::string result = chars == nullptr ? "" : chars;
    if (chars != nullptr) env->ReleaseStringUTFChars(value, chars);
    return result;
}

void unload_locked() {
    if (g_sampler != nullptr) {
        llama_sampler_free(g_sampler);
        g_sampler = nullptr;
    }
    if (g_context != nullptr) {
        llama_free(g_context);
        g_context = nullptr;
    }
    if (g_model != nullptr) {
        llama_model_free(g_model);
        g_model = nullptr;
    }
    g_model_path.clear();
    g_context_tokens = 0;
}

std::string format_chat_prompt(const std::string& prompt) {
    const char* chat_template = llama_model_chat_template(g_model, nullptr);
    if (chat_template == nullptr) return prompt;

    const llama_chat_message message{"user", prompt.c_str()};
    int32_t length = llama_chat_apply_template(
        chat_template, &message, 1, true, nullptr, 0);
    if (length <= 0) return prompt;

    std::vector<char> formatted(static_cast<size_t>(length) + 1);
    length = llama_chat_apply_template(
        chat_template, &message, 1, true, formatted.data(), formatted.size());
    if (length <= 0) return prompt;
    return {formatted.data(), static_cast<size_t>(length)};
}

std::string token_piece(const llama_vocab* vocab, llama_token token) {
    std::vector<char> buffer(256);
    int32_t length = llama_token_to_piece(
        vocab, token, buffer.data(), buffer.size(), 0, true);
    if (length < 0) {
        buffer.resize(static_cast<size_t>(-length));
        length = llama_token_to_piece(
            vocab, token, buffer.data(), buffer.size(), 0, true);
    }
    return length > 0 ? std::string(buffer.data(), static_cast<size_t>(length)) : "";
}

}  // namespace

extern "C" JNIEXPORT jint JNICALL
Java_com_atari_slm_SlmBridge_nativeRuntimeInit(
    JNIEnv* env, jclass, jstring native_library_dir) {
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_backend_initialized) return 0;

    llama_log_set(log_message, nullptr);
    const std::string library_dir = from_jstring(env, native_library_dir);
    // Dynamic backend loading disabled in CMake; CPU backend is statically linked.
    llama_backend_init();
    g_backend_initialized = true;
    return 0;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_atari_slm_SlmBridge_nativeLoadModel(
    JNIEnv* env, jclass, jstring model_path, jint context_tokens) {
    std::lock_guard<std::mutex> lock(g_mutex);
    if (!g_backend_initialized) return 1;

    unload_locked();
    const std::string path = from_jstring(env, model_path);
    const auto started = std::chrono::steady_clock::now();

    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0;
    g_model = llama_model_load_from_file(path.c_str(), model_params);
    if (g_model == nullptr) return 2;

    llama_context_params context_params = llama_context_default_params();
    const int processors = static_cast<int>(sysconf(_SC_NPROCESSORS_ONLN));
    const int threads = std::max(kMinThreads, std::min(kMaxThreads, processors - 2));
    context_params.n_ctx = static_cast<uint32_t>(std::max(512, context_tokens));
    context_params.n_batch = kBatchSize;
    context_params.n_ubatch = kBatchSize;
    context_params.n_threads = threads;
    context_params.n_threads_batch = threads;
    g_context = llama_init_from_model(g_model, context_params);
    if (g_context == nullptr) {
        unload_locked();
        return 3;
    }

    g_sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
    llama_sampler_chain_add(g_sampler, llama_sampler_init_min_p(0.05f, 1));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_temp(0.3f));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_dist(42));

    g_model_path = path;
    g_context_tokens = llama_n_ctx(g_context);
    g_load_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now() - started).count();
    return 0;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_atari_slm_SlmBridge_nativeGenerate(
    JNIEnv* env, jclass, jstring raw_prompt, jint max_tokens) {
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_model == nullptr || g_context == nullptr || g_sampler == nullptr) {
        return env->NewStringUTF("");
    }

    llama_memory_clear(llama_get_memory(g_context), false);
    llama_sampler_reset(g_sampler);
    const std::string prompt = format_chat_prompt(from_jstring(env, raw_prompt));
    const llama_vocab* vocab = llama_model_get_vocab(g_model);

    int32_t token_count = -llama_tokenize(
        vocab, prompt.c_str(), prompt.size(), nullptr, 0, true, true);
    if (token_count <= 0 || token_count >= static_cast<int32_t>(g_context_tokens)) {
        return env->NewStringUTF("");
    }
    std::vector<llama_token> prompt_tokens(static_cast<size_t>(token_count));
    if (llama_tokenize(vocab, prompt.c_str(), prompt.size(), prompt_tokens.data(),
            prompt_tokens.size(), true, true) < 0) {
        return env->NewStringUTF("");
    }

    const auto started = std::chrono::steady_clock::now();
    llama_batch batch = llama_batch_get_one(prompt_tokens.data(), prompt_tokens.size());
    std::string output;
    g_generated_tokens = 0;
    g_ttft_ms = 0;

    for (int index = 0; index < std::max(1, max_tokens); ++index) {
        if (llama_decode(g_context, batch) != 0) break;
        llama_token token = llama_sampler_sample(g_sampler, g_context, -1);
        if (llama_vocab_is_eog(vocab, token)) break;
        if (g_generated_tokens == 0) {
            g_ttft_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::steady_clock::now() - started).count();
        }
        output += token_piece(vocab, token);
        ++g_generated_tokens;
        batch = llama_batch_get_one(&token, 1);
    }

    g_generation_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now() - started).count();
    return env->NewStringUTF(output.c_str());
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_atari_slm_SlmBridge_nativeRuntimeMetrics(JNIEnv* env, jclass) {
    std::lock_guard<std::mutex> lock(g_mutex);
    std::ostringstream json;
    json << "{\"modelLoaded\":" << (g_model != nullptr ? "true" : "false")
         << ",\"contextTokens\":" << g_context_tokens
         << ",\"loadMs\":" << g_load_ms
         << ",\"generationMs\":" << g_generation_ms
         << ",\"ttftMs\":" << g_ttft_ms
         << ",\"generatedTokens\":" << g_generated_tokens << "}";
    return env->NewStringUTF(json.str().c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_atari_slm_SlmBridge_nativeUnloadModel(JNIEnv*, jclass) {
    std::lock_guard<std::mutex> lock(g_mutex);
    unload_locked();
}
