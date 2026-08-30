import 'package:flutter/material.dart';

import '../models/difficulty_tier.dart';
import '../theme/app_theme.dart';

/// Shown when a list has nothing in it yet. Always says what the user
/// can do next rather than only stating emptiness.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            Gap.m,
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            Gap.s,
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[Gap.l, action!],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Displays a task's assigned difficulty.
///
/// Colour encodes effort, not danger — see `AppTheme`'s note on why
/// alarming colours are avoided as motivators.
class DifficultyChip extends StatelessWidget {
  const DifficultyChip({super.key, required this.tier, this.showXp = false});

  final DifficultyTier tier;
  final bool showXp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = showXp
        ? '${difficultyLabel(tier)} · ${xpForDifficulty(tier)} XP'
        : difficultyLabel(tier);

    final background = switch (tier) {
      DifficultyTier.trivial => scheme.surfaceContainerHighest,
      DifficultyTier.light => scheme.secondaryContainer,
      DifficultyTier.moderate => scheme.tertiaryContainer,
      DifficultyTier.heavy => scheme.primaryContainer,
    };
    final foreground = switch (tier) {
      DifficultyTier.trivial => scheme.onSurfaceVariant,
      DifficultyTier.light => scheme.onSecondaryContainer,
      DifficultyTier.moderate => scheme.onTertiaryContainer,
      DifficultyTier.heavy => scheme.onPrimaryContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}

/// Formats a date/time for display, using relative wording for the
/// common near-term cases since that's what a deadline usually is.
String formatWhen(DateTime when, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final day = DateTime(when.year, when.month, when.day);
  final today = DateTime(reference.year, reference.month, reference.day);
  final dayDelta = day.difference(today).inDays;

  final clock = formatClock(TimeOfDay.fromDateTime(when));

  return switch (dayDelta) {
    0 => 'Today $clock',
    1 => 'Tomorrow $clock',
    -1 => 'Yesterday $clock',
    _ when dayDelta > 1 && dayDelta < 7 =>
      '${weekdayAbbrev(when.weekday)} $clock',
    _ => '${when.day}/${when.month} $clock',
  };
}

/// `3:45pm`-style 12-hour clock, with no leading zero on the hour —
/// the piece of [formatWhen] callers need on its own for anything that
/// only picks a time of day, like a health target's daily check-in.
String formatClock(TimeOfDay time) {
  final hh = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final mm = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'am' : 'pm';
  return '$hh:$mm$period';
}

/// "18:30"-style 24-hour storage format for a [TimeOfDay] — what
/// `HealthTarget.reminderTime` is stored as.
String formatHHmm(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// Inverse of [formatHHmm]. Returns null for anything that isn't
/// exactly "HH:mm" rather than throwing — a malformed stored value
/// should read as "no schedule", not crash the screen showing it.
TimeOfDay? parseHHmm(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

/// [weekday] is `DateTime.weekday` numbering: 1 = Monday .. 7 = Sunday.
String weekdayAbbrev(int weekday) => const [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
][(weekday - 1).clamp(0, 6)];
