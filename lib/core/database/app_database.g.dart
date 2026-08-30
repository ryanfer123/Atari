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

class $TodosTable extends Todos with TableInfo<$TodosTable, TodoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    createdAt,
    deadline,
    difficulty,
    completedAt,
    notes,
    parentId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  VerificationContext validateIntegrity(
    Insertable<TodoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
    );
  }

  @override
  $TodosTable createAlias(String alias) {
    return $TodosTable(attachedDatabase, alias);
  }
}

class TodoRow extends DataClass implements Insertable<TodoRow> {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime? deadline;

  /// `DifficultyTier.name`, or null until scored. Stored as its name
  /// rather than its index so reordering the enum can't silently
  /// remap existing rows.
  final String? difficulty;
  final DateTime? completedAt;
  final String? notes;

  /// Set when this row is a subtask produced by decomposing another
  /// todo. Self-referencing, so a deleted parent's subtasks are cleaned
  /// up by the repository rather than by a DB cascade (Drift would need
  /// the reference declared up front, and this keeps deletion policy in
  /// one readable place).
  final int? parentId;
  const TodoRow({
    required this.id,
    required this.title,
    required this.createdAt,
    this.deadline,
    this.difficulty,
    this.completedAt,
    this.notes,
    this.parentId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<String>(difficulty);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    return map;
  }

  TodosCompanion toCompanion(bool nullToAbsent) {
    return TodosCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
    );
  }

  factory TodoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      difficulty: serializer.fromJson<String?>(json['difficulty']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      parentId: serializer.fromJson<int?>(json['parentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'difficulty': serializer.toJson<String?>(difficulty),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'notes': serializer.toJson<String?>(notes),
      'parentId': serializer.toJson<int?>(parentId),
    };
  }

  TodoRow copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    Value<DateTime?> deadline = const Value.absent(),
    Value<String?> difficulty = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> parentId = const Value.absent(),
  }) => TodoRow(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    deadline: deadline.present ? deadline.value : this.deadline,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    notes: notes.present ? notes.value : this.notes,
    parentId: parentId.present ? parentId.value : this.parentId,
  );
  TodoRow copyWithCompanion(TodosCompanion data) {
    return TodoRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('deadline: $deadline, ')
          ..write('difficulty: $difficulty, ')
          ..write('completedAt: $completedAt, ')
          ..write('notes: $notes, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    createdAt,
    deadline,
    difficulty,
    completedAt,
    notes,
    parentId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.deadline == this.deadline &&
          other.difficulty == this.difficulty &&
          other.completedAt == this.completedAt &&
          other.notes == this.notes &&
          other.parentId == this.parentId);
}

