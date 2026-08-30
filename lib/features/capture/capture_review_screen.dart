import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/captured_item.dart';
import '../../core/models/health_target.dart';
import '../../core/models/task_tool.dart';
import '../../core/models/todo.dart';
import '../../core/services/model_services.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/model_backend_badge.dart';
import '../../engine/capture/captured_item_parser.dart';
import '../../engine/scheduling/schedule_calculator.dart';
import '../goals/reminder_sheet.dart';
import '../goals/schedule_pickers.dart';

/// The confirm-before-write gate for the capture loop.
///
/// OCR and the type/deadline heuristic will both be wrong sometimes, so
/// this screen is a real editing step, never a formality — nothing is
/// persisted until the user taps save (Plans/IMPLEMENTATION.md §4.6,
/// Plans/PIVOT_PLAN.md §2.4).
class CaptureReviewScreen extends StatefulWidget {
  const CaptureReviewScreen({
    super.key,
    required this.imagePath,
    required this.ocrService,
  });

  /// The already-cropped region the user circled.
  final String? imagePath;
  final OcrService ocrService;

  @override
  State<CaptureReviewScreen> createState() => _CaptureReviewScreenState();
}

class _CaptureReviewScreenState extends State<CaptureReviewScreen> {
  final _textController = TextEditingController();
  ItemType _type = ItemType.note;
  DateTime? _deadline;

  // Health target scheduling.
  TimeOfDay? _healthTime;
  bool _healthEveryDay = true;
  Set<int> _healthDays = {1, 2, 3, 4, 5, 6, 7};

  ModelBackend? _backend;
  double? _confidence;
  bool _loading = true;

