#pragma once

#include <cstddef>
#include <string>
#include <vector>

#include "atari/model/explanation_service.h"

namespace atari::model {

enum class GoalContextSource {
  kNotes,
  kTodos,
  kHealthTargets,
  kCalendar,
  kCaptureHistory,
};

struct SourceSelectionRequest {
  std::string trigger_signal;
  std::string top_signal;
  std::vector<GoalContextSource> allowed_sources;
};

struct SourceSelectionResult {
  std::vector<GoalContextSource> sources;
  bool used_model = false;
  std::string fallback_reason;
};

class SourceSelectionService {
 public:
  explicit SourceSelectionService(ModelRuntime& runtime, std::size_t max_sources = 3);

  [[nodiscard]] SourceSelectionResult select(const SourceSelectionRequest& request) const;

  [[nodiscard]] static Prompt build_prompt(const SourceSelectionRequest& request,
                                           std::size_t max_sources);
  [[nodiscard]] static std::string response_json_schema(
      const SourceSelectionRequest& request,
      std::size_t max_sources);
  [[nodiscard]] static std::vector<GoalContextSource> parse_response(
      const std::string& response);
  [[nodiscard]] static std::string source_name(GoalContextSource source);

 private:
  ModelRuntime& runtime_;
  std::size_t max_sources_;
};

}  // namespace atari::model
