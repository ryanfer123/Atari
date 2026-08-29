#include <jni.h>
#include <string>
#include <vector>
#include <sstream>

#include "atari/model/explanation_service.h"
#include "atari/model/source_selection_service.h"

using namespace atari::model;

namespace {

std::string jstring_to_string(JNIEnv* env, jstring j_str) {
    if (!j_str) return "";
    const char* chars = env->GetStringUTFChars(j_str, nullptr);
    std::string result(chars ? chars : "");
    if (chars) {
        env->ReleaseStringUTFChars(j_str, chars);
    }
    return result;
}

jstring string_to_jstring(JNIEnv* env, const std::string& str) {
    return env->NewStringUTF(str.c_str());
}

}  // namespace

extern "C" {

JNIEXPORT jstring JNICALL
Java_com_atari_slm_SlmBridge_nativeBuildPrompt(
    JNIEnv* env,
    jclass /*clazz*/,
    jdouble fragmentation_score,
    jdouble app_switch_z,
    jdouble unlock_z,
    jdouble notif_z,
    jstring time_bucket,
    jobjectArray context_sources,
    jobjectArray context_texts) {

    BehavioralEvidence evidence;
    evidence.fragmentation_score = fragmentation_score;
    if (app_switch_z > -999.0) evidence.app_switch_z_score = app_switch_z;
    if (unlock_z > -999.0) evidence.unlock_z_score = unlock_z;
    if (notif_z > -999.0) evidence.notification_z_score = notif_z;
    evidence.time_bucket = jstring_to_string(env, time_bucket);

    if (context_sources && context_texts) {
        jsize len = env->GetArrayLength(context_sources);
        for (jsize i = 0; i < len; ++i) {
            auto src = static_cast<jstring>(env->GetObjectArrayElement(context_sources, i));
            auto txt = static_cast<jstring>(env->GetObjectArrayElement(context_texts, i));
            evidence.context_bullets.push_back({
                jstring_to_string(env, src),
                jstring_to_string(env, txt)
            });
            if (src) env->DeleteLocalRef(src);
            if (txt) env->DeleteLocalRef(txt);
        }
    }

    Prompt p = ExplanationService::build_prompt(evidence);
    std::string combined = p.system + "\n---\n" + p.user;
    return string_to_jstring(env, combined);
}

JNIEXPORT jstring JNICALL
Java_com_atari_slm_SlmBridge_nativeFallbackText(
    JNIEnv* env,
    jclass /*clazz*/,
    jdouble fragmentation_score,
    jdouble app_switch_z,
    jdouble unlock_z,
    jdouble notif_z,
    jstring time_bucket) {

    BehavioralEvidence evidence;
    evidence.fragmentation_score = fragmentation_score;
    if (app_switch_z > -999.0) evidence.app_switch_z_score = app_switch_z;
    if (unlock_z > -999.0) evidence.unlock_z_score = unlock_z;
    if (notif_z > -999.0) evidence.notification_z_score = notif_z;
    evidence.time_bucket = jstring_to_string(env, time_bucket);

    std::string fallback = ExplanationService::fallback_text(evidence);
    return string_to_jstring(env, fallback);
}

JNIEXPORT jboolean JNICALL
Java_com_atari_slm_SlmBridge_nativeIsSafeOutput(
    JNIEnv* env,
    jclass /*clazz*/,
    jstring output) {

    std::string text = jstring_to_string(env, output);
    return ExplanationService::is_safe_output(text) ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jstring JNICALL
Java_com_atari_slm_SlmBridge_nativeSourceSelectionSchema(
    JNIEnv* env,
    jclass /*clazz*/,
    jstring trigger_signal,
    jstring top_signal,
    jintArray allowed_source_ids,
    jint max_sources) {

    SourceSelectionRequest req;
    req.trigger_signal = jstring_to_string(env, trigger_signal);
    req.top_signal = jstring_to_string(env, top_signal);

    if (allowed_source_ids) {
        jsize len = env->GetArrayLength(allowed_source_ids);
        jint* ids = env->GetIntArrayElements(allowed_source_ids, nullptr);
        for (jsize i = 0; i < len; ++i) {
            req.allowed_sources.push_back(static_cast<GoalContextSource>(ids[i]));
        }
        env->ReleaseIntArrayElements(allowed_source_ids, ids, JNI_ABORT);
    }

    std::string schema = SourceSelectionService::response_json_schema(req, static_cast<std::size_t>(max_sources));
    return string_to_jstring(env, schema);
}

JNIEXPORT jintArray JNICALL
Java_com_atari_slm_SlmBridge_nativeParseSourceSelection(
    JNIEnv* env,
    jclass /*clazz*/,
    jstring json_response) {

    std::string resp = jstring_to_string(env, json_response);
    std::vector<GoalContextSource> sources = SourceSelectionService::parse_response(resp);

    jintArray result = env->NewIntArray(static_cast<jsize>(sources.size()));
    if (result && !sources.empty()) {
        std::vector<jint> int_ids;
        int_ids.reserve(sources.size());
        for (auto s : sources) {
            int_ids.push_back(static_cast<jint>(s));
        }
        env->SetIntArrayRegion(result, 0, static_cast<jsize>(int_ids.size()), int_ids.data());
    }
    return result;
}

}  // extern "C"
