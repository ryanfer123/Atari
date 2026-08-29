#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace atari::model {

struct BehavioralEvidence {
  double fragmentation_score = 0.0;
  std::optional<double> app_switch_z_score;
  std::optional<double> unlock_z_score;
  std::optional<double> notification_z_score;
  std::string time_bucket;
  struct ContextBullet {
    std::string source;
    std::string text;
  };

  std::vector<ContextBullet> context_bullets;
};

struct Prompt {
  std::string system;
  std::string user;
};

struct GenerationOptions {
  std::uint32_t max_output_tokens = 48;
  float temperature = 0.2F;
  float top_p = 0.9F;
  std::uint32_t top_k = 20;
  std::uint64_t seed = 42;
  std::optional<std::string> response_json_schema;
};

struct GenerationResult {
  bool success = false;
  std::string text;
  std::string error;
};

// Directs a ModelRuntime at a specific on-device model file. Deliberately
// minimal — just what "point the runtime at this GGUF file" requires — not
// a generic engine-configuration struct; add fields only as a concrete
// implementation actually needs them (context length, thread count, etc.).
struct ModelConfig {
  std::string model_path;
};

class ModelRuntime {
 public:
  virtual ~ModelRuntime() = default;

  // Directs this runtime at config.model_path. Returns false (and leaves
  // is_ready() false) if the path doesn't resolve to a loadable model —
  // a concrete implementation decides what "loadable" means for it
  // (existence/format check now; actual weight loading once a real
  // inference engine, e.g. llama.cpp, is wired in — see
  // native/model/README.md). Callers must call load() before relying on
  // is_ready()/generate(); a runtime that hasn't had load() called is
  // not ready by definition.
  virtual bool load(const ModelConfig& config) = 0;

  [[nodiscard]] virtual bool is_ready() const = 0;
  virtual GenerationResult generate(
      const Prompt& prompt,
      const GenerationOptions& options) = 0;
};

struct ExplanationResult {
  std::string text;
  std::vector<BehavioralEvidence::ContextBullet> context_bullets;
  bool used_model = false;
  std::string fallback_reason;
};

class ExplanationService {
 public:
  explicit ExplanationService(ModelRuntime& runtime);

  [[nodiscard]] ExplanationResult explain(const BehavioralEvidence& evidence) const;

  [[nodiscard]] static Prompt build_prompt(const BehavioralEvidence& evidence);
  [[nodiscard]] static std::string fallback_text(const BehavioralEvidence& evidence);
  [[nodiscard]] static bool is_safe_output(const std::string& output);

 private:
  ModelRuntime& runtime_;
};

}  // namespace atari::model
