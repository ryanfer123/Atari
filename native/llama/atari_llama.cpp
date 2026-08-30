// JNI bridge from Kotlin to llama.cpp.
//
// Deliberately narrow: load a GGUF, generate under a grammar, embed a
// string, free. Everything about *what* to generate — prompts, the
// closed enums, validation, fallbacks — stays on the Dart/Kotlin side
// where it is testable without a 2.5GB model. See
// Plans/PIVOT_PLAN.md §2.3.
//
// Only one model is held at a time; that policy lives in
// LlamaBridge.kt, per Plans/PIVOT_PLAN.md §2.2.

#include <jni.h>
#include <android/log.h>

#include <cmath>
#include <cstring>
#include <string>
#include <vector>

#include "llama.h"

#define LOG_TAG "AtariLlama"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace {

struct Session {
    llama_model *model = nullptr;
    llama_context *ctx = nullptr;
    const llama_vocab *vocab = nullptr;
    bool embedding = false;
};

bool g_backend_ready = false;

/// Throws a Java exception so failures surface as Kotlin exceptions
/// rather than silent nulls the caller has to guess about.
void throwJava(JNIEnv *env, const char *message) {
    jclass cls = env->FindClass("java/lang/RuntimeException");
    if (cls != nullptr) env->ThrowNew(cls, message);
}

std::vector<llama_token> tokenize(const llama_vocab *vocab, const std::string &text, bool add_special) {
    // Negative return is the required capacity; call twice rather than
    // guessing a bound.
    int32_t needed = -llama_tokenize(vocab, text.data(), (int32_t) text.size(), nullptr, 0, add_special, true);
    if (needed <= 0) return {};

    std::vector<llama_token> tokens(needed);
    int32_t written = llama_tokenize(
        vocab, text.data(), (int32_t) text.size(), tokens.data(), needed, add_special, true);
    if (written < 0) return {};
    tokens.resize(written);
    return tokens;
}

/// Frees a sampler chain however the scope is left.
///
/// llama.cpp throws for a grammar it cannot advance, and that path runs
/// between creating the chain and freeing it.
struct SamplerGuard {
    llama_sampler *chain;
    explicit SamplerGuard(llama_sampler *c) : chain(c) {}
    ~SamplerGuard() { if (chain != nullptr) llama_sampler_free(chain); }
    SamplerGuard(const SamplerGuard &) = delete;
    SamplerGuard &operator=(const SamplerGuard &) = delete;
};

std::string pieceFor(const llama_vocab *vocab, llama_token token) {
    char buf[256];
    int32_t n = llama_token_to_piece(vocab, token, buf, sizeof(buf), 0, false);
    if (n < 0) return {};
    return std::string(buf, n);
}

} // namespace

