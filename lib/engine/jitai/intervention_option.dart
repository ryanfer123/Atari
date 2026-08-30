import '../../core/models/task_tool.dart';

/// The only things this app can ever DO.
///
/// A closed enum the decision rule selects from — never an invented
/// action. Every branch except [defer] goes through a
/// confirm-before-write gate; XP is the one documented exception, since
/// it has no real-world consequence (Plans/ARCHITECTURE.md §2,
/// Plans/PIVOT_PLAN.md §2.4).
enum InterventionOption {
  setReminder,
  setAlarm,
  startTimer,
  addTodo,
  showOverlay,
  defer,
}

/// True when acting on this option changes something in the physical
/// world (an alarm firing, a notification arriving) and therefore
/// requires an explicit user tap first.
bool requiresConfirmation(InterventionOption option) => switch (option) {
  InterventionOption.setReminder => true,
  InterventionOption.setAlarm => true,
  InterventionOption.startTimer => true,
  InterventionOption.addTodo => true,
  InterventionOption.showOverlay => true,
  // Doing nothing needs no permission.
  InterventionOption.defer => false,
};

String interventionOptionLabel(InterventionOption option) => switch (option) {
  InterventionOption.setReminder => 'Set a reminder',
  InterventionOption.setAlarm => 'Set an alarm',
  InterventionOption.startTimer => 'Start a timer',
  InterventionOption.addTodo => 'Add a todo',
  InterventionOption.showOverlay => 'Show focus overlay',
  InterventionOption.defer => 'Do nothing',
};

/// Maps the task-level [TaskTool] a model may propose onto the
/// system-level intervention enum. [TaskTool.none] means "propose
/// nothing", which is [InterventionOption.defer].
InterventionOption interventionForTaskTool(TaskTool tool) => switch (tool) {
  TaskTool.setReminder => InterventionOption.setReminder,
  TaskTool.setAlarm => InterventionOption.setAlarm,
  TaskTool.startTimer => InterventionOption.startTimer,
  TaskTool.addTodo => InterventionOption.addTodo,
  TaskTool.none => InterventionOption.defer,
};

/// The bandit arm name an option is recorded under.
///
/// Arms are the thing `InterventionBandit` learns weights over, so this
/// mapping is what connects the JITAI intervention enum to outcome
/// measurement (Plans/ARCHITECTURE.md §2's outcome-logging layer).
String banditArmFor(InterventionOption option) => option.name;
