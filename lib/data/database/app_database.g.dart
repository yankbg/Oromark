// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _courseCodeMeta = const VerificationMeta(
    'courseCode',
  );
  @override
  late final GeneratedColumn<String> courseCode = GeneratedColumn<String>(
    'course_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseNameMeta = const VerificationMeta(
    'courseName',
  );
  @override
  late final GeneratedColumn<String> courseName = GeneratedColumn<String>(
    'course_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lecturerNameMeta = const VerificationMeta(
    'lecturerName',
  );
  @override
  late final GeneratedColumn<String> lecturerName = GeneratedColumn<String>(
    'lecturer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roomCodeMeta = const VerificationMeta(
    'roomCode',
  );
  @override
  late final GeneratedColumn<String> roomCode = GeneratedColumn<String>(
    'room_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presentCutoffMeta = const VerificationMeta(
    'presentCutoff',
  );
  @override
  late final GeneratedColumn<String> presentCutoff = GeneratedColumn<String>(
    'present_cutoff',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lateCutoffMeta = const VerificationMeta(
    'lateCutoff',
  );
  @override
  late final GeneratedColumn<String> lateCutoff = GeneratedColumn<String>(
    'late_cutoff',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    courseCode,
    courseName,
    lecturerName,
    roomCode,
    startTime,
    endTime,
    presentCutoff,
    lateCutoff,
    status,
    synced,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('course_code')) {
      context.handle(
        _courseCodeMeta,
        courseCode.isAcceptableOrUnknown(data['course_code']!, _courseCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_courseCodeMeta);
    }
    if (data.containsKey('course_name')) {
      context.handle(
        _courseNameMeta,
        courseName.isAcceptableOrUnknown(data['course_name']!, _courseNameMeta),
      );
    } else if (isInserting) {
      context.missing(_courseNameMeta);
    }
    if (data.containsKey('lecturer_name')) {
      context.handle(
        _lecturerNameMeta,
        lecturerName.isAcceptableOrUnknown(
          data['lecturer_name']!,
          _lecturerNameMeta,
        ),
      );
    }
    if (data.containsKey('room_code')) {
      context.handle(
        _roomCodeMeta,
        roomCode.isAcceptableOrUnknown(data['room_code']!, _roomCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_roomCodeMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('present_cutoff')) {
      context.handle(
        _presentCutoffMeta,
        presentCutoff.isAcceptableOrUnknown(
          data['present_cutoff']!,
          _presentCutoffMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_presentCutoffMeta);
    }
    if (data.containsKey('late_cutoff')) {
      context.handle(
        _lateCutoffMeta,
        lateCutoff.isAcceptableOrUnknown(data['late_cutoff']!, _lateCutoffMeta),
      );
    } else if (isInserting) {
      context.missing(_lateCutoffMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
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
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      courseCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_code'],
      )!,
      courseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_name'],
      )!,
      lecturerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lecturer_name'],
      ),
      roomCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_code'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_time'],
      )!,
      presentCutoff: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}present_cutoff'],
      )!,
      lateCutoff: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}late_cutoff'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String sessionId;
  final String courseCode;
  final String courseName;
  final String? lecturerName;
  final String roomCode;
  final int startTime;
  final int endTime;
  final String presentCutoff;
  final String lateCutoff;
  final String status;
  final bool synced;
  final int createdAt;
  const Session({
    required this.id,
    required this.sessionId,
    required this.courseCode,
    required this.courseName,
    this.lecturerName,
    required this.roomCode,
    required this.startTime,
    required this.endTime,
    required this.presentCutoff,
    required this.lateCutoff,
    required this.status,
    required this.synced,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['course_code'] = Variable<String>(courseCode);
    map['course_name'] = Variable<String>(courseName);
    if (!nullToAbsent || lecturerName != null) {
      map['lecturer_name'] = Variable<String>(lecturerName);
    }
    map['room_code'] = Variable<String>(roomCode);
    map['start_time'] = Variable<int>(startTime);
    map['end_time'] = Variable<int>(endTime);
    map['present_cutoff'] = Variable<String>(presentCutoff);
    map['late_cutoff'] = Variable<String>(lateCutoff);
    map['status'] = Variable<String>(status);
    map['synced'] = Variable<bool>(synced);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      courseCode: Value(courseCode),
      courseName: Value(courseName),
      lecturerName: lecturerName == null && nullToAbsent
          ? const Value.absent()
          : Value(lecturerName),
      roomCode: Value(roomCode),
      startTime: Value(startTime),
      endTime: Value(endTime),
      presentCutoff: Value(presentCutoff),
      lateCutoff: Value(lateCutoff),
      status: Value(status),
      synced: Value(synced),
      createdAt: Value(createdAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      courseCode: serializer.fromJson<String>(json['courseCode']),
      courseName: serializer.fromJson<String>(json['courseName']),
      lecturerName: serializer.fromJson<String?>(json['lecturerName']),
      roomCode: serializer.fromJson<String>(json['roomCode']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int>(json['endTime']),
      presentCutoff: serializer.fromJson<String>(json['presentCutoff']),
      lateCutoff: serializer.fromJson<String>(json['lateCutoff']),
      status: serializer.fromJson<String>(json['status']),
      synced: serializer.fromJson<bool>(json['synced']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'courseCode': serializer.toJson<String>(courseCode),
      'courseName': serializer.toJson<String>(courseName),
      'lecturerName': serializer.toJson<String?>(lecturerName),
      'roomCode': serializer.toJson<String>(roomCode),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int>(endTime),
      'presentCutoff': serializer.toJson<String>(presentCutoff),
      'lateCutoff': serializer.toJson<String>(lateCutoff),
      'status': serializer.toJson<String>(status),
      'synced': serializer.toJson<bool>(synced),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Session copyWith({
    int? id,
    String? sessionId,
    String? courseCode,
    String? courseName,
    Value<String?> lecturerName = const Value.absent(),
    String? roomCode,
    int? startTime,
    int? endTime,
    String? presentCutoff,
    String? lateCutoff,
    String? status,
    bool? synced,
    int? createdAt,
  }) => Session(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    courseCode: courseCode ?? this.courseCode,
    courseName: courseName ?? this.courseName,
    lecturerName: lecturerName.present ? lecturerName.value : this.lecturerName,
    roomCode: roomCode ?? this.roomCode,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    presentCutoff: presentCutoff ?? this.presentCutoff,
    lateCutoff: lateCutoff ?? this.lateCutoff,
    status: status ?? this.status,
    synced: synced ?? this.synced,
    createdAt: createdAt ?? this.createdAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      courseCode: data.courseCode.present
          ? data.courseCode.value
          : this.courseCode,
      courseName: data.courseName.present
          ? data.courseName.value
          : this.courseName,
      lecturerName: data.lecturerName.present
          ? data.lecturerName.value
          : this.lecturerName,
      roomCode: data.roomCode.present ? data.roomCode.value : this.roomCode,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      presentCutoff: data.presentCutoff.present
          ? data.presentCutoff.value
          : this.presentCutoff,
      lateCutoff: data.lateCutoff.present
          ? data.lateCutoff.value
          : this.lateCutoff,
      status: data.status.present ? data.status.value : this.status,
      synced: data.synced.present ? data.synced.value : this.synced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('courseCode: $courseCode, ')
          ..write('courseName: $courseName, ')
          ..write('lecturerName: $lecturerName, ')
          ..write('roomCode: $roomCode, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('presentCutoff: $presentCutoff, ')
          ..write('lateCutoff: $lateCutoff, ')
          ..write('status: $status, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    courseCode,
    courseName,
    lecturerName,
    roomCode,
    startTime,
    endTime,
    presentCutoff,
    lateCutoff,
    status,
    synced,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.courseCode == this.courseCode &&
          other.courseName == this.courseName &&
          other.lecturerName == this.lecturerName &&
          other.roomCode == this.roomCode &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.presentCutoff == this.presentCutoff &&
          other.lateCutoff == this.lateCutoff &&
          other.status == this.status &&
          other.synced == this.synced &&
          other.createdAt == this.createdAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<String> courseCode;
  final Value<String> courseName;
  final Value<String?> lecturerName;
  final Value<String> roomCode;
  final Value<int> startTime;
  final Value<int> endTime;
  final Value<String> presentCutoff;
  final Value<String> lateCutoff;
  final Value<String> status;
  final Value<bool> synced;
  final Value<int> createdAt;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.courseCode = const Value.absent(),
    this.courseName = const Value.absent(),
    this.lecturerName = const Value.absent(),
    this.roomCode = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.presentCutoff = const Value.absent(),
    this.lateCutoff = const Value.absent(),
    this.status = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required String courseCode,
    required String courseName,
    this.lecturerName = const Value.absent(),
    required String roomCode,
    required int startTime,
    required int endTime,
    required String presentCutoff,
    required String lateCutoff,
    required String status,
    this.synced = const Value.absent(),
    required int createdAt,
  }) : sessionId = Value(sessionId),
       courseCode = Value(courseCode),
       courseName = Value(courseName),
       roomCode = Value(roomCode),
       startTime = Value(startTime),
       endTime = Value(endTime),
       presentCutoff = Value(presentCutoff),
       lateCutoff = Value(lateCutoff),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<String>? courseCode,
    Expression<String>? courseName,
    Expression<String>? lecturerName,
    Expression<String>? roomCode,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<String>? presentCutoff,
    Expression<String>? lateCutoff,
    Expression<String>? status,
    Expression<bool>? synced,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (courseCode != null) 'course_code': courseCode,
      if (courseName != null) 'course_name': courseName,
      if (lecturerName != null) 'lecturer_name': lecturerName,
      if (roomCode != null) 'room_code': roomCode,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (presentCutoff != null) 'present_cutoff': presentCutoff,
      if (lateCutoff != null) 'late_cutoff': lateCutoff,
      if (status != null) 'status': status,
      if (synced != null) 'synced': synced,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<String>? courseCode,
    Value<String>? courseName,
    Value<String?>? lecturerName,
    Value<String>? roomCode,
    Value<int>? startTime,
    Value<int>? endTime,
    Value<String>? presentCutoff,
    Value<String>? lateCutoff,
    Value<String>? status,
    Value<bool>? synced,
    Value<int>? createdAt,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      lecturerName: lecturerName ?? this.lecturerName,
      roomCode: roomCode ?? this.roomCode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      presentCutoff: presentCutoff ?? this.presentCutoff,
      lateCutoff: lateCutoff ?? this.lateCutoff,
      status: status ?? this.status,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (courseCode.present) {
      map['course_code'] = Variable<String>(courseCode.value);
    }
    if (courseName.present) {
      map['course_name'] = Variable<String>(courseName.value);
    }
    if (lecturerName.present) {
      map['lecturer_name'] = Variable<String>(lecturerName.value);
    }
    if (roomCode.present) {
      map['room_code'] = Variable<String>(roomCode.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (presentCutoff.present) {
      map['present_cutoff'] = Variable<String>(presentCutoff.value);
    }
    if (lateCutoff.present) {
      map['late_cutoff'] = Variable<String>(lateCutoff.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('courseCode: $courseCode, ')
          ..write('courseName: $courseName, ')
          ..write('lecturerName: $lecturerName, ')
          ..write('roomCode: $roomCode, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('presentCutoff: $presentCutoff, ')
          ..write('lateCutoff: $lateCutoff, ')
          ..write('status: $status, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AttendanceRecordsTable extends AttendanceRecords
    with TableInfo<$AttendanceRecordsTable, AttendanceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    studentId,
    status,
    timestamp,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $AttendanceRecordsTable createAlias(String alias) {
    return $AttendanceRecordsTable(attachedDatabase, alias);
  }
}

class AttendanceRecord extends DataClass
    implements Insertable<AttendanceRecord> {
  final int id;
  final String sessionId;
  final String studentId;
  final String status;
  final int timestamp;
  final bool synced;
  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.timestamp,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['student_id'] = Variable<String>(studentId);
    map['status'] = Variable<String>(status);
    map['timestamp'] = Variable<int>(timestamp);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  AttendanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceRecordsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      studentId: Value(studentId),
      status: Value(status),
      timestamp: Value(timestamp),
      synced: Value(synced),
    );
  }

  factory AttendanceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceRecord(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      status: serializer.fromJson<String>(json['status']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'studentId': serializer.toJson<String>(studentId),
      'status': serializer.toJson<String>(status),
      'timestamp': serializer.toJson<int>(timestamp),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  AttendanceRecord copyWith({
    int? id,
    String? sessionId,
    String? studentId,
    String? status,
    int? timestamp,
    bool? synced,
  }) => AttendanceRecord(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    studentId: studentId ?? this.studentId,
    status: status ?? this.status,
    timestamp: timestamp ?? this.timestamp,
    synced: synced ?? this.synced,
  );
  AttendanceRecord copyWithCompanion(AttendanceRecordsCompanion data) {
    return AttendanceRecord(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      status: data.status.present ? data.status.value : this.status,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecord(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('studentId: $studentId, ')
          ..write('status: $status, ')
          ..write('timestamp: $timestamp, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, studentId, status, timestamp, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceRecord &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.studentId == this.studentId &&
          other.status == this.status &&
          other.timestamp == this.timestamp &&
          other.synced == this.synced);
}

class AttendanceRecordsCompanion extends UpdateCompanion<AttendanceRecord> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<String> studentId;
  final Value<String> status;
  final Value<int> timestamp;
  final Value<bool> synced;
  const AttendanceRecordsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.status = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.synced = const Value.absent(),
  });
  AttendanceRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required String studentId,
    required String status,
    required int timestamp,
    this.synced = const Value.absent(),
  }) : sessionId = Value(sessionId),
       studentId = Value(studentId),
       status = Value(status),
       timestamp = Value(timestamp);
  static Insertable<AttendanceRecord> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<String>? studentId,
    Expression<String>? status,
    Expression<int>? timestamp,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (studentId != null) 'student_id': studentId,
      if (status != null) 'status': status,
      if (timestamp != null) 'timestamp': timestamp,
      if (synced != null) 'synced': synced,
    });
  }

  AttendanceRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<String>? studentId,
    Value<String>? status,
    Value<int>? timestamp,
    Value<bool>? synced,
  }) {
    return AttendanceRecordsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('studentId: $studentId, ')
          ..write('status: $status, ')
          ..write('timestamp: $timestamp, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $AttendanceRecordsTable attendanceRecords =
      $AttendanceRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    attendanceRecords,
  ];
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required String sessionId,
      required String courseCode,
      required String courseName,
      Value<String?> lecturerName,
      required String roomCode,
      required int startTime,
      required int endTime,
      required String presentCutoff,
      required String lateCutoff,
      required String status,
      Value<bool> synced,
      required int createdAt,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<String> sessionId,
      Value<String> courseCode,
      Value<String> courseName,
      Value<String?> lecturerName,
      Value<String> roomCode,
      Value<int> startTime,
      Value<int> endTime,
      Value<String> presentCutoff,
      Value<String> lateCutoff,
      Value<String> status,
      Value<bool> synced,
      Value<int> createdAt,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseCode => $composableBuilder(
    column: $table.courseCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lecturerName => $composableBuilder(
    column: $table.lecturerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomCode => $composableBuilder(
    column: $table.roomCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presentCutoff => $composableBuilder(
    column: $table.presentCutoff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lateCutoff => $composableBuilder(
    column: $table.lateCutoff,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseCode => $composableBuilder(
    column: $table.courseCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lecturerName => $composableBuilder(
    column: $table.lecturerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomCode => $composableBuilder(
    column: $table.roomCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presentCutoff => $composableBuilder(
    column: $table.presentCutoff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lateCutoff => $composableBuilder(
    column: $table.lateCutoff,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get courseCode => $composableBuilder(
    column: $table.courseCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lecturerName => $composableBuilder(
    column: $table.lecturerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roomCode =>
      $composableBuilder(column: $table.roomCode, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get presentCutoff => $composableBuilder(
    column: $table.presentCutoff,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lateCutoff => $composableBuilder(
    column: $table.lateCutoff,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> courseCode = const Value.absent(),
                Value<String> courseName = const Value.absent(),
                Value<String?> lecturerName = const Value.absent(),
                Value<String> roomCode = const Value.absent(),
                Value<int> startTime = const Value.absent(),
                Value<int> endTime = const Value.absent(),
                Value<String> presentCutoff = const Value.absent(),
                Value<String> lateCutoff = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                sessionId: sessionId,
                courseCode: courseCode,
                courseName: courseName,
                lecturerName: lecturerName,
                roomCode: roomCode,
                startTime: startTime,
                endTime: endTime,
                presentCutoff: presentCutoff,
                lateCutoff: lateCutoff,
                status: status,
                synced: synced,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required String courseCode,
                required String courseName,
                Value<String?> lecturerName = const Value.absent(),
                required String roomCode,
                required int startTime,
                required int endTime,
                required String presentCutoff,
                required String lateCutoff,
                required String status,
                Value<bool> synced = const Value.absent(),
                required int createdAt,
              }) => SessionsCompanion.insert(
                id: id,
                sessionId: sessionId,
                courseCode: courseCode,
                courseName: courseName,
                lecturerName: lecturerName,
                roomCode: roomCode,
                startTime: startTime,
                endTime: endTime,
                presentCutoff: presentCutoff,
                lateCutoff: lateCutoff,
                status: status,
                synced: synced,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$AttendanceRecordsTableCreateCompanionBuilder =
    AttendanceRecordsCompanion Function({
      Value<int> id,
      required String sessionId,
      required String studentId,
      required String status,
      required int timestamp,
      Value<bool> synced,
    });
typedef $$AttendanceRecordsTableUpdateCompanionBuilder =
    AttendanceRecordsCompanion Function({
      Value<int> id,
      Value<String> sessionId,
      Value<String> studentId,
      Value<String> status,
      Value<int> timestamp,
      Value<bool> synced,
    });

class $$AttendanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttendanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentId => $composableBuilder(
    column: $table.studentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttendanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$AttendanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceRecordsTable,
          AttendanceRecord,
          $$AttendanceRecordsTableFilterComposer,
          $$AttendanceRecordsTableOrderingComposer,
          $$AttendanceRecordsTableAnnotationComposer,
          $$AttendanceRecordsTableCreateCompanionBuilder,
          $$AttendanceRecordsTableUpdateCompanionBuilder,
          (
            AttendanceRecord,
            BaseReferences<
              _$AppDatabase,
              $AttendanceRecordsTable,
              AttendanceRecord
            >,
          ),
          AttendanceRecord,
          PrefetchHooks Function()
        > {
  $$AttendanceRecordsTableTableManager(
    _$AppDatabase db,
    $AttendanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<bool> synced = const Value.absent(),
              }) => AttendanceRecordsCompanion(
                id: id,
                sessionId: sessionId,
                studentId: studentId,
                status: status,
                timestamp: timestamp,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required String studentId,
                required String status,
                required int timestamp,
                Value<bool> synced = const Value.absent(),
              }) => AttendanceRecordsCompanion.insert(
                id: id,
                sessionId: sessionId,
                studentId: studentId,
                status: status,
                timestamp: timestamp,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttendanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceRecordsTable,
      AttendanceRecord,
      $$AttendanceRecordsTableFilterComposer,
      $$AttendanceRecordsTableOrderingComposer,
      $$AttendanceRecordsTableAnnotationComposer,
      $$AttendanceRecordsTableCreateCompanionBuilder,
      $$AttendanceRecordsTableUpdateCompanionBuilder,
      (
        AttendanceRecord,
        BaseReferences<
          _$AppDatabase,
          $AttendanceRecordsTable,
          AttendanceRecord
        >,
      ),
      AttendanceRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$AttendanceRecordsTableTableManager get attendanceRecords =>
      $$AttendanceRecordsTableTableManager(_db, _db.attendanceRecords);
}