class TodosCompanion extends UpdateCompanion<TodoRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deadline;
  final Value<String?> difficulty;
  final Value<DateTime?> completedAt;
  final Value<String?> notes;
  final Value<int?> parentId;
  const TodosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deadline = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.parentId = const Value.absent(),
  });
  TodosCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required DateTime createdAt,
    this.deadline = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.parentId = const Value.absent(),
  }) : title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<TodoRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deadline,
    Expression<String>? difficulty,
    Expression<DateTime>? completedAt,
    Expression<String>? notes,
    Expression<int>? parentId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (deadline != null) 'deadline': deadline,
      if (difficulty != null) 'difficulty': difficulty,
      if (completedAt != null) 'completed_at': completedAt,
      if (notes != null) 'notes': notes,
      if (parentId != null) 'parent_id': parentId,
    });
  }

  TodosCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deadline,
    Value<String?>? difficulty,
    Value<DateTime?>? completedAt,
    Value<String?>? notes,
    Value<int?>? parentId,
  }) {
    return TodosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      difficulty: difficulty ?? this.difficulty,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      parentId: parentId ?? this.parentId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('deadline: $deadline, ')
          ..write('difficulty: $difficulty, ')
          ..write('completedAt: $completedAt, ')
          ..write('notes: $notes, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceCaptureIdMeta = const VerificationMeta(
    'sourceCaptureId',
  );
  @override
  late final GeneratedColumn<int> sourceCaptureId = GeneratedColumn<int>(
    'source_capture_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<Uint8List> embedding = GeneratedColumn<Uint8List>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingModelMeta = const VerificationMeta(
    'embeddingModel',
  );
  @override
  late final GeneratedColumn<String> embeddingModel = GeneratedColumn<String>(
    'embedding_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingDimensionsMeta =
      const VerificationMeta('embeddingDimensions');
  @override
  late final GeneratedColumn<int> embeddingDimensions = GeneratedColumn<int>(
    'embedding_dimensions',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    body,
    createdAt,
    sourceCaptureId,
    embedding,
    embeddingModel,
    embeddingDimensions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('source_capture_id')) {
      context.handle(
        _sourceCaptureIdMeta,
        sourceCaptureId.isAcceptableOrUnknown(
          data['source_capture_id']!,
          _sourceCaptureIdMeta,
        ),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    if (data.containsKey('embedding_model')) {
      context.handle(
        _embeddingModelMeta,
        embeddingModel.isAcceptableOrUnknown(
          data['embedding_model']!,
          _embeddingModelMeta,
        ),
      );
    }
    if (data.containsKey('embedding_dimensions')) {
      context.handle(
        _embeddingDimensionsMeta,
        embeddingDimensions.isAcceptableOrUnknown(
          data['embedding_dimensions']!,
          _embeddingDimensionsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sourceCaptureId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_capture_id'],
      ),
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}embedding'],
      ),
      embeddingModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding_model'],
      ),
      embeddingDimensions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}embedding_dimensions'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final int id;

  /// The note's content. Named `body`, not `text`, because `text` is
  /// Drift's own column-builder method on [Table] and would collide.
  /// The domain model (`Note.text`) keeps the natural name.
  final String body;
  final DateTime createdAt;

  /// Set when this note came from the capture flow rather than typing.
  final int? sourceCaptureId;

  /// Embedding of [body], stored as little-endian float64s. Nullable so
  /// a note is still savable when no embedder is available.
  final Uint8List? embedding;
  final String? embeddingModel;
  final int? embeddingDimensions;
  const NoteRow({
    required this.id,
    required this.body,
    required this.createdAt,
    this.sourceCaptureId,
    this.embedding,
    this.embeddingModel,
    this.embeddingDimensions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || sourceCaptureId != null) {
      map['source_capture_id'] = Variable<int>(sourceCaptureId);
    }
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<Uint8List>(embedding);
    }
    if (!nullToAbsent || embeddingModel != null) {
      map['embedding_model'] = Variable<String>(embeddingModel);
    }
    if (!nullToAbsent || embeddingDimensions != null) {
      map['embedding_dimensions'] = Variable<int>(embeddingDimensions);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      body: Value(body),
      createdAt: Value(createdAt),
      sourceCaptureId: sourceCaptureId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceCaptureId),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
      embeddingModel: embeddingModel == null && nullToAbsent
          ? const Value.absent()
          : Value(embeddingModel),
      embeddingDimensions: embeddingDimensions == null && nullToAbsent
          ? const Value.absent()
          : Value(embeddingDimensions),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<int>(json['id']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sourceCaptureId: serializer.fromJson<int?>(json['sourceCaptureId']),
      embedding: serializer.fromJson<Uint8List?>(json['embedding']),
      embeddingModel: serializer.fromJson<String?>(json['embeddingModel']),
      embeddingDimensions: serializer.fromJson<int?>(
        json['embeddingDimensions'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sourceCaptureId': serializer.toJson<int?>(sourceCaptureId),
      'embedding': serializer.toJson<Uint8List?>(embedding),
      'embeddingModel': serializer.toJson<String?>(embeddingModel),
      'embeddingDimensions': serializer.toJson<int?>(embeddingDimensions),
    };
  }

  NoteRow copyWith({
    int? id,
    String? body,
    DateTime? createdAt,
    Value<int?> sourceCaptureId = const Value.absent(),
    Value<Uint8List?> embedding = const Value.absent(),
    Value<String?> embeddingModel = const Value.absent(),
    Value<int?> embeddingDimensions = const Value.absent(),
  }) => NoteRow(
    id: id ?? this.id,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    sourceCaptureId: sourceCaptureId.present
        ? sourceCaptureId.value
        : this.sourceCaptureId,
    embedding: embedding.present ? embedding.value : this.embedding,
    embeddingModel: embeddingModel.present
        ? embeddingModel.value
        : this.embeddingModel,
    embeddingDimensions: embeddingDimensions.present
        ? embeddingDimensions.value
        : this.embeddingDimensions,
  );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sourceCaptureId: data.sourceCaptureId.present
          ? data.sourceCaptureId.value
          : this.sourceCaptureId,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      embeddingModel: data.embeddingModel.present
          ? data.embeddingModel.value
          : this.embeddingModel,
      embeddingDimensions: data.embeddingDimensions.present
          ? data.embeddingDimensions.value
          : this.embeddingDimensions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('sourceCaptureId: $sourceCaptureId, ')
          ..write('embedding: $embedding, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('embeddingDimensions: $embeddingDimensions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    body,
    createdAt,
    sourceCaptureId,
    $driftBlobEquality.hash(embedding),
    embeddingModel,
    embeddingDimensions,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.sourceCaptureId == this.sourceCaptureId &&
          $driftBlobEquality.equals(other.embedding, this.embedding) &&
          other.embeddingModel == this.embeddingModel &&
          other.embeddingDimensions == this.embeddingDimensions);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<int> id;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<int?> sourceCaptureId;
  final Value<Uint8List?> embedding;
  final Value<String?> embeddingModel;
  final Value<int?> embeddingDimensions;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sourceCaptureId = const Value.absent(),
    this.embedding = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.embeddingDimensions = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String body,
    required DateTime createdAt,
    this.sourceCaptureId = const Value.absent(),
    this.embedding = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.embeddingDimensions = const Value.absent(),
  }) : body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<NoteRow> custom({
    Expression<int>? id,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<int>? sourceCaptureId,
    Expression<Uint8List>? embedding,
    Expression<String>? embeddingModel,
    Expression<int>? embeddingDimensions,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (sourceCaptureId != null) 'source_capture_id': sourceCaptureId,
      if (embedding != null) 'embedding': embedding,
      if (embeddingModel != null) 'embedding_model': embeddingModel,
      if (embeddingDimensions != null)
        'embedding_dimensions': embeddingDimensions,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<int?>? sourceCaptureId,
    Value<Uint8List?>? embedding,
    Value<String?>? embeddingModel,
    Value<int?>? embeddingDimensions,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      sourceCaptureId: sourceCaptureId ?? this.sourceCaptureId,
      embedding: embedding ?? this.embedding,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      embeddingDimensions: embeddingDimensions ?? this.embeddingDimensions,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sourceCaptureId.present) {
      map['source_capture_id'] = Variable<int>(sourceCaptureId.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<Uint8List>(embedding.value);
    }
    if (embeddingModel.present) {
      map['embedding_model'] = Variable<String>(embeddingModel.value);
    }
    if (embeddingDimensions.present) {
      map['embedding_dimensions'] = Variable<int>(embeddingDimensions.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('sourceCaptureId: $sourceCaptureId, ')
          ..write('embedding: $embedding, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('embeddingDimensions: $embeddingDimensions')
          ..write(')'))
        .toString();
  }
}

class $HealthTargetsTable extends HealthTargets
    with TableInfo<$HealthTargetsTable, HealthTargetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthTargetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _metricMeta = const VerificationMeta('metric');
  @override
  late final GeneratedColumn<String> metric = GeneratedColumn<String>(
    'metric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thresholdMeta = const VerificationMeta(
    'threshold',
  );
  @override
  late final GeneratedColumn<String> threshold = GeneratedColumn<String>(
    'threshold',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastMetAtMeta = const VerificationMeta(
    'lastMetAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastMetAt = GeneratedColumn<DateTime>(
    'last_met_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeDaysMaskMeta = const VerificationMeta(
    'activeDaysMask',
  );
  @override
  late final GeneratedColumn<int> activeDaysMask = GeneratedColumn<int>(
    'active_days_mask',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    metric,
    threshold,
    createdAt,
    active,
    lastMetAt,
    reminderTime,
    activeDaysMask,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthTargetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('metric')) {
      context.handle(
        _metricMeta,
        metric.isAcceptableOrUnknown(data['metric']!, _metricMeta),
      );
    } else if (isInserting) {
      context.missing(_metricMeta);
    }
    if (data.containsKey('threshold')) {
      context.handle(
        _thresholdMeta,
        threshold.isAcceptableOrUnknown(data['threshold']!, _thresholdMeta),
      );
    } else if (isInserting) {
      context.missing(_thresholdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('last_met_at')) {
      context.handle(
        _lastMetAtMeta,
        lastMetAt.isAcceptableOrUnknown(data['last_met_at']!, _lastMetAtMeta),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('active_days_mask')) {
      context.handle(
        _activeDaysMaskMeta,
        activeDaysMask.isAcceptableOrUnknown(
          data['active_days_mask']!,
          _activeDaysMaskMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthTargetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthTargetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      metric: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric'],
      )!,
      threshold: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}threshold'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      lastMetAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_met_at'],
      ),
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      ),
      activeDaysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_days_mask'],
      ),
    );
  }

  @override
  $HealthTargetsTable createAlias(String alias) {
    return $HealthTargetsTable(attachedDatabase, alias);
  }
}

