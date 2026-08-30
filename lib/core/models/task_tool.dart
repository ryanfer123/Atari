/// The only actions a model may ever propose for a task.
///
/// A closed enum, not an open tool name the model generates freely — the
/// same masking pattern as `GoalContextSource` (Plans/IMPLEMENTATION.md
/// §4.8), extended here per Plans/PIVOT_PLAN.md §2.3.
///
/// Every one of these except [none] has a real-world consequence (an
/// alarm firing at 3am, a missed reminder), so per §2.4 the user must
/// confirm before any of them is actually scheduled — the model only
/// ever *proposes*.
enum TaskTool { setReminder, setAlarm, startTimer, addTodo, none }

String taskToolLabel(TaskTool tool) => switch (tool) {
  TaskTool.setReminder => 'Set reminder',
  TaskTool.setAlarm => 'Set alarm',
  TaskTool.startTimer => 'Start timer',
  TaskTool.addTodo => 'Add to todos',
  TaskTool.none => 'No action',
};