extern "C" {

JNIEXPORT void JNICALL
Java_com_atari_atari_LlamaBridge_nativeInit(JNIEnv *, jobject) {
    if (g_backend_ready) return;
    llama_backend_init();
    // llama.cpp is chatty at INFO; keep only real problems in logcat.
    // Only genuine problems. Note CONT (5) sorts *above* ERROR (4) but
    // means "continuation of the previous line" — a `>=` test would
    // spray every model-loading progress dot into logcat as an error.
    llama_log_set([](ggml_log_level level, const char *text, void *) {
        if (level == GGML_LOG_LEVEL_ERROR || level == GGML_LOG_LEVEL_WARN) {
            LOGE("%s", text);
        }
    }, nullptr);
    g_backend_ready = true;
}

JNIEXPORT jlong JNICALL
Java_com_atari_atari_LlamaBridge_nativeLoad(
    JNIEnv *env, jobject, jstring pathIn, jint contextSize, jboolean embedding, jint threads) {

  try {
    const char *path = env->GetStringUTFChars(pathIn, nullptr);
    if (path == nullptr) return 0;

    llama_model_params mp = llama_model_default_params();
    // CPU only. The device's GPU/NPU has no llama.cpp backend we build
    // here, and mmap keeps the 2.5GB weights out of the app's dirty
    // memory so the kernel can evict pages under pressure.
    mp.n_gpu_layers = 0;
    // mmap (not mlock) keeps the 2.5GB of weights as clean, evictable
    // pages rather than dirty app memory, so the kernel can reclaim them
    // under pressure instead of the app being killed.
    mp.load_mode = LLAMA_LOAD_MODE_MMAP;

    llama_model *model = llama_model_load_from_file(path, mp);
    env->ReleaseStringUTFChars(pathIn, path);

    if (model == nullptr) {
        throwJava(env, "llama_model_load_from_file returned null");
        return 0;
    }

    llama_context_params cp = llama_context_default_params();
    cp.n_ctx = (uint32_t) contextSize;
    cp.n_batch = (uint32_t) contextSize;
    cp.n_threads = threads;
    cp.n_threads_batch = threads;
    cp.embeddings = embedding == JNI_TRUE;
    if (cp.embeddings) {
        // Mean pooling gives one vector per sequence, which is what the
        // cosine search in EmbeddingService expects.
        cp.pooling_type = LLAMA_POOLING_TYPE_MEAN;
    }

    llama_context *ctx = llama_init_from_model(model, cp);
    if (ctx == nullptr) {
        llama_model_free(model);
        throwJava(env, "llama_init_from_model returned null");
        return 0;
    }

    auto *session = new Session();
    session->model = model;
    session->ctx = ctx;
    session->vocab = llama_model_get_vocab(model);
    session->embedding = cp.embeddings;
    return reinterpret_cast<jlong>(session);
  } catch (const std::exception &e) {
    throwJava(env, e.what());
    return 0;
  } catch (...) {
    throwJava(env, "Unknown native failure while loading the model");
    return 0;
  }
}

JNIEXPORT void JNICALL
Java_com_atari_atari_LlamaBridge_nativeFree(JNIEnv *, jobject, jlong handle) {
    auto *session = reinterpret_cast<Session *>(handle);
    if (session == nullptr) return;
    if (session->ctx != nullptr) llama_free(session->ctx);
    if (session->model != nullptr) llama_model_free(session->model);
    delete session;
}

JNIEXPORT jint JNICALL
Java_com_atari_atari_LlamaBridge_nativeEmbeddingDim(JNIEnv *, jobject, jlong handle) {
    auto *session = reinterpret_cast<Session *>(handle);
    if (session == nullptr) return 0;
    return llama_model_n_embd(session->model);
}

/// Generates text, optionally constrained by a GBNF grammar.
///
/// Sampling is greedy: these calls choose from a closed enum, so a
/// deterministic answer is the point — the grammar makes malformed
/// output impossible to emit rather than something to detect afterwards.
JNIEXPORT jstring JNICALL
Java_com_atari_atari_LlamaBridge_nativeGenerate(
    JNIEnv *env, jobject, jlong handle, jstring promptIn, jint maxTokens, jstring grammarIn) {

  // llama.cpp reports bad input by throwing. An exception escaping a
  // JNI frame calls std::terminate and takes the whole app down, so
  // everything below is converted into a Java exception instead.
  try {
    auto *session = reinterpret_cast<Session *>(handle);
    if (session == nullptr) {
        throwJava(env, "No model is loaded");
        return nullptr;
    }

    const char *promptChars = env->GetStringUTFChars(promptIn, nullptr);
    std::string prompt = promptChars == nullptr ? "" : promptChars;
    if (promptChars != nullptr) env->ReleaseStringUTFChars(promptIn, promptChars);

    // Each call is independent; without clearing, the previous prompt's
    // KV cache would silently prefix this one.
    llama_memory_clear(llama_get_memory(session->ctx), true);

    std::vector<llama_token> tokens = tokenize(session->vocab, prompt, true);
    if (tokens.empty()) {
        throwJava(env, "Prompt tokenised to nothing");
        return nullptr;
    }

    llama_sampler_chain_params sp = llama_sampler_chain_default_params();
    SamplerGuard guard(llama_sampler_chain_init(sp));
    llama_sampler *chain = guard.chain;

    if (grammarIn != nullptr) {
        const char *grammarChars = env->GetStringUTFChars(grammarIn, nullptr);
        if (grammarChars != nullptr) {
            llama_sampler *grammar = llama_sampler_init_grammar(session->vocab, grammarChars, "root");
            env->ReleaseStringUTFChars(grammarIn, grammarChars);
            if (grammar == nullptr) {
                throwJava(env, "Grammar failed to parse");
                return nullptr;
            }
            llama_sampler_chain_add(chain, grammar);
        }
    }
    llama_sampler_chain_add(chain, llama_sampler_init_greedy());

    llama_batch batch = llama_batch_get_one(tokens.data(), (int32_t) tokens.size());
    if (llama_decode(session->ctx, batch) != 0) {
        throwJava(env, "llama_decode failed on the prompt");
        return nullptr;
    }

    // Accumulated as bytes and converted once at the end: a multi-byte
    // character can straddle two tokens, so converting per piece could
    // hand Java a truncated sequence.
    std::string out;
    for (int32_t i = 0; i < maxTokens; i++) {
        // llama_sampler_sample() accepts the token into the chain
        // itself. Calling llama_sampler_accept() as well advances the
        // grammar twice per token, which empties its stack and makes
        // llama.cpp throw ("Unexpected empty grammar stack").
        llama_token id = llama_sampler_sample(chain, session->ctx, -1);
        if (llama_vocab_is_eog(session->vocab, id)) break;

        out += pieceFor(session->vocab, id);

        llama_batch next = llama_batch_get_one(&id, 1);
        if (llama_decode(session->ctx, next) != 0) break;
    }

    return env->NewStringUTF(out.c_str());
  } catch (const std::exception &e) {
    throwJava(env, e.what());
    return nullptr;
  } catch (...) {
    throwJava(env, "Unknown native failure during generation");
    return nullptr;
  }
}

/// Returns one L2-normalised vector for [textIn], so callers can use a
/// plain dot product as cosine similarity.
JNIEXPORT jfloatArray JNICALL
Java_com_atari_atari_LlamaBridge_nativeEmbed(JNIEnv *env, jobject, jlong handle, jstring textIn) {
  try {
    auto *session = reinterpret_cast<Session *>(handle);
    if (session == nullptr || !session->embedding) {
        throwJava(env, "No embedding model is loaded");
        return nullptr;
    }

    const char *textChars = env->GetStringUTFChars(textIn, nullptr);
    std::string text = textChars == nullptr ? "" : textChars;
    if (textChars != nullptr) env->ReleaseStringUTFChars(textIn, textChars);

    llama_memory_clear(llama_get_memory(session->ctx), true);

    std::vector<llama_token> tokens = tokenize(session->vocab, text, true);
    if (tokens.empty()) {
        throwJava(env, "Text tokenised to nothing");
        return nullptr;
    }

    llama_batch batch = llama_batch_get_one(tokens.data(), (int32_t) tokens.size());
    const int32_t rc = llama_model_has_encoder(session->model)
        ? llama_encode(session->ctx, batch)
        : llama_decode(session->ctx, batch);
    if (rc != 0) {
        throwJava(env, "Encoding the text for embedding failed");
        return nullptr;
    }

    const int32_t dim = llama_model_n_embd(session->model);
    const float *raw = llama_get_embeddings_seq(session->ctx, 0);
    if (raw == nullptr) {
        throwJava(env, "No pooled embedding was produced");
        return nullptr;
    }

    double sum = 0.0;
    for (int32_t i = 0; i < dim; i++) sum += (double) raw[i] * raw[i];
    const float norm = sum > 0.0 ? (float) std::sqrt(sum) : 1.0f;

    std::vector<float> normalised(dim);
    for (int32_t i = 0; i < dim; i++) normalised[i] = raw[i] / norm;

    jfloatArray result = env->NewFloatArray(dim);
    if (result == nullptr) return nullptr;
    env->SetFloatArrayRegion(result, 0, dim, normalised.data());
    return result;
  } catch (const std::exception &e) {
    throwJava(env, e.what());
    return nullptr;
  } catch (...) {
    throwJava(env, "Unknown native failure during embedding");
    return nullptr;
  }
}

} // extern "C"