class HealthTargetRow extends DataClass implements Insertable<HealthTargetRow> {
  final int id;
  final String metric;
  final String threshold;
  final DateTime createdAt;
  final bool active;
  final DateTime? lastMetAt;

  /// Time of day to check this target, as "HH:mm" in 24-hour time.
  /// Null means no recurring reminder is configured — the target is
  /// still a normal field record either way.
  final String? reminderTime;

  /// Which days [reminderTime] applies to, as a 7-bit mask — bit 0 is
  /// Monday, bit 6 is Sunday, matching `DateTime.weekday - 1`. "Every
  /// day" is all seven bits set (127), not a separate null case, so a
  /// schedule is always one concrete thing rather than two shapes to
  /// handle everywhere it's read. Null alongside a null [reminderTime]
  /// means no schedule at all.
  final int? activeDaysMask;
  const HealthTargetRow({
    required this.id,
    required this.metric,
    required this.threshold,
    required this.createdAt,
    required this.active,
    this.lastMetAt,
    this.reminderTime,
    this.activeDaysMask,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['metric'] = Variable<String>(metric);
    map['threshold'] = Variable<String>(threshold);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || lastMetAt != null) {
      map['last_met_at'] = Variable<DateTime>(lastMetAt);
    }
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    if (!nullToAbsent || activeDaysMask != null) {
      map['active_days_mask'] = Variable<int>(activeDaysMask);
    }
    return map;
  }

