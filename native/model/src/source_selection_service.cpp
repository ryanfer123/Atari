#include "atari/model/source_selection_service.h"

#include <algorithm>
#include <cctype>
#include <sstream>
#include <stdexcept>
#include <string_view>

namespace atari::model {
namespace {

constexpr std::size_t kAvailableSourceCount = 5;
constexpr std::size_t kMaxSignalCharacters = 80;

std::string trim(std::string value) {
  const auto first = std::find_if_not(value.begin(), value.end(), [](unsigned char character) {
    return std::isspace(character) != 0;
  });
  const auto last = std::find_if_not(value.rbegin(), value.rend(), [](unsigned char character) {
    return std::isspace(character) != 0;
  }).base();
  return first < last ? std::string(first, last) : std::string{};
}

void validate_signal(const std::string& signal, std::string_view name) {
  const bool has_control = std::any_of(signal.begin(), signal.end(), [](unsigned char character) {
    return std::iscntrl(character) != 0;
  });
  if (signal.empty() || signal.size() > kMaxSignalCharacters || has_control) {
    throw std::invalid_argument(std::string(name) + " must be a short, printable value");
  }
}

void validate_request(const SourceSelectionRequest& request, std::size_t max_sources) {
  validate_signal(request.trigger_signal, "trigger_signal");
  validate_signal(request.top_signal, "top_signal");
  if (max_sources == 0 || max_sources > kAvailableSourceCount) {
    throw std::invalid_argument("max_sources must be between one and five");
  }
  if (request.allowed_sources.empty() || request.allowed_sources.size() > kAvailableSourceCount) {
    throw std::invalid_argument("allowed_sources must contain between one and five sources");
  }
  auto sorted = request.allowed_sources;
  std::sort(sorted.begin(), sorted.end());
  if (std::adjacent_find(sorted.begin(), sorted.end()) != sorted.end()) {
    throw std::invalid_argument("allowed_sources must not contain duplicates");
  }
}

bool is_allowed(GoalContextSource source, const SourceSelectionRequest& request) {
  return std::find(request.allowed_sources.begin(), request.allowed_sources.end(), source) !=
         request.allowed_sources.end();
}

GoalContextSource parse_source_name(const std::string& name) {
  if (name == "NOTES") return GoalContextSource::kNotes;
  if (name == "TODOS") return GoalContextSource::kTodos;
  if (name == "HEALTH_TARGETS") return GoalContextSource::kHealthTargets;
  if (name == "CALENDAR") return GoalContextSource::kCalendar;
  if (name == "CAPTURE_HISTORY") return GoalContextSource::kCaptureHistory;
  throw std::invalid_argument("unknown context source");
}

}  // namespace

SourceSelectionService::SourceSelectionService(ModelRuntime& runtime, std::size_t max_sources)
    : runtime_(runtime), max_sources_(max_sources) {
  if (max_sources == 0 || max_sources > kAvailableSourceCount) {
    throw std::invalid_argument("max_sources must be between one and five");
  }
}

SourceSelectionResult SourceSelectionService::select(const SourceSelectionRequest& request) const {
  validate_request(request, max_sources_);
  const auto fallback = [&](std::string reason) {
    return SourceSelectionResult{request.allowed_sources, false, std::move(reason)};
  };

  if (!runtime_.is_ready()) return fallback("runtime_not_ready");

  try {
    GenerationOptions options;
    options.max_output_tokens = 40;
    options.temperature = 0.2F;
    options.top_p = 0.8F;
    options.top_k = 20;
    options.response_json_schema = response_json_schema(request, max_sources_);
    const GenerationResult generated = runtime_.generate(build_prompt(request, max_sources_), options);
    if (!generated.success) {
      return fallback(generated.error.empty() ? "generation_failed" : generated.error);
    }

    const auto selected = parse_response(generated.text);
    const bool duplicates = [&] {
      auto copy = selected;
      std::sort(copy.begin(), copy.end());
      return std::adjacent_find(copy.begin(), copy.end()) != copy.end();
    }();
    const bool disallowed = std::any_of(selected.begin(), selected.end(), [&](GoalContextSource source) {
      return !is_allowed(source, request);
    });
    if (selected.empty() || selected.size() > max_sources_ || duplicates || disallowed) {
      return fallback("invalid_source_selection");
    }
    return {selected, true, {}};
  } catch (const std::invalid_argument&) {
    return fallback("invalid_source_selection");
  } catch (const std::exception&) {
    return fallback("runtime_exception");
  }
}

Prompt SourceSelectionService::build_prompt(const SourceSelectionRequest& request,
                                            std::size_t max_sources) {
  validate_request(request, max_sources);
  Prompt prompt;
  prompt.system =
      "You select relevant ATARI context sources. Return only a JSON array containing one to " +
      std::to_string(max_sources) +
      " exact source names from the supplied allow-list. Never invent a source. /no_think";
  std::ostringstream user;
  user << "triggerSignal=" << request.trigger_signal << "\ntopSignal=" << request.top_signal
       << "\nallowedSources=[";
  for (std::size_t index = 0; index < request.allowed_sources.size(); ++index) {
    if (index > 0) user << ',';
    user << source_name(request.allowed_sources[index]);
  }
  user << ']';
  prompt.user = user.str();
  return prompt;
}

std::string SourceSelectionService::response_json_schema(const SourceSelectionRequest& request,
                                                         std::size_t max_sources) {
  validate_request(request, max_sources);
  std::ostringstream schema;
  schema << R"({"type":"array","items":{"type":"string","enum":[)";
  for (std::size_t index = 0; index < request.allowed_sources.size(); ++index) {
    if (index > 0) schema << ',';
    schema << '\"' << source_name(request.allowed_sources[index]) << '\"';
  }
  schema << R"(]},"minItems":1,"maxItems":)" << max_sources << '}';
  return schema.str();
}

std::vector<GoalContextSource> SourceSelectionService::parse_response(const std::string& response) {
  const std::string value = trim(response);
  if (value.size() < 4 || value.front() != '[' || value.back() != ']') {
    throw std::invalid_argument("selection must be a JSON array");
  }

  std::vector<GoalContextSource> sources;
  std::size_t cursor = 1;
  while (cursor < value.size() - 1) {
    while (cursor < value.size() - 1 && std::isspace(static_cast<unsigned char>(value[cursor]))) {
      ++cursor;
    }
    if (value[cursor] != '\"') throw std::invalid_argument("source must be a JSON string");
    const std::size_t end = value.find('\"', cursor + 1);
    if (end == std::string::npos) throw std::invalid_argument("unterminated source string");
    sources.push_back(parse_source_name(value.substr(cursor + 1, end - cursor - 1)));
    cursor = end + 1;
    while (cursor < value.size() - 1 && std::isspace(static_cast<unsigned char>(value[cursor]))) {
      ++cursor;
    }
    if (cursor == value.size() - 1) break;
    if (value[cursor] != ',') throw std::invalid_argument("sources must be comma separated");
    ++cursor;
  }
  return sources;
}

std::string SourceSelectionService::source_name(GoalContextSource source) {
  switch (source) {
    case GoalContextSource::kNotes: return "NOTES";
    case GoalContextSource::kTodos: return "TODOS";
    case GoalContextSource::kHealthTargets: return "HEALTH_TARGETS";
    case GoalContextSource::kCalendar: return "CALENDAR";
    case GoalContextSource::kCaptureHistory: return "CAPTURE_HISTORY";
  }
  throw std::invalid_argument("unknown context source");
}

}  // namespace atari::model
