/// State machine driven by `Orchestrator` (`lib/engine/orchestration`).
///
/// `NORMAL -> OVERLOAD_DETECTED -> INTERVENING -> COOLDOWN -> NORMAL`.
/// See Plans/IMPLEMENTATION.md §4.2.
enum AgentState { normal, overloadDetected, intervening, cooldown }
