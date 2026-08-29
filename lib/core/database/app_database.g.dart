// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SignalBucketsTable extends SignalBuckets
    with TableInfo<$SignalBucketsTable, SignalBucketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalBucketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _signalMeta = const VerificationMeta('signal');
  @override
  late final GeneratedColumn<String> signal = GeneratedColumn<String>(
    'signal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hourOfDayMeta = const VerificationMeta(
    'hourOfDay',
  );
  @override
  late final GeneratedColumn<int> hourOfDay = GeneratedColumn<int>(
    'hour_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _meanMeta = const VerificationMeta('mean');
  @override
  late final GeneratedColumn<double> mean = GeneratedColumn<double>(
    'mean',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _m2Meta = const VerificationMeta('m2');
  @override
  late final GeneratedColumn<double> m2 = GeneratedColumn<double>(
    'm2',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    signal,
    hourOfDay,
    dayOfWeek,
    count,
    mean,
    m2,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_buckets';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalBucketRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('signal')) {
      context.handle(
        _signalMeta,
        signal.isAcceptableOrUnknown(data['signal']!, _signalMeta),
      );
    } else if (isInserting) {
      context.missing(_signalMeta);
    }
    if (data.containsKey('hour_of_day')) {
      context.handle(
        _hourOfDayMeta,
        hourOfDay.isAcceptableOrUnknown(data['hour_of_day']!, _hourOfDayMeta),
      );
    } else if (isInserting) {
      context.missing(_hourOfDayMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('mean')) {
      context.handle(
        _meanMeta,
        mean.isAcceptableOrUnknown(data['mean']!, _meanMeta),
      );
    }
    if (data.containsKey('m2')) {
      context.handle(_m2Meta, m2.isAcceptableOrUnknown(data['m2']!, _m2Meta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {signal, hourOfDay, dayOfWeek};
  @override
  SignalBucketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalBucketRow(
      signal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signal'],
      )!,
      hourOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour_of_day'],
      )!,
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      mean: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mean'],
      )!,
      m2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}m2'],
      )!,
    );
  }

  @override
  $SignalBucketsTable createAlias(String alias) {
    return $SignalBucketsTable(attachedDatabase, alias);
  }
}

