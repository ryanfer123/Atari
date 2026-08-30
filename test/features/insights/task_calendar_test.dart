import 'package:atari/core/models/todo.dart';
import 'package:atari/features/insights/task_calendar_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('groupByDeadlineDay', () {
    Todo todo(int id, String title, {DateTime? deadline}) => Todo(
      id: id,
      title: title,
      createdAt: DateTime(2026, 1, 1),
      deadline: deadline,
    );

    test('groups todos on the same calendar day together, ignoring time', () {
      final byDay = groupByDeadlineDay([
        todo(1, 'Morning task', deadline: DateTime(2026, 8, 30, 9)),
        todo(2, 'Evening task', deadline: DateTime(2026, 8, 30, 21)),
      ]);

      expect(byDay, hasLength(1));
      expect(
        byDay[DateTime(2026, 8, 30)]!.map((t) => t.title),
        ['Morning task', 'Evening task'],
      );
    });

    test('separates todos on different days', () {
      final byDay = groupByDeadlineDay([
        todo(1, 'Today', deadline: DateTime(2026, 8, 30)),
        todo(2, 'Tomorrow', deadline: DateTime(2026, 8, 31)),
      ]);

      expect(byDay, hasLength(2));
      expect(byDay[DateTime(2026, 8, 30)]!.single.title, 'Today');
      expect(byDay[DateTime(2026, 8, 31)]!.single.title, 'Tomorrow');
    });

    test('drops todos with no deadline rather than crashing', () {
      final byDay = groupByDeadlineDay([todo(1, 'No deadline')]);
      expect(byDay, isEmpty);
    });

    test('returns an empty map for an empty list', () {
      expect(groupByDeadlineDay(const []), isEmpty);
    });
  });
}
