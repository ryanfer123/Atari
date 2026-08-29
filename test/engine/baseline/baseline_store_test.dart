import 'package:atari/core/database/app_database.dart';
import 'package:atari/engine/baseline/baseline_store.dart';
import 'package:atari/engine/baseline/population_priors.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BaselineStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = BaselineStore(db);
  });

  tearDown(() async {
    await db.close();
  });

  // Tuesday 09:00 -> hourOfDay 9, dayOfWeek 2 (DateTime.weekday: Mon=1).
  final tuesdayMorning = DateTime(2026, 8, 25, 9);

  group('BaselineStore', () {
    test('observe persists and accumulates across calls', () async {
      await store.observe('unlocks', tuesdayMorning, 4);
      final second = await store.observe('unlocks', tuesdayMorning, 6);

      expect(second.count, 2);
      expect(second.mean, 5);
    });

    test(
      'observe keys buckets by signal, hour, and day of week independently',
      () async {
        final mondayMorning = DateTime(2026, 8, 24, 9); // dayOfWeek 1
        final tuesdayEvening = DateTime(2026, 8, 25, 21); // hourOfDay 21

        await store.observe('unlocks', tuesdayMorning, 4);
        await store.observe('unlocks', mondayMorning, 100);
        await store.observe('unlocks', tuesdayEvening, 100);
        await store.observe('app_switches', tuesdayMorning, 100);

        final z = await store.zScoreFor('unlocks', tuesdayMorning, 4);
        // Should reflect only the single tuesdayMorning('unlocks') observation
        // of 4, not the 100s recorded in the other buckets/signals.
        final reloaded = await store.observe('unlocks', tuesdayMorning, 4);
        expect(reloaded.count, 2);
        expect(z.isFinite, isTrue);
      },
    );

    test(
      'zScoreFor does not record the queried value as a new observation',
      () async {
        await store.observe('unlocks', tuesdayMorning, 4);
        await store.zScoreFor('unlocks', tuesdayMorning, 999);
        final afterScore = await store.observe('unlocks', tuesdayMorning, 4);

        // If zScoreFor had recorded 999, count would be 3 here instead of 2.
        expect(afterScore.count, 2);
      },
    );

    test(
      'zScoreFor on an unseen bucket falls back to the population prior',
      () async {
        final z = await store.zScoreFor(
          'unlocks',
          tuesdayMorning,
          defaultPopulationPriors['unlocks']!.mean,
        );
        expect(z, closeTo(0, 1e-9));
      },
    );

    test(
      'zScoreFor throws for a signal with no registered population prior',
      () async {
        await expectLater(
          store.zScoreFor('unknown_signal', tuesdayMorning, 1),
          throwsArgumentError,
        );
      },
    );

    test(
      'a fresh BaselineStore reads back state persisted by a previous instance',
      () async {
        await store.observe('unlocks', tuesdayMorning, 4);
        await store.observe('unlocks', tuesdayMorning, 6);

        final zFromOriginal = await store.zScoreFor(
          'unlocks',
          tuesdayMorning,
          5,
        );
        final reopened = BaselineStore(db);
        final zFromReopened = await reopened.zScoreFor(
          'unlocks',
          tuesdayMorning,
          5,
        );

        expect(zFromReopened, closeTo(zFromOriginal, 1e-9));
      },
    );
  });
}