class SignalBucketRow extends DataClass implements Insertable<SignalBucketRow> {
  final String signal;
  final int hourOfDay;
  final int dayOfWeek;
  final int count;
  final double mean;
  final double m2;
  const SignalBucketRow({
    required this.signal,
    required this.hourOfDay,
    required this.dayOfWeek,
    required this.count,
    required this.mean,
    required this.m2,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['signal'] = Variable<String>(signal);
    map['hour_of_day'] = Variable<int>(hourOfDay);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['count'] = Variable<int>(count);
    map['mean'] = Variable<double>(mean);
    map['m2'] = Variable<double>(m2);
    return map;
  }

  SignalBucketsCompanion toCompanion(bool nullToAbsent) {
    return SignalBucketsCompanion(
      signal: Value(signal),
      hourOfDay: Value(hourOfDay),
      dayOfWeek: Value(dayOfWeek),
      count: Value(count),
      mean: Value(mean),
      m2: Value(m2),
    );
  }

  factory SignalBucketRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalBucketRow(
      signal: serializer.fromJson<String>(json['signal']),
      hourOfDay: serializer.fromJson<int>(json['hourOfDay']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      count: serializer.fromJson<int>(json['count']),
      mean: serializer.fromJson<double>(json['mean']),
      m2: serializer.fromJson<double>(json['m2']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'signal': serializer.toJson<String>(signal),
      'hourOfDay': serializer.toJson<int>(hourOfDay),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'count': serializer.toJson<int>(count),
      'mean': serializer.toJson<double>(mean),
      'm2': serializer.toJson<double>(m2),
    };
  }

  SignalBucketRow copyWith({
    String? signal,
    int? hourOfDay,
    int? dayOfWeek,
    int? count,
    double? mean,
    double? m2,
  }) => SignalBucketRow(
    signal: signal ?? this.signal,
    hourOfDay: hourOfDay ?? this.hourOfDay,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    count: count ?? this.count,
    mean: mean ?? this.mean,
    m2: m2 ?? this.m2,
  );
  SignalBucketRow copyWithCompanion(SignalBucketsCompanion data) {
    return SignalBucketRow(
      signal: data.signal.present ? data.signal.value : this.signal,
      hourOfDay: data.hourOfDay.present ? data.hourOfDay.value : this.hourOfDay,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      count: data.count.present ? data.count.value : this.count,
      mean: data.mean.present ? data.mean.value : this.mean,
      m2: data.m2.present ? data.m2.value : this.m2,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalBucketRow(')
          ..write('signal: $signal, ')
          ..write('hourOfDay: $hourOfDay, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('count: $count, ')
          ..write('mean: $mean, ')
          ..write('m2: $m2')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(signal, hourOfDay, dayOfWeek, count, mean, m2);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalBucketRow &&
          other.signal == this.signal &&
          other.hourOfDay == this.hourOfDay &&
          other.dayOfWeek == this.dayOfWeek &&
          other.count == this.count &&
          other.mean == this.mean &&
          other.m2 == this.m2);
}

class SignalBucketsCompanion extends UpdateCompanion<SignalBucketRow> {
  final Value<String> signal;
  final Value<int> hourOfDay;
  final Value<int> dayOfWeek;
  final Value<int> count;
  final Value<double> mean;
  final Value<double> m2;
  final Value<int> rowid;
  const SignalBucketsCompanion({
    this.signal = const Value.absent(),
    this.hourOfDay = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.count = const Value.absent(),
    this.mean = const Value.absent(),
    this.m2 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignalBucketsCompanion.insert({
    required String signal,
    required int hourOfDay,
    required int dayOfWeek,
    this.count = const Value.absent(),
    this.mean = const Value.absent(),
    this.m2 = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : signal = Value(signal),
       hourOfDay = Value(hourOfDay),
       dayOfWeek = Value(dayOfWeek);
  static Insertable<SignalBucketRow> custom({
    Expression<String>? signal,
    Expression<int>? hourOfDay,
    Expression<int>? dayOfWeek,
    Expression<int>? count,
    Expression<double>? mean,
    Expression<double>? m2,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (signal != null) 'signal': signal,
      if (hourOfDay != null) 'hour_of_day': hourOfDay,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (count != null) 'count': count,
      if (mean != null) 'mean': mean,
      if (m2 != null) 'm2': m2,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignalBucketsCompanion copyWith({
    Value<String>? signal,
    Value<int>? hourOfDay,
    Value<int>? dayOfWeek,
    Value<int>? count,
    Value<double>? mean,
    Value<double>? m2,
    Value<int>? rowid,
  }) {
    return SignalBucketsCompanion(
      signal: signal ?? this.signal,
      hourOfDay: hourOfDay ?? this.hourOfDay,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      count: count ?? this.count,
      mean: mean ?? this.mean,
      m2: m2 ?? this.m2,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (signal.present) {
      map['signal'] = Variable<String>(signal.value);
    }
    if (hourOfDay.present) {
      map['hour_of_day'] = Variable<int>(hourOfDay.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (mean.present) {
      map['mean'] = Variable<double>(mean.value);
    }
    if (m2.present) {
      map['m2'] = Variable<double>(m2.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalBucketsCompanion(')
          ..write('signal: $signal, ')
          ..write('hourOfDay: $hourOfDay, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('count: $count, ')
          ..write('mean: $mean, ')
          ..write('m2: $m2, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GamificationEventsTable extends GamificationEvents
    with TableInfo<$GamificationEventsTable, GamificationEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamificationEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta(
    'trigger',
  );
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpAwardedMeta = const VerificationMeta(
    'xpAwarded',
  );
  @override
  late final GeneratedColumn<int> xpAwarded = GeneratedColumn<int>(
    'xp_awarded',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, trigger, xpAwarded, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gamification_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<GamificationEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trigger')) {
      context.handle(
        _triggerMeta,
        trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta),
      );
    } else if (isInserting) {
      context.missing(_triggerMeta);
    }
    if (data.containsKey('xp_awarded')) {
      context.handle(
        _xpAwardedMeta,
        xpAwarded.isAcceptableOrUnknown(data['xp_awarded']!, _xpAwardedMeta),
      );
    } else if (isInserting) {
      context.missing(_xpAwardedMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GamificationEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GamificationEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trigger: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger'],
      )!,
      xpAwarded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_awarded'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $GamificationEventsTable createAlias(String alias) {
    return $GamificationEventsTable(attachedDatabase, alias);
  }
}

class GamificationEventRow extends DataClass
    implements Insertable<GamificationEventRow> {
  final int id;
  final String trigger;
  final int xpAwarded;
  final DateTime timestamp;
  const GamificationEventRow({
    required this.id,
    required this.trigger,
    required this.xpAwarded,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trigger'] = Variable<String>(trigger);
    map['xp_awarded'] = Variable<int>(xpAwarded);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  GamificationEventsCompanion toCompanion(bool nullToAbsent) {
    return GamificationEventsCompanion(
      id: Value(id),
      trigger: Value(trigger),
      xpAwarded: Value(xpAwarded),
      timestamp: Value(timestamp),
    );
  }

  factory GamificationEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GamificationEventRow(
      id: serializer.fromJson<int>(json['id']),
      trigger: serializer.fromJson<String>(json['trigger']),
      xpAwarded: serializer.fromJson<int>(json['xpAwarded']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trigger': serializer.toJson<String>(trigger),
      'xpAwarded': serializer.toJson<int>(xpAwarded),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  GamificationEventRow copyWith({
    int? id,
    String? trigger,
    int? xpAwarded,
    DateTime? timestamp,
  }) => GamificationEventRow(
    id: id ?? this.id,
    trigger: trigger ?? this.trigger,
    xpAwarded: xpAwarded ?? this.xpAwarded,
    timestamp: timestamp ?? this.timestamp,
  );
  GamificationEventRow copyWithCompanion(GamificationEventsCompanion data) {
    return GamificationEventRow(
      id: data.id.present ? data.id.value : this.id,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      xpAwarded: data.xpAwarded.present ? data.xpAwarded.value : this.xpAwarded,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GamificationEventRow(')
          ..write('id: $id, ')
          ..write('trigger: $trigger, ')
          ..write('xpAwarded: $xpAwarded, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trigger, xpAwarded, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GamificationEventRow &&
          other.id == this.id &&
          other.trigger == this.trigger &&
          other.xpAwarded == this.xpAwarded &&
          other.timestamp == this.timestamp);
}

class GamificationEventsCompanion
    extends UpdateCompanion<GamificationEventRow> {
  final Value<int> id;
  final Value<String> trigger;
  final Value<int> xpAwarded;
  final Value<DateTime> timestamp;
  const GamificationEventsCompanion({
    this.id = const Value.absent(),
    this.trigger = const Value.absent(),
    this.xpAwarded = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  GamificationEventsCompanion.insert({
    this.id = const Value.absent(),
    required String trigger,
    required int xpAwarded,
    required DateTime timestamp,
  }) : trigger = Value(trigger),
       xpAwarded = Value(xpAwarded),
       timestamp = Value(timestamp);
  static Insertable<GamificationEventRow> custom({
    Expression<int>? id,
    Expression<String>? trigger,
    Expression<int>? xpAwarded,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trigger != null) 'trigger': trigger,
      if (xpAwarded != null) 'xp_awarded': xpAwarded,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  GamificationEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? trigger,
    Value<int>? xpAwarded,
    Value<DateTime>? timestamp,
  }) {
    return GamificationEventsCompanion(
      id: id ?? this.id,
      trigger: trigger ?? this.trigger,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (xpAwarded.present) {
      map['xp_awarded'] = Variable<int>(xpAwarded.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamificationEventsCompanion(')
          ..write('id: $id, ')
          ..write('trigger: $trigger, ')
          ..write('xpAwarded: $xpAwarded, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SignalBucketsTable signalBuckets = $SignalBucketsTable(this);
  late final $GamificationEventsTable gamificationEvents =
      $GamificationEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    signalBuckets,
    gamificationEvents,
  ];
}

typedef $$SignalBucketsTableCreateCompanionBuilder =
    SignalBucketsCompanion Function({
      required String signal,
      required int hourOfDay,
      required int dayOfWeek,
      Value<int> count,
      Value<double> mean,
      Value<double> m2,
      Value<int> rowid,
    });
typedef $$SignalBucketsTableUpdateCompanionBuilder =
    SignalBucketsCompanion Function({
      Value<String> signal,
      Value<int> hourOfDay,
      Value<int> dayOfWeek,
      Value<int> count,
      Value<double> mean,
      Value<double> m2,
      Value<int> rowid,
    });

class $$SignalBucketsTableFilterComposer
    extends Composer<_$AppDatabase, $SignalBucketsTable> {
  $$SignalBucketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get signal => $composableBuilder(
    column: $table.signal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hourOfDay => $composableBuilder(
    column: $table.hourOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mean => $composableBuilder(
    column: $table.mean,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get m2 => $composableBuilder(
    column: $table.m2,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalBucketsTableOrderingComposer
    extends Composer<_$AppDatabase, $SignalBucketsTable> {
  $$SignalBucketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get signal => $composableBuilder(
    column: $table.signal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hourOfDay => $composableBuilder(
    column: $table.hourOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mean => $composableBuilder(
    column: $table.mean,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get m2 => $composableBuilder(
    column: $table.m2,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalBucketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SignalBucketsTable> {
  $$SignalBucketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get signal =>
      $composableBuilder(column: $table.signal, builder: (column) => column);

  GeneratedColumn<int> get hourOfDay =>
      $composableBuilder(column: $table.hourOfDay, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<double> get mean =>
      $composableBuilder(column: $table.mean, builder: (column) => column);

  GeneratedColumn<double> get m2 =>
      $composableBuilder(column: $table.m2, builder: (column) => column);
}

class $$SignalBucketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SignalBucketsTable,
          SignalBucketRow,
          $$SignalBucketsTableFilterComposer,
          $$SignalBucketsTableOrderingComposer,
          $$SignalBucketsTableAnnotationComposer,
          $$SignalBucketsTableCreateCompanionBuilder,
          $$SignalBucketsTableUpdateCompanionBuilder,
          (
            SignalBucketRow,
            BaseReferences<_$AppDatabase, $SignalBucketsTable, SignalBucketRow>,
          ),
          SignalBucketRow,
          PrefetchHooks Function()
        > {
  $$SignalBucketsTableTableManager(_$AppDatabase db, $SignalBucketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalBucketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalBucketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalBucketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> signal = const Value.absent(),
                Value<int> hourOfDay = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<double> mean = const Value.absent(),
                Value<double> m2 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalBucketsCompanion(
                signal: signal,
                hourOfDay: hourOfDay,
                dayOfWeek: dayOfWeek,
                count: count,
                mean: mean,
                m2: m2,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String signal,
                required int hourOfDay,
                required int dayOfWeek,
                Value<int> count = const Value.absent(),
                Value<double> mean = const Value.absent(),
                Value<double> m2 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalBucketsCompanion.insert(
                signal: signal,
                hourOfDay: hourOfDay,
                dayOfWeek: dayOfWeek,
                count: count,
                mean: mean,
                m2: m2,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalBucketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SignalBucketsTable,
      SignalBucketRow,
      $$SignalBucketsTableFilterComposer,
      $$SignalBucketsTableOrderingComposer,
      $$SignalBucketsTableAnnotationComposer,
      $$SignalBucketsTableCreateCompanionBuilder,
      $$SignalBucketsTableUpdateCompanionBuilder,
      (
        SignalBucketRow,
        BaseReferences<_$AppDatabase, $SignalBucketsTable, SignalBucketRow>,
      ),
      SignalBucketRow,
      PrefetchHooks Function()
    >;
typedef $$GamificationEventsTableCreateCompanionBuilder =
    GamificationEventsCompanion Function({
      Value<int> id,
      required String trigger,
      required int xpAwarded,
      required DateTime timestamp,
    });
typedef $$GamificationEventsTableUpdateCompanionBuilder =
    GamificationEventsCompanion Function({
      Value<int> id,
      Value<String> trigger,
      Value<int> xpAwarded,
      Value<DateTime> timestamp,
    });

class $$GamificationEventsTableFilterComposer
    extends Composer<_$AppDatabase, $GamificationEventsTable> {
  $$GamificationEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpAwarded => $composableBuilder(
    column: $table.xpAwarded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GamificationEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $GamificationEventsTable> {
  $$GamificationEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpAwarded => $composableBuilder(
    column: $table.xpAwarded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamificationEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamificationEventsTable> {
  $$GamificationEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<int> get xpAwarded =>
      $composableBuilder(column: $table.xpAwarded, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$GamificationEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamificationEventsTable,
          GamificationEventRow,
          $$GamificationEventsTableFilterComposer,
          $$GamificationEventsTableOrderingComposer,
          $$GamificationEventsTableAnnotationComposer,
          $$GamificationEventsTableCreateCompanionBuilder,
          $$GamificationEventsTableUpdateCompanionBuilder,
          (
            GamificationEventRow,
            BaseReferences<
              _$AppDatabase,
              $GamificationEventsTable,
              GamificationEventRow
            >,
          ),
          GamificationEventRow,
          PrefetchHooks Function()
        > {
  $$GamificationEventsTableTableManager(
    _$AppDatabase db,
    $GamificationEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamificationEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamificationEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamificationEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trigger = const Value.absent(),
                Value<int> xpAwarded = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => GamificationEventsCompanion(
                id: id,
                trigger: trigger,
                xpAwarded: xpAwarded,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trigger,
                required int xpAwarded,
                required DateTime timestamp,
              }) => GamificationEventsCompanion.insert(
                id: id,
                trigger: trigger,
                xpAwarded: xpAwarded,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GamificationEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamificationEventsTable,
      GamificationEventRow,
      $$GamificationEventsTableFilterComposer,
      $$GamificationEventsTableOrderingComposer,
      $$GamificationEventsTableAnnotationComposer,
      $$GamificationEventsTableCreateCompanionBuilder,
      $$GamificationEventsTableUpdateCompanionBuilder,
      (
        GamificationEventRow,
        BaseReferences<
          _$AppDatabase,
          $GamificationEventsTable,
          GamificationEventRow
        >,
      ),
      GamificationEventRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SignalBucketsTableTableManager get signalBuckets =>
      $$SignalBucketsTableTableManager(_db, _db.signalBuckets);
  $$GamificationEventsTableTableManager get gamificationEvents =>
      $$GamificationEventsTableTableManager(_db, _db.gamificationEvents);
}