  HealthTargetsCompanion toCompanion(bool nullToAbsent) {
    return HealthTargetsCompanion(
      id: Value(id),
      metric: Value(metric),
      threshold: Value(threshold),
      createdAt: Value(createdAt),
      active: Value(active),
      lastMetAt: lastMetAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMetAt),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      activeDaysMask: activeDaysMask == null && nullToAbsent
          ? const Value.absent()
          : Value(activeDaysMask),
    );
  }

  factory HealthTargetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthTargetRow(
      id: serializer.fromJson<int>(json['id']),
      metric: serializer.fromJson<String>(json['metric']),
      threshold: serializer.fromJson<String>(json['threshold']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      active: serializer.fromJson<bool>(json['active']),
      lastMetAt: serializer.fromJson<DateTime?>(json['lastMetAt']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      activeDaysMask: serializer.fromJson<int?>(json['activeDaysMask']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'metric': serializer.toJson<String>(metric),
      'threshold': serializer.toJson<String>(threshold),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'active': serializer.toJson<bool>(active),
      'lastMetAt': serializer.toJson<DateTime?>(lastMetAt),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'activeDaysMask': serializer.toJson<int?>(activeDaysMask),
    };
  }

  HealthTargetRow copyWith({
    int? id,
    String? metric,
    String? threshold,
    DateTime? createdAt,
    bool? active,
    Value<DateTime?> lastMetAt = const Value.absent(),
    Value<String?> reminderTime = const Value.absent(),
    Value<int?> activeDaysMask = const Value.absent(),
  }) => HealthTargetRow(
    id: id ?? this.id,
    metric: metric ?? this.metric,
    threshold: threshold ?? this.threshold,
    createdAt: createdAt ?? this.createdAt,
    active: active ?? this.active,
    lastMetAt: lastMetAt.present ? lastMetAt.value : this.lastMetAt,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    activeDaysMask: activeDaysMask.present
        ? activeDaysMask.value
        : this.activeDaysMask,
  );
  HealthTargetRow copyWithCompanion(HealthTargetsCompanion data) {
    return HealthTargetRow(
      id: data.id.present ? data.id.value : this.id,
      metric: data.metric.present ? data.metric.value : this.metric,
      threshold: data.threshold.present ? data.threshold.value : this.threshold,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      active: data.active.present ? data.active.value : this.active,
      lastMetAt: data.lastMetAt.present ? data.lastMetAt.value : this.lastMetAt,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      activeDaysMask: data.activeDaysMask.present
          ? data.activeDaysMask.value
          : this.activeDaysMask,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthTargetRow(')
          ..write('id: $id, ')
          ..write('metric: $metric, ')
          ..write('threshold: $threshold, ')
          ..write('createdAt: $createdAt, ')
          ..write('active: $active, ')
          ..write('lastMetAt: $lastMetAt, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('activeDaysMask: $activeDaysMask')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    metric,
    threshold,
    createdAt,
    active,
    lastMetAt,
    reminderTime,
    activeDaysMask,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthTargetRow &&
          other.id == this.id &&
          other.metric == this.metric &&
          other.threshold == this.threshold &&
          other.createdAt == this.createdAt &&
          other.active == this.active &&
          other.lastMetAt == this.lastMetAt &&
          other.reminderTime == this.reminderTime &&
          other.activeDaysMask == this.activeDaysMask);
}

class HealthTargetsCompanion extends UpdateCompanion<HealthTargetRow> {
  final Value<int> id;
  final Value<String> metric;
  final Value<String> threshold;
  final Value<DateTime> createdAt;
  final Value<bool> active;
  final Value<DateTime?> lastMetAt;
  final Value<String?> reminderTime;
  final Value<int?> activeDaysMask;
  const HealthTargetsCompanion({
    this.id = const Value.absent(),
    this.metric = const Value.absent(),
    this.threshold = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.active = const Value.absent(),
    this.lastMetAt = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.activeDaysMask = const Value.absent(),
  });
  HealthTargetsCompanion.insert({
    this.id = const Value.absent(),
    required String metric,
    required String threshold,
    required DateTime createdAt,
    this.active = const Value.absent(),
    this.lastMetAt = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.activeDaysMask = const Value.absent(),
  }) : metric = Value(metric),
       threshold = Value(threshold),
       createdAt = Value(createdAt);
  static Insertable<HealthTargetRow> custom({
    Expression<int>? id,
    Expression<String>? metric,
    Expression<String>? threshold,
    Expression<DateTime>? createdAt,
    Expression<bool>? active,
    Expression<DateTime>? lastMetAt,
    Expression<String>? reminderTime,
    Expression<int>? activeDaysMask,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (metric != null) 'metric': metric,
      if (threshold != null) 'threshold': threshold,
      if (createdAt != null) 'created_at': createdAt,
      if (active != null) 'active': active,
      if (lastMetAt != null) 'last_met_at': lastMetAt,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (activeDaysMask != null) 'active_days_mask': activeDaysMask,
    });
  }

  HealthTargetsCompanion copyWith({
    Value<int>? id,
    Value<String>? metric,
    Value<String>? threshold,
    Value<DateTime>? createdAt,
    Value<bool>? active,
    Value<DateTime?>? lastMetAt,
    Value<String?>? reminderTime,
    Value<int?>? activeDaysMask,
  }) {
    return HealthTargetsCompanion(
      id: id ?? this.id,
      metric: metric ?? this.metric,
      threshold: threshold ?? this.threshold,
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
      lastMetAt: lastMetAt ?? this.lastMetAt,
      reminderTime: reminderTime ?? this.reminderTime,
      activeDaysMask: activeDaysMask ?? this.activeDaysMask,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(metric.value);
    }
    if (threshold.present) {
      map['threshold'] = Variable<String>(threshold.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (lastMetAt.present) {
      map['last_met_at'] = Variable<DateTime>(lastMetAt.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (activeDaysMask.present) {
      map['active_days_mask'] = Variable<int>(activeDaysMask.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthTargetsCompanion(')
          ..write('id: $id, ')
          ..write('metric: $metric, ')
          ..write('threshold: $threshold, ')
          ..write('createdAt: $createdAt, ')
          ..write('active: $active, ')
          ..write('lastMetAt: $lastMetAt, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('activeDaysMask: $activeDaysMask')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledForMeta = const VerificationMeta(
    'scheduledFor',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledFor = GeneratedColumn<DateTime>(
    'scheduled_for',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toolMeta = const VerificationMeta('tool');
  @override
  late final GeneratedColumn<String> tool = GeneratedColumn<String>(
    'tool',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _todoIdMeta = const VerificationMeta('todoId');
  @override
  late final GeneratedColumn<int> todoId = GeneratedColumn<int>(
    'todo_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthTargetIdMeta = const VerificationMeta(
    'healthTargetId',
  );
  @override
  late final GeneratedColumn<int> healthTargetId = GeneratedColumn<int>(
    'health_target_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firedAtMeta = const VerificationMeta(
    'firedAt',
  );
  @override
  late final GeneratedColumn<DateTime> firedAt = GeneratedColumn<DateTime>(
    'fired_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelledMeta = const VerificationMeta(
    'cancelled',
  );
  @override
  late final GeneratedColumn<bool> cancelled = GeneratedColumn<bool>(
    'cancelled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cancelled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    scheduledFor,
    tool,
    createdAt,
    todoId,
    healthTargetId,
    firedAt,
    cancelled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('scheduled_for')) {
      context.handle(
        _scheduledForMeta,
        scheduledFor.isAcceptableOrUnknown(
          data['scheduled_for']!,
          _scheduledForMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledForMeta);
    }
    if (data.containsKey('tool')) {
      context.handle(
        _toolMeta,
        tool.isAcceptableOrUnknown(data['tool']!, _toolMeta),
      );
    } else if (isInserting) {
      context.missing(_toolMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('todo_id')) {
      context.handle(
        _todoIdMeta,
        todoId.isAcceptableOrUnknown(data['todo_id']!, _todoIdMeta),
      );
    }
    if (data.containsKey('health_target_id')) {
      context.handle(
        _healthTargetIdMeta,
        healthTargetId.isAcceptableOrUnknown(
          data['health_target_id']!,
          _healthTargetIdMeta,
        ),
      );
    }
    if (data.containsKey('fired_at')) {
      context.handle(
        _firedAtMeta,
        firedAt.isAcceptableOrUnknown(data['fired_at']!, _firedAtMeta),
      );
    }
    if (data.containsKey('cancelled')) {
      context.handle(
        _cancelledMeta,
        cancelled.isAcceptableOrUnknown(data['cancelled']!, _cancelledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      scheduledFor: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_for'],
      )!,
      tool: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      todoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}todo_id'],
      ),
      healthTargetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}health_target_id'],
      ),
      firedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fired_at'],
      ),
      cancelled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cancelled'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final int id;
  final String title;
  final DateTime scheduledFor;

  /// `TaskTool.name`. Stored by name, not index — see the equivalent
  /// note on `Todos.difficulty`.
  final String tool;
  final DateTime createdAt;
  final int? todoId;

  /// Set when this reminder is one occurrence of a health target's
  /// recurring schedule, rather than tied to a todo. A row is never
  /// linked to both — each reminder has exactly one owner.
  final int? healthTargetId;
  final DateTime? firedAt;
  final bool cancelled;
  const ReminderRow({
    required this.id,
    required this.title,
    required this.scheduledFor,
    required this.tool,
    required this.createdAt,
    this.todoId,
    this.healthTargetId,
    this.firedAt,
    required this.cancelled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['scheduled_for'] = Variable<DateTime>(scheduledFor);
    map['tool'] = Variable<String>(tool);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || todoId != null) {
      map['todo_id'] = Variable<int>(todoId);
    }
    if (!nullToAbsent || healthTargetId != null) {
      map['health_target_id'] = Variable<int>(healthTargetId);
    }
    if (!nullToAbsent || firedAt != null) {
      map['fired_at'] = Variable<DateTime>(firedAt);
    }
    map['cancelled'] = Variable<bool>(cancelled);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      scheduledFor: Value(scheduledFor),
      tool: Value(tool),
      createdAt: Value(createdAt),
      todoId: todoId == null && nullToAbsent
          ? const Value.absent()
          : Value(todoId),
      healthTargetId: healthTargetId == null && nullToAbsent
          ? const Value.absent()
          : Value(healthTargetId),
      firedAt: firedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firedAt),
      cancelled: Value(cancelled),
    );
  }

  factory ReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      scheduledFor: serializer.fromJson<DateTime>(json['scheduledFor']),
      tool: serializer.fromJson<String>(json['tool']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      todoId: serializer.fromJson<int?>(json['todoId']),
      healthTargetId: serializer.fromJson<int?>(json['healthTargetId']),
      firedAt: serializer.fromJson<DateTime?>(json['firedAt']),
      cancelled: serializer.fromJson<bool>(json['cancelled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'scheduledFor': serializer.toJson<DateTime>(scheduledFor),
      'tool': serializer.toJson<String>(tool),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'todoId': serializer.toJson<int?>(todoId),
      'healthTargetId': serializer.toJson<int?>(healthTargetId),
      'firedAt': serializer.toJson<DateTime?>(firedAt),
      'cancelled': serializer.toJson<bool>(cancelled),
    };
  }

  ReminderRow copyWith({
    int? id,
    String? title,
    DateTime? scheduledFor,
    String? tool,
    DateTime? createdAt,
    Value<int?> todoId = const Value.absent(),
    Value<int?> healthTargetId = const Value.absent(),
    Value<DateTime?> firedAt = const Value.absent(),
    bool? cancelled,
  }) => ReminderRow(
    id: id ?? this.id,
    title: title ?? this.title,
    scheduledFor: scheduledFor ?? this.scheduledFor,
    tool: tool ?? this.tool,
    createdAt: createdAt ?? this.createdAt,
    todoId: todoId.present ? todoId.value : this.todoId,
    healthTargetId: healthTargetId.present
        ? healthTargetId.value
        : this.healthTargetId,
    firedAt: firedAt.present ? firedAt.value : this.firedAt,
    cancelled: cancelled ?? this.cancelled,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      scheduledFor: data.scheduledFor.present
          ? data.scheduledFor.value
          : this.scheduledFor,
      tool: data.tool.present ? data.tool.value : this.tool,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      todoId: data.todoId.present ? data.todoId.value : this.todoId,
      healthTargetId: data.healthTargetId.present
          ? data.healthTargetId.value
          : this.healthTargetId,
      firedAt: data.firedAt.present ? data.firedAt.value : this.firedAt,
      cancelled: data.cancelled.present ? data.cancelled.value : this.cancelled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('tool: $tool, ')
          ..write('createdAt: $createdAt, ')
          ..write('todoId: $todoId, ')
          ..write('healthTargetId: $healthTargetId, ')
          ..write('firedAt: $firedAt, ')
          ..write('cancelled: $cancelled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    scheduledFor,
    tool,
    createdAt,
    todoId,
    healthTargetId,
    firedAt,
    cancelled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.scheduledFor == this.scheduledFor &&
          other.tool == this.tool &&
          other.createdAt == this.createdAt &&
          other.todoId == this.todoId &&
          other.healthTargetId == this.healthTargetId &&
          other.firedAt == this.firedAt &&
          other.cancelled == this.cancelled);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<DateTime> scheduledFor;
  final Value<String> tool;
  final Value<DateTime> createdAt;
  final Value<int?> todoId;
  final Value<int?> healthTargetId;
  final Value<DateTime?> firedAt;
  final Value<bool> cancelled;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.tool = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.todoId = const Value.absent(),
    this.healthTargetId = const Value.absent(),
    this.firedAt = const Value.absent(),
    this.cancelled = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required DateTime scheduledFor,
    required String tool,
    required DateTime createdAt,
    this.todoId = const Value.absent(),
    this.healthTargetId = const Value.absent(),
    this.firedAt = const Value.absent(),
    this.cancelled = const Value.absent(),
  }) : title = Value(title),
       scheduledFor = Value(scheduledFor),
       tool = Value(tool),
       createdAt = Value(createdAt);
  static Insertable<ReminderRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<DateTime>? scheduledFor,
    Expression<String>? tool,
    Expression<DateTime>? createdAt,
    Expression<int>? todoId,
    Expression<int>? healthTargetId,
    Expression<DateTime>? firedAt,
    Expression<bool>? cancelled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (scheduledFor != null) 'scheduled_for': scheduledFor,
      if (tool != null) 'tool': tool,
      if (createdAt != null) 'created_at': createdAt,
      if (todoId != null) 'todo_id': todoId,
      if (healthTargetId != null) 'health_target_id': healthTargetId,
      if (firedAt != null) 'fired_at': firedAt,
      if (cancelled != null) 'cancelled': cancelled,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<DateTime>? scheduledFor,
    Value<String>? tool,
    Value<DateTime>? createdAt,
    Value<int?>? todoId,
    Value<int?>? healthTargetId,
    Value<DateTime?>? firedAt,
    Value<bool>? cancelled,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      tool: tool ?? this.tool,
      createdAt: createdAt ?? this.createdAt,
      todoId: todoId ?? this.todoId,
      healthTargetId: healthTargetId ?? this.healthTargetId,
      firedAt: firedAt ?? this.firedAt,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (scheduledFor.present) {
      map['scheduled_for'] = Variable<DateTime>(scheduledFor.value);
    }
    if (tool.present) {
      map['tool'] = Variable<String>(tool.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (todoId.present) {
      map['todo_id'] = Variable<int>(todoId.value);
    }
    if (healthTargetId.present) {
      map['health_target_id'] = Variable<int>(healthTargetId.value);
    }
    if (firedAt.present) {
      map['fired_at'] = Variable<DateTime>(firedAt.value);
    }
    if (cancelled.present) {
      map['cancelled'] = Variable<bool>(cancelled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('tool: $tool, ')
          ..write('createdAt: $createdAt, ')
          ..write('todoId: $todoId, ')
          ..write('healthTargetId: $healthTargetId, ')
          ..write('firedAt: $firedAt, ')
          ..write('cancelled: $cancelled')
          ..write(')'))
        .toString();
  }
}

class $CapturesTable extends Captures
    with TableInfo<$CapturesTable, CaptureRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CapturesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extractedTextMeta = const VerificationMeta(
    'extractedText',
  );
  @override
  late final GeneratedColumn<String> extractedText = GeneratedColumn<String>(
    'extracted_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<Uint8List> embedding = GeneratedColumn<Uint8List>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingModelMeta = const VerificationMeta(
    'embeddingModel',
  );
  @override
  late final GeneratedColumn<String> embeddingModel = GeneratedColumn<String>(
    'embedding_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _embeddingDimensionsMeta =
      const VerificationMeta('embeddingDimensions');
  @override
  late final GeneratedColumn<int> embeddingDimensions = GeneratedColumn<int>(
    'embedding_dimensions',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    imagePath,
    extractedText,
    embedding,
    embeddingModel,
    embeddingDimensions,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'captures';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaptureRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('extracted_text')) {
      context.handle(
        _extractedTextMeta,
        extractedText.isAcceptableOrUnknown(
          data['extracted_text']!,
          _extractedTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_extractedTextMeta);
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    if (data.containsKey('embedding_model')) {
      context.handle(
        _embeddingModelMeta,
        embeddingModel.isAcceptableOrUnknown(
          data['embedding_model']!,
          _embeddingModelMeta,
        ),
      );
    }
    if (data.containsKey('embedding_dimensions')) {
      context.handle(
        _embeddingDimensionsMeta,
        embeddingDimensions.isAcceptableOrUnknown(
          data['embedding_dimensions']!,
          _embeddingDimensionsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CaptureRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaptureRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      extractedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_text'],
      )!,
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}embedding'],
      ),
      embeddingModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding_model'],
      ),
      embeddingDimensions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}embedding_dimensions'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CapturesTable createAlias(String alias) {
    return $CapturesTable(attachedDatabase, alias);
  }
}

class CaptureRow extends DataClass implements Insertable<CaptureRow> {
  final int id;

  /// Path to the cropped PNG the overlay produced.
  final String imagePath;

  /// Text extracted by OCR, as the user confirmed it. Named
  /// `extractedText`, not `text`, because `text` is Drift's own
  /// column-builder method on [Table] and would collide.
  final String extractedText;

  /// Embedding of [extractedText], stored as little-endian float64s.
  ///
  /// Nullable because a capture is still worth keeping if the embedder
  /// wasn't available — it just can't be searched semantically until
  /// it's re-embedded.
  final Uint8List? embedding;

  /// Which embedder produced [embedding]. Vectors from a different model
  /// aren't comparable, so this is what lets stale ones be detected
  /// rather than silently compared.
  final String? embeddingModel;
  final int? embeddingDimensions;
  final DateTime createdAt;
  const CaptureRow({
    required this.id,
    required this.imagePath,
    required this.extractedText,
    this.embedding,
    this.embeddingModel,
    this.embeddingDimensions,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['image_path'] = Variable<String>(imagePath);
    map['extracted_text'] = Variable<String>(extractedText);
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<Uint8List>(embedding);
    }
    if (!nullToAbsent || embeddingModel != null) {
      map['embedding_model'] = Variable<String>(embeddingModel);
    }
    if (!nullToAbsent || embeddingDimensions != null) {
      map['embedding_dimensions'] = Variable<int>(embeddingDimensions);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CapturesCompanion toCompanion(bool nullToAbsent) {
    return CapturesCompanion(
      id: Value(id),
      imagePath: Value(imagePath),
      extractedText: Value(extractedText),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
      embeddingModel: embeddingModel == null && nullToAbsent
          ? const Value.absent()
          : Value(embeddingModel),
      embeddingDimensions: embeddingDimensions == null && nullToAbsent
          ? const Value.absent()
          : Value(embeddingDimensions),
      createdAt: Value(createdAt),
    );
  }

  factory CaptureRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaptureRow(
      id: serializer.fromJson<int>(json['id']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      extractedText: serializer.fromJson<String>(json['extractedText']),
      embedding: serializer.fromJson<Uint8List?>(json['embedding']),
      embeddingModel: serializer.fromJson<String?>(json['embeddingModel']),
      embeddingDimensions: serializer.fromJson<int?>(
        json['embeddingDimensions'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'imagePath': serializer.toJson<String>(imagePath),
      'extractedText': serializer.toJson<String>(extractedText),
      'embedding': serializer.toJson<Uint8List?>(embedding),
      'embeddingModel': serializer.toJson<String?>(embeddingModel),
      'embeddingDimensions': serializer.toJson<int?>(embeddingDimensions),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CaptureRow copyWith({
    int? id,
    String? imagePath,
    String? extractedText,
    Value<Uint8List?> embedding = const Value.absent(),
    Value<String?> embeddingModel = const Value.absent(),
    Value<int?> embeddingDimensions = const Value.absent(),
    DateTime? createdAt,
  }) => CaptureRow(
    id: id ?? this.id,
    imagePath: imagePath ?? this.imagePath,
    extractedText: extractedText ?? this.extractedText,
    embedding: embedding.present ? embedding.value : this.embedding,
    embeddingModel: embeddingModel.present
        ? embeddingModel.value
        : this.embeddingModel,
    embeddingDimensions: embeddingDimensions.present
        ? embeddingDimensions.value
        : this.embeddingDimensions,
    createdAt: createdAt ?? this.createdAt,
  );
  CaptureRow copyWithCompanion(CapturesCompanion data) {
    return CaptureRow(
      id: data.id.present ? data.id.value : this.id,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      extractedText: data.extractedText.present
          ? data.extractedText.value
          : this.extractedText,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      embeddingModel: data.embeddingModel.present
          ? data.embeddingModel.value
          : this.embeddingModel,
      embeddingDimensions: data.embeddingDimensions.present
          ? data.embeddingDimensions.value
          : this.embeddingDimensions,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaptureRow(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('extractedText: $extractedText, ')
          ..write('embedding: $embedding, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('embeddingDimensions: $embeddingDimensions, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    imagePath,
    extractedText,
    $driftBlobEquality.hash(embedding),
    embeddingModel,
    embeddingDimensions,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaptureRow &&
          other.id == this.id &&
          other.imagePath == this.imagePath &&
          other.extractedText == this.extractedText &&
          $driftBlobEquality.equals(other.embedding, this.embedding) &&
          other.embeddingModel == this.embeddingModel &&
          other.embeddingDimensions == this.embeddingDimensions &&
          other.createdAt == this.createdAt);
}

class CapturesCompanion extends UpdateCompanion<CaptureRow> {
  final Value<int> id;
  final Value<String> imagePath;
  final Value<String> extractedText;
  final Value<Uint8List?> embedding;
  final Value<String?> embeddingModel;
  final Value<int?> embeddingDimensions;
  final Value<DateTime> createdAt;
  const CapturesCompanion({
    this.id = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.embedding = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.embeddingDimensions = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CapturesCompanion.insert({
    this.id = const Value.absent(),
    required String imagePath,
    required String extractedText,
    this.embedding = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.embeddingDimensions = const Value.absent(),
    required DateTime createdAt,
  }) : imagePath = Value(imagePath),
       extractedText = Value(extractedText),
       createdAt = Value(createdAt);
  static Insertable<CaptureRow> custom({
    Expression<int>? id,
    Expression<String>? imagePath,
    Expression<String>? extractedText,
    Expression<Uint8List>? embedding,
    Expression<String>? embeddingModel,
    Expression<int>? embeddingDimensions,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imagePath != null) 'image_path': imagePath,
      if (extractedText != null) 'extracted_text': extractedText,
      if (embedding != null) 'embedding': embedding,
      if (embeddingModel != null) 'embedding_model': embeddingModel,
      if (embeddingDimensions != null)
        'embedding_dimensions': embeddingDimensions,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CapturesCompanion copyWith({
    Value<int>? id,
    Value<String>? imagePath,
    Value<String>? extractedText,
    Value<Uint8List?>? embedding,
    Value<String?>? embeddingModel,
    Value<int?>? embeddingDimensions,
    Value<DateTime>? createdAt,
  }) {
    return CapturesCompanion(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      embedding: embedding ?? this.embedding,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      embeddingDimensions: embeddingDimensions ?? this.embeddingDimensions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (extractedText.present) {
      map['extracted_text'] = Variable<String>(extractedText.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<Uint8List>(embedding.value);
    }
    if (embeddingModel.present) {
      map['embedding_model'] = Variable<String>(embeddingModel.value);
    }
    if (embeddingDimensions.present) {
      map['embedding_dimensions'] = Variable<int>(embeddingDimensions.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CapturesCompanion(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('extractedText: $extractedText, ')
          ..write('embedding: $embedding, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('embeddingDimensions: $embeddingDimensions, ')
          ..write('createdAt: $createdAt')
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
  late final $TodosTable todos = $TodosTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $HealthTargetsTable healthTargets = $HealthTargetsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $CapturesTable captures = $CapturesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    signalBuckets,
    gamificationEvents,
    todos,
    notes,
    healthTargets,
    reminders,
    captures,
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
typedef $$TodosTableCreateCompanionBuilder =
    TodosCompanion Function({
      Value<int> id,
      required String title,
      required DateTime createdAt,
      Value<DateTime?> deadline,
      Value<String?> difficulty,
      Value<DateTime?> completedAt,
      Value<String?> notes,
      Value<int?> parentId,
    });
typedef $$TodosTableUpdateCompanionBuilder =
    TodosCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<DateTime?> deadline,
      Value<String?> difficulty,
      Value<DateTime?> completedAt,
      Value<String?> notes,
      Value<int?> parentId,
    });

class $$TodosTableFilterComposer extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TodosTableOrderingComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TodosTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);
}

class $$TodosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TodosTable,
          TodoRow,
          $$TodosTableFilterComposer,
          $$TodosTableOrderingComposer,
          $$TodosTableAnnotationComposer,
          $$TodosTableCreateCompanionBuilder,
          $$TodosTableUpdateCompanionBuilder,
          (TodoRow, BaseReferences<_$AppDatabase, $TodosTable, TodoRow>),
          TodoRow,
          PrefetchHooks Function()
        > {
  $$TodosTableTableManager(_$AppDatabase db, $TodosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
              }) => TodosCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                deadline: deadline,
                difficulty: difficulty,
                completedAt: completedAt,
                notes: notes,
                parentId: parentId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required DateTime createdAt,
                Value<DateTime?> deadline = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
              }) => TodosCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                deadline: deadline,
                difficulty: difficulty,
                completedAt: completedAt,
                notes: notes,
                parentId: parentId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TodosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TodosTable,
      TodoRow,
      $$TodosTableFilterComposer,
      $$TodosTableOrderingComposer,
      $$TodosTableAnnotationComposer,
      $$TodosTableCreateCompanionBuilder,
      $$TodosTableUpdateCompanionBuilder,
      (TodoRow, BaseReferences<_$AppDatabase, $TodosTable, TodoRow>),
      TodoRow,
      PrefetchHooks Function()
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      required String body,
      required DateTime createdAt,
      Value<int?> sourceCaptureId,
      Value<Uint8List?> embedding,
      Value<String?> embeddingModel,
      Value<int?> embeddingDimensions,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<int?> sourceCaptureId,
      Value<Uint8List?> embedding,
      Value<String?> embeddingModel,
      Value<int?> embeddingDimensions,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
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

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceCaptureId => $composableBuilder(
    column: $table.sourceCaptureId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get embeddingDimensions => $composableBuilder(
    column: $table.embeddingDimensions,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
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

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceCaptureId => $composableBuilder(
    column: $table.sourceCaptureId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get embeddingDimensions => $composableBuilder(
    column: $table.embeddingDimensions,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sourceCaptureId => $composableBuilder(
    column: $table.sourceCaptureId,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get embeddingDimensions => $composableBuilder(
    column: $table.embeddingDimensions,
    builder: (column) => column,
  );
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          NoteRow,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
          NoteRow,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> sourceCaptureId = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
                Value<String?> embeddingModel = const Value.absent(),
                Value<int?> embeddingDimensions = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                body: body,
                createdAt: createdAt,
                sourceCaptureId: sourceCaptureId,
                embedding: embedding,
                embeddingModel: embeddingModel,
                embeddingDimensions: embeddingDimensions,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String body,
                required DateTime createdAt,
                Value<int?> sourceCaptureId = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
                Value<String?> embeddingModel = const Value.absent(),
                Value<int?> embeddingDimensions = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                body: body,
                createdAt: createdAt,
                sourceCaptureId: sourceCaptureId,
                embedding: embedding,
                embeddingModel: embeddingModel,
                embeddingDimensions: embeddingDimensions,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      NoteRow,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
      NoteRow,
      PrefetchHooks Function()
    >;
typedef $$HealthTargetsTableCreateCompanionBuilder =
    HealthTargetsCompanion Function({
      Value<int> id,
      required String metric,
      required String threshold,
      required DateTime createdAt,
      Value<bool> active,
      Value<DateTime?> lastMetAt,
      Value<String?> reminderTime,
      Value<int?> activeDaysMask,
    });
typedef $$HealthTargetsTableUpdateCompanionBuilder =
    HealthTargetsCompanion Function({
      Value<int> id,
      Value<String> metric,
      Value<String> threshold,
      Value<DateTime> createdAt,
      Value<bool> active,
      Value<DateTime?> lastMetAt,
      Value<String?> reminderTime,
      Value<int?> activeDaysMask,
    });

class $$HealthTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $HealthTargetsTable> {
  $$HealthTargetsTableFilterComposer({
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

  ColumnFilters<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threshold => $composableBuilder(
    column: $table.threshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMetAt => $composableBuilder(
    column: $table.lastMetAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeDaysMask => $composableBuilder(
    column: $table.activeDaysMask,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthTargetsTable> {
  $$HealthTargetsTableOrderingComposer({
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

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threshold => $composableBuilder(
    column: $table.threshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMetAt => $composableBuilder(
    column: $table.lastMetAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeDaysMask => $composableBuilder(
    column: $table.activeDaysMask,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthTargetsTable> {
  $$HealthTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<String> get threshold =>
      $composableBuilder(column: $table.threshold, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMetAt =>
      $composableBuilder(column: $table.lastMetAt, builder: (column) => column);

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activeDaysMask => $composableBuilder(
    column: $table.activeDaysMask,
    builder: (column) => column,
  );
}

class $$HealthTargetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthTargetsTable,
          HealthTargetRow,
          $$HealthTargetsTableFilterComposer,
          $$HealthTargetsTableOrderingComposer,
          $$HealthTargetsTableAnnotationComposer,
          $$HealthTargetsTableCreateCompanionBuilder,
          $$HealthTargetsTableUpdateCompanionBuilder,
          (
            HealthTargetRow,
            BaseReferences<_$AppDatabase, $HealthTargetsTable, HealthTargetRow>,
          ),
          HealthTargetRow,
          PrefetchHooks Function()
        > {
  $$HealthTargetsTableTableManager(_$AppDatabase db, $HealthTargetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthTargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> metric = const Value.absent(),
                Value<String> threshold = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime?> lastMetAt = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<int?> activeDaysMask = const Value.absent(),
              }) => HealthTargetsCompanion(
                id: id,
                metric: metric,
                threshold: threshold,
                createdAt: createdAt,
                active: active,
                lastMetAt: lastMetAt,
                reminderTime: reminderTime,
                activeDaysMask: activeDaysMask,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String metric,
                required String threshold,
                required DateTime createdAt,
                Value<bool> active = const Value.absent(),
                Value<DateTime?> lastMetAt = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<int?> activeDaysMask = const Value.absent(),
              }) => HealthTargetsCompanion.insert(
                id: id,
                metric: metric,
                threshold: threshold,
                createdAt: createdAt,
                active: active,
                lastMetAt: lastMetAt,
                reminderTime: reminderTime,
                activeDaysMask: activeDaysMask,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthTargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthTargetsTable,
      HealthTargetRow,
      $$HealthTargetsTableFilterComposer,
      $$HealthTargetsTableOrderingComposer,
      $$HealthTargetsTableAnnotationComposer,
      $$HealthTargetsTableCreateCompanionBuilder,
      $$HealthTargetsTableUpdateCompanionBuilder,
      (
        HealthTargetRow,
        BaseReferences<_$AppDatabase, $HealthTargetsTable, HealthTargetRow>,
      ),
      HealthTargetRow,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      required String title,
      required DateTime scheduledFor,
      required String tool,
      required DateTime createdAt,
      Value<int?> todoId,
      Value<int?> healthTargetId,
      Value<DateTime?> firedAt,
      Value<bool> cancelled,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<DateTime> scheduledFor,
      Value<String> tool,
      Value<DateTime> createdAt,
      Value<int?> todoId,
      Value<int?> healthTargetId,
      Value<DateTime?> firedAt,
      Value<bool> cancelled,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tool => $composableBuilder(
    column: $table.tool,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get todoId => $composableBuilder(
    column: $table.todoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get healthTargetId => $composableBuilder(
    column: $table.healthTargetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firedAt => $composableBuilder(
    column: $table.firedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tool => $composableBuilder(
    column: $table.tool,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get todoId => $composableBuilder(
    column: $table.todoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get healthTargetId => $composableBuilder(
    column: $table.healthTargetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firedAt => $composableBuilder(
    column: $table.firedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tool =>
      $composableBuilder(column: $table.tool, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get todoId =>
      $composableBuilder(column: $table.todoId, builder: (column) => column);

  GeneratedColumn<int> get healthTargetId => $composableBuilder(
    column: $table.healthTargetId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firedAt =>
      $composableBuilder(column: $table.firedAt, builder: (column) => column);

  GeneratedColumn<bool> get cancelled =>
      $composableBuilder(column: $table.cancelled, builder: (column) => column);
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          ReminderRow,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (
            ReminderRow,
            BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>,
          ),
          ReminderRow,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> scheduledFor = const Value.absent(),
                Value<String> tool = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> todoId = const Value.absent(),
                Value<int?> healthTargetId = const Value.absent(),
                Value<DateTime?> firedAt = const Value.absent(),
                Value<bool> cancelled = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                title: title,
                scheduledFor: scheduledFor,
                tool: tool,
                createdAt: createdAt,
                todoId: todoId,
                healthTargetId: healthTargetId,
                firedAt: firedAt,
                cancelled: cancelled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required DateTime scheduledFor,
                required String tool,
                required DateTime createdAt,
                Value<int?> todoId = const Value.absent(),
                Value<int?> healthTargetId = const Value.absent(),
                Value<DateTime?> firedAt = const Value.absent(),
                Value<bool> cancelled = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                title: title,
                scheduledFor: scheduledFor,
                tool: tool,
                createdAt: createdAt,
                todoId: todoId,
                healthTargetId: healthTargetId,
                firedAt: firedAt,
                cancelled: cancelled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      ReminderRow,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (
        ReminderRow,
        BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>,
      ),
      ReminderRow,
      PrefetchHooks Function()
    >;
typedef $$CapturesTableCreateCompanionBuilder =
    CapturesCompanion Function({
      Value<int> id,
      required String imagePath,
      required String extractedText,
      Value<Uint8List?> embedding,
      Value<String?> embeddingModel,
      Value<int?> embeddingDimensions,
      required DateTime createdAt,
    });
typedef $$CapturesTableUpdateCompanionBuilder =
    CapturesCompanion Function({
      Value<int> id,
      Value<String> imagePath,
      Value<String> extractedText,
      Value<Uint8List?> embedding,
      Value<String?> embeddingModel,
      Value<int?> embeddingDimensions,
      Value<DateTime> createdAt,
    });

class $$CapturesTableFilterComposer
    extends Composer<_$AppDatabase, $CapturesTable> {
  $$CapturesTableFilterComposer({
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

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get embeddingDimensions => $composableBuilder(
    column: $table.embeddingDimensions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CapturesTableOrderingComposer
    extends Composer<_$AppDatabase, $CapturesTable> {
  $$CapturesTableOrderingComposer({
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

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get embeddingDimensions => $composableBuilder(
    column: $table.embeddingDimensions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CapturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CapturesTable> {
  $$CapturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<String> get embeddingModel => $composableBuilder(
    column: $table.embeddingModel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get embeddingDimensions => $composableBuilder(
    column: $table.embeddingDimensions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CapturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CapturesTable,
          CaptureRow,
          $$CapturesTableFilterComposer,
          $$CapturesTableOrderingComposer,
          $$CapturesTableAnnotationComposer,
          $$CapturesTableCreateCompanionBuilder,
          $$CapturesTableUpdateCompanionBuilder,
          (
            CaptureRow,
            BaseReferences<_$AppDatabase, $CapturesTable, CaptureRow>,
          ),
          CaptureRow,
          PrefetchHooks Function()
        > {
  $$CapturesTableTableManager(_$AppDatabase db, $CapturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CapturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CapturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CapturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<String> extractedText = const Value.absent(),
                Value<Uint8List?> embedding = const Value.absent(),
                Value<String?> embeddingModel = const Value.absent(),
                Value<int?> embeddingDimensions = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CapturesCompanion(
                id: id,
                imagePath: imagePath,
                extractedText: extractedText,
                embedding: embedding,
                embeddingModel: embeddingModel,
                embeddingDimensions: embeddingDimensions,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String imagePath,
                required String extractedText,
                Value<Uint8List?> embedding = const Value.absent(),
                Value<String?> embeddingModel = const Value.absent(),
                Value<int?> embeddingDimensions = const Value.absent(),
                required DateTime createdAt,
              }) => CapturesCompanion.insert(
                id: id,
                imagePath: imagePath,
                extractedText: extractedText,
                embedding: embedding,
                embeddingModel: embeddingModel,
                embeddingDimensions: embeddingDimensions,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CapturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CapturesTable,
      CaptureRow,
      $$CapturesTableFilterComposer,
      $$CapturesTableOrderingComposer,
      $$CapturesTableAnnotationComposer,
      $$CapturesTableCreateCompanionBuilder,
      $$CapturesTableUpdateCompanionBuilder,
      (CaptureRow, BaseReferences<_$AppDatabase, $CapturesTable, CaptureRow>),
      CaptureRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SignalBucketsTableTableManager get signalBuckets =>
      $$SignalBucketsTableTableManager(_db, _db.signalBuckets);
  $$GamificationEventsTableTableManager get gamificationEvents =>
      $$GamificationEventsTableTableManager(_db, _db.gamificationEvents);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db, _db.todos);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$HealthTargetsTableTableManager get healthTargets =>
      $$HealthTargetsTableTableManager(_db, _db.healthTargets);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$CapturesTableTableManager get captures =>
      $$CapturesTableTableManager(_db, _db.captures);
}