  /// Saving is no longer instant now that the models are real: writing a
  /// todo embeds the text and scores its difficulty, and under the
  /// one-model-at-a-time rule (Plans/PIVOT_PLAN.md §2.2) that can mean
  /// swapping a 2.5GB model in. Without this the button just looks dead.
  bool _saving = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _runOcr();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _runOcr() async {
    try {
      final result = await widget.ocrService.extractText(
        widget.imagePath ?? '',
      );
      // The parser is deliberately heuristic, not a second model — see
      // Plans/IMPLEMENTATION.md §4.6.
      final parsed = CapturedItemParser().parse(result.text);
      if (!mounted) return;
      setState(() {
        _textController.text = result.text;
        _type = parsed.suggestedType;
        _deadline = parsed.suggestedDeadline;
        _backend = result.backend;
        _confidence = result.confidence;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (!mounted) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _save() async {
    final services = ServiceScope.of(context);
    final text = _textController.text.trim();
    if (text.isEmpty || _saving) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await _write(services, text, navigator, messenger);
    } finally {
      // Only matters when something threw — on the success paths this
      // screen has already been popped.
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _write(
    AppServices services,
    String text,
    NavigatorState navigator,
    ScaffoldMessengerState messenger,
  ) async {
    // Every confirmed capture is stored and embedded, whatever the user
    // chose to file it as. That's what makes
    // GoalContextSource.captureHistory a real source — something
    // circled last week can ground an explanation today. Failing to
    // store the capture must not lose the item the user is saving, so
    // it's deliberately not fatal.
    final imagePath = widget.imagePath;
    if (imagePath != null) {
      try {
        await services.captures.create(imagePath: imagePath, text: text);
      } catch (e) {
        debugPrint('Could not store the capture: $e');
      }
    }

    switch (_type) {
      case ItemType.note:
        await services.notes.create(text: text);
        messenger.showSnackBar(
          const SnackBar(content: Text('Saved as a note')),
        );
        navigator.pop();

      case ItemType.healthTarget:
        // Health targets are metric + threshold; the first line is the
        // metric and anything after it the threshold, which the user has
        // just had the chance to edit into that shape.
        final lines = text
            .split(RegExp(r'\r\n|\r|\n'))
            .where((l) => l.trim().isNotEmpty)
            .toList();
        final metric = lines.first.trim();
        final scheduled = _healthTime != null;
        final weekdays = _healthEveryDay
            ? const {1, 2, 3, 4, 5, 6, 7}
            : _healthDays;
        final targetId = await services.healthTargets.create(
          metric: metric,
          threshold: lines.length > 1 ? lines[1].trim() : '—',
          reminderTime: scheduled ? formatHHmm(_healthTime!) : null,
          activeDaysMask: scheduled
              ? (_healthEveryDay
                    ? everyDayMask
                    : HealthTarget.maskFromWeekdays(weekdays))
              : null,
        );
        if (scheduled) {
          await services.scheduleReminder(
            title: metric,
            scheduledFor: nextOccurrence(
              hour: _healthTime!.hour,
              minute: _healthTime!.minute,
              weekdays: weekdays,
            ),
            tool: TaskTool.setReminder,
            healthTargetId: targetId,
          );
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('Saved as a health target')),
        );
        navigator.pop();

      case ItemType.todo:
        final title = text.split(RegExp(r'\r\n|\r|\n')).first.trim();
        // Difficulty is scored automatically: a wrong tier costs only a
        // slightly-off XP number, which §2.4 puts on the safe-to-automate
        // side of the line.
        final nearby = _deadline == null
            ? const <Todo>[]
            : await services.todos.withDeadlineNear(_deadline!);
        final tier = await services.difficultyScorer.score(
          title: title,
          notes: text,
          deadline: _deadline,
          nearbyTasks: nearby,
        );
        final id = await services.todos.create(
          title: title,
          deadline: _deadline,
          difficulty: tier,
          notes: text,
        );

        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Saved as a todo')),
        );

        // Decision point A: capture completed. Offering a reminder is a
        // proposal — the sheet is the confirm gate, and declining it
        // still leaves the todo saved.
        final todo = await services.todos.findById(id);
        if (todo != null && mounted) {
          await showReminderSheet(context, todo: todo);
        }
        navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review before saving')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Could not read the image: $_error',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                  Gap.m,
                ],
                if (widget.imagePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.imagePath!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      // A crop that can't be decoded shouldn't take the
                      // whole review screen down with it — the text is
                      // still editable and savable without the preview.
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Gap.m,
                ],
                Row(
                  children: [
                    Text(
                      'Extracted text',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (_backend != null)
                      ModelBackendBadge(backend: _backend!, compact: true),
                  ],
                ),
                Gap.s,
                TextField(
                  controller: _textController,
                  maxLines: null,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'What was captured',
                  ),
                ),
                if (_confidence != null) ...[
                  Gap.xs,
                  Text(
                    'Reading confidence ${(_confidence! * 100).round()}% — check it before saving.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                Gap.l,
                Text('Save as', style: Theme.of(context).textTheme.titleSmall),
                Gap.s,
                SegmentedButton<ItemType>(
                  segments: const [
                    ButtonSegment(
                      value: ItemType.note,
                      label: Text('Note'),
                      icon: Icon(Icons.sticky_note_2_outlined),
                    ),
                    ButtonSegment(
                      value: ItemType.todo,
                      label: Text('Todo'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment(
                      value: ItemType.healthTarget,
                      label: Text('Health'),
                      icon: Icon(Icons.favorite_outline),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                if (_type == ItemType.todo) ...[
                  Gap.l,
                  Text(
                    'Deadline',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Gap.s,
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(
                        _deadline == null
                            ? 'No deadline'
                            : formatWhen(_deadline!),
                      ),
                      trailing: _deadline == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _deadline = null),
                            ),
                      onTap: _pickDeadline,
                    ),
                  ),
                ],
                if (_type == ItemType.healthTarget) ...[
                  Gap.l,
                  Text(
                    'Check-in schedule',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Gap.s,
                  HealthScheduleField(
                    time: _healthTime,
                    everyDay: _healthEveryDay,
                    days: _healthDays,
                    onTimeChanged: (time) => setState(() => _healthTime = time),
                    onEveryDayChanged: (everyDay) => setState(() {
                      _healthEveryDay = everyDay;
                      if (everyDay) _healthDays = {1, 2, 3, 4, 5, 6, 7};
                    }),
                    onDaysChanged: (days) => setState(() => _healthDays = days),
                  ),
                ],
                Gap.xl,
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save'),
                ),
                Gap.s,
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Discard'),
                ),
              ],
            ),
    );
  }
}
