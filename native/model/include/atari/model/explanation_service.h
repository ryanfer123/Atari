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
  std::vector<std::string> context;
};

struct Prompt {
  std::string system;
  std::string user;
};

struct GenerationOptions {
  std::uint32_t max_output_tokens = 48;
  float temperature = 0.2F;
  float top_p = 0.9F;
  std::uint64_t seed = 42;
};

struct GenerationResult {
  bool success = false;
  std::string text;
  std::string error;
};

class ModelRuntime {
 public:
  virtual ~ModelRuntime() = default;

  [[nodiscard]] virtual bool is_ready() const = 0;
  virtual GenerationResult generate(
      const Prompt& prompt,
      const GenerationOptions& options) = 0;
};

struct ExplanationResult {
  std::string text;
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
