// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    true,
    check: () => ComparableExpr(startMinute).isBetweenValues(0, 1439),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    check: () => ComparableExpr(durationMinutes).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    localDate,
    name,
    startMinute,
    durationMinutes,
    templateId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSessionRow extends DataClass
    implements Insertable<WorkoutSessionRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The training day, `YYYY-MM-DD`.
  final String localDate;

  /// "Push", or null. User content.
  final String? name;

  /// Start time, minutes after local midnight.
  final int? startMinute;

  /// Duration in minutes.
  final int? durationMinutes;

  /// The template it was started from (WO-022, A36 D4).
  final String? templateId;
  const WorkoutSessionRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.localDate,
    this.name,
    this.startMinute,
    this.durationMinutes,
    this.templateId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['local_date'] = Variable<String>(localDate);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || startMinute != null) {
      map['start_minute'] = Variable<int>(startMinute);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      localDate: Value(localDate),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      startMinute: startMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(startMinute),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
    );
  }

  factory WorkoutSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSessionRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      localDate: serializer.fromJson<String>(json['localDate']),
      name: serializer.fromJson<String?>(json['name']),
      startMinute: serializer.fromJson<int?>(json['startMinute']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      templateId: serializer.fromJson<String?>(json['templateId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'localDate': serializer.toJson<String>(localDate),
      'name': serializer.toJson<String?>(name),
      'startMinute': serializer.toJson<int?>(startMinute),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'templateId': serializer.toJson<String?>(templateId),
    };
  }

  WorkoutSessionRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? localDate,
    Value<String?> name = const Value.absent(),
    Value<int?> startMinute = const Value.absent(),
    Value<int?> durationMinutes = const Value.absent(),
    Value<String?> templateId = const Value.absent(),
  }) => WorkoutSessionRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    localDate: localDate ?? this.localDate,
    name: name.present ? name.value : this.name,
    startMinute: startMinute.present ? startMinute.value : this.startMinute,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    templateId: templateId.present ? templateId.value : this.templateId,
  );
  WorkoutSessionRow copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSessionRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      name: data.name.present ? data.name.value : this.name,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('localDate: $localDate, ')
          ..write('name: $name, ')
          ..write('startMinute: $startMinute, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('templateId: $templateId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    localDate,
    name,
    startMinute,
    durationMinutes,
    templateId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSessionRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.localDate == this.localDate &&
          other.name == this.name &&
          other.startMinute == this.startMinute &&
          other.durationMinutes == this.durationMinutes &&
          other.templateId == this.templateId);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSessionRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> localDate;
  final Value<String?> name;
  final Value<int?> startMinute;
  final Value<int?> durationMinutes;
  final Value<String?> templateId;
  final Value<int> rowid;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.localDate = const Value.absent(),
    this.name = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.templateId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String localDate,
    this.name = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.templateId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       localDate = Value(localDate);
  static Insertable<WorkoutSessionRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? localDate,
    Expression<String>? name,
    Expression<int>? startMinute,
    Expression<int>? durationMinutes,
    Expression<String>? templateId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (localDate != null) 'local_date': localDate,
      if (name != null) 'name': name,
      if (startMinute != null) 'start_minute': startMinute,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (templateId != null) 'template_id': templateId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? localDate,
    Value<String?>? name,
    Value<int?>? startMinute,
    Value<int?>? durationMinutes,
    Value<String?>? templateId,
    Value<int>? rowid,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      localDate: localDate ?? this.localDate,
      name: name ?? this.name,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      templateId: templateId ?? this.templateId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('localDate: $localDate, ')
          ..write('name: $name, ')
          ..write('startMinute: $startMinute, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('templateId: $templateId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionExercisesTable extends SessionExercises
    with TableInfo<$SessionExercisesTable, SessionExerciseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    check: () => ComparableExpr(position).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    sessionId,
    exerciseId,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionExerciseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionExerciseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionExerciseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SessionExercisesTable createAlias(String alias) {
    return $SessionExercisesTable(attachedDatabase, alias);
  }
}

class SessionExerciseRow extends DataClass
    implements Insertable<SessionExerciseRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The session.
  final String sessionId;

  /// A catalog ID (`ex:…`) or a custom exercise's ID.
  final String exerciseId;

  /// Order within the session, from 0.
  final int position;
  const SessionExerciseRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.sessionId,
    required this.exerciseId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['session_id'] = Variable<String>(sessionId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    return map;
  }

  SessionExercisesCompanion toCompanion(bool nullToAbsent) {
    return SessionExercisesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      position: Value(position),
    );
  }

  factory SessionExerciseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionExerciseRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'sessionId': serializer.toJson<String>(sessionId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
    };
  }

  SessionExerciseRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? sessionId,
    String? exerciseId,
    int? position,
  }) => SessionExerciseRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
  );
  SessionExerciseRow copyWithCompanion(SessionExercisesCompanion data) {
    return SessionExerciseRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionExerciseRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    sessionId,
    exerciseId,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionExerciseRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position);
}

class SessionExercisesCompanion extends UpdateCompanion<SessionExerciseRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> sessionId;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<int> rowid;
  const SessionExercisesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionExercisesCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String sessionId,
    required String exerciseId,
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       sessionId = Value(sessionId),
       exerciseId = Value(exerciseId),
       position = Value(position);
  static Insertable<SessionExerciseRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? sessionId,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionExercisesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? sessionId,
    Value<String>? exerciseId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return SessionExercisesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercisesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetsTable extends WorkoutSets
    with TableInfo<$WorkoutSetsTable, WorkoutSetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sessionExerciseIdMeta = const VerificationMeta(
    'sessionExerciseId',
  );
  @override
  late final GeneratedColumn<String> sessionExerciseId =
      GeneratedColumn<String>(
        'session_exercise_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    check: () => ComparableExpr(position).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    check: () => ComparableExpr(reps).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kgMeta = const VerificationMeta('kg');
  @override
  late final GeneratedColumn<double> kg = GeneratedColumn<double>(
    'kg',
    aliasedName,
    true,
    check: () => ComparableExpr(kg).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputValueMeta = const VerificationMeta(
    'inputValue',
  );
  @override
  late final GeneratedColumn<double> inputValue = GeneratedColumn<double>(
    'input_value',
    aliasedName,
    true,
    check: () => ComparableExpr(inputValue).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputUnitMeta = const VerificationMeta(
    'inputUnit',
  );
  @override
  late final GeneratedColumn<String> inputUnit = GeneratedColumn<String>(
    'input_unit',
    aliasedName,
    true,
    check: () => inputUnit.isIn(const ['kg', 'lb']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    check: () => ComparableExpr(durationSeconds).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    true,
    check: () => ComparableExpr(distanceMeters).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    sessionExerciseId,
    position,
    reps,
    kg,
    inputValue,
    inputUnit,
    durationSeconds,
    distanceMeters,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('session_exercise_id')) {
      context.handle(
        _sessionExerciseIdMeta,
        sessionExerciseId.isAcceptableOrUnknown(
          data['session_exercise_id']!,
          _sessionExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionExerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('kg')) {
      context.handle(_kgMeta, kg.isAcceptableOrUnknown(data['kg']!, _kgMeta));
    }
    if (data.containsKey('input_value')) {
      context.handle(
        _inputValueMeta,
        inputValue.isAcceptableOrUnknown(data['input_value']!, _inputValueMeta),
      );
    }
    if (data.containsKey('input_unit')) {
      context.handle(
        _inputUnitMeta,
        inputUnit.isAcceptableOrUnknown(data['input_unit']!, _inputUnitMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      sessionExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      kg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kg'],
      ),
      inputValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}input_value'],
      ),
      inputUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_unit'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      ),
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }
}

class WorkoutSetRow extends DataClass implements Insertable<WorkoutSetRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The session exercise.
  final String sessionExerciseId;

  /// Order within the exercise, from 0.
  final int position;

  /// Reps.
  final int? reps;

  /// Load in kg.
  final double? kg;

  /// The weight as typed, in [inputUnit] (A36 D1, TD-017).
  final double? inputValue;

  /// The unit the weight was typed in: `kg` or `lb` (A36 D1).
  final String? inputUnit;

  /// Duration in seconds.
  final int? durationSeconds;

  /// Distance in metres.
  final double? distanceMeters;
  const WorkoutSetRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.sessionExerciseId,
    required this.position,
    this.reps,
    this.kg,
    this.inputValue,
    this.inputUnit,
    this.durationSeconds,
    this.distanceMeters,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['session_exercise_id'] = Variable<String>(sessionExerciseId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || kg != null) {
      map['kg'] = Variable<double>(kg);
    }
    if (!nullToAbsent || inputValue != null) {
      map['input_value'] = Variable<double>(inputValue);
    }
    if (!nullToAbsent || inputUnit != null) {
      map['input_unit'] = Variable<String>(inputUnit);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || distanceMeters != null) {
      map['distance_meters'] = Variable<double>(distanceMeters);
    }
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      sessionExerciseId: Value(sessionExerciseId),
      position: Value(position),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      kg: kg == null && nullToAbsent ? const Value.absent() : Value(kg),
      inputValue: inputValue == null && nullToAbsent
          ? const Value.absent()
          : Value(inputValue),
      inputUnit: inputUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(inputUnit),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      distanceMeters: distanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceMeters),
    );
  }

  factory WorkoutSetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSetRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      sessionExerciseId: serializer.fromJson<String>(json['sessionExerciseId']),
      position: serializer.fromJson<int>(json['position']),
      reps: serializer.fromJson<int?>(json['reps']),
      kg: serializer.fromJson<double?>(json['kg']),
      inputValue: serializer.fromJson<double?>(json['inputValue']),
      inputUnit: serializer.fromJson<String?>(json['inputUnit']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      distanceMeters: serializer.fromJson<double?>(json['distanceMeters']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'sessionExerciseId': serializer.toJson<String>(sessionExerciseId),
      'position': serializer.toJson<int>(position),
      'reps': serializer.toJson<int?>(reps),
      'kg': serializer.toJson<double?>(kg),
      'inputValue': serializer.toJson<double?>(inputValue),
      'inputUnit': serializer.toJson<String?>(inputUnit),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'distanceMeters': serializer.toJson<double?>(distanceMeters),
    };
  }

  WorkoutSetRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? sessionExerciseId,
    int? position,
    Value<int?> reps = const Value.absent(),
    Value<double?> kg = const Value.absent(),
    Value<double?> inputValue = const Value.absent(),
    Value<String?> inputUnit = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<double?> distanceMeters = const Value.absent(),
  }) => WorkoutSetRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
    position: position ?? this.position,
    reps: reps.present ? reps.value : this.reps,
    kg: kg.present ? kg.value : this.kg,
    inputValue: inputValue.present ? inputValue.value : this.inputValue,
    inputUnit: inputUnit.present ? inputUnit.value : this.inputUnit,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    distanceMeters: distanceMeters.present
        ? distanceMeters.value
        : this.distanceMeters,
  );
  WorkoutSetRow copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSetRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      sessionExerciseId: data.sessionExerciseId.present
          ? data.sessionExerciseId.value
          : this.sessionExerciseId,
      position: data.position.present ? data.position.value : this.position,
      reps: data.reps.present ? data.reps.value : this.reps,
      kg: data.kg.present ? data.kg.value : this.kg,
      inputValue: data.inputValue.present
          ? data.inputValue.value
          : this.inputValue,
      inputUnit: data.inputUnit.present ? data.inputUnit.value : this.inputUnit,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('position: $position, ')
          ..write('reps: $reps, ')
          ..write('kg: $kg, ')
          ..write('inputValue: $inputValue, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    sessionExerciseId,
    position,
    reps,
    kg,
    inputValue,
    inputUnit,
    durationSeconds,
    distanceMeters,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSetRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.sessionExerciseId == this.sessionExerciseId &&
          other.position == this.position &&
          other.reps == this.reps &&
          other.kg == this.kg &&
          other.inputValue == this.inputValue &&
          other.inputUnit == this.inputUnit &&
          other.durationSeconds == this.durationSeconds &&
          other.distanceMeters == this.distanceMeters);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSetRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> sessionExerciseId;
  final Value<int> position;
  final Value<int?> reps;
  final Value<double?> kg;
  final Value<double?> inputValue;
  final Value<String?> inputUnit;
  final Value<int?> durationSeconds;
  final Value<double?> distanceMeters;
  final Value<int> rowid;
  const WorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.sessionExerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.reps = const Value.absent(),
    this.kg = const Value.absent(),
    this.inputValue = const Value.absent(),
    this.inputUnit = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String sessionExerciseId,
    required int position,
    this.reps = const Value.absent(),
    this.kg = const Value.absent(),
    this.inputValue = const Value.absent(),
    this.inputUnit = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       sessionExerciseId = Value(sessionExerciseId),
       position = Value(position);
  static Insertable<WorkoutSetRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? sessionExerciseId,
    Expression<int>? position,
    Expression<int>? reps,
    Expression<double>? kg,
    Expression<double>? inputValue,
    Expression<String>? inputUnit,
    Expression<int>? durationSeconds,
    Expression<double>? distanceMeters,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (sessionExerciseId != null) 'session_exercise_id': sessionExerciseId,
      if (position != null) 'position': position,
      if (reps != null) 'reps': reps,
      if (kg != null) 'kg': kg,
      if (inputValue != null) 'input_value': inputValue,
      if (inputUnit != null) 'input_unit': inputUnit,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSetsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? sessionExerciseId,
    Value<int>? position,
    Value<int?>? reps,
    Value<double?>? kg,
    Value<double?>? inputValue,
    Value<String?>? inputUnit,
    Value<int?>? durationSeconds,
    Value<double?>? distanceMeters,
    Value<int>? rowid,
  }) {
    return WorkoutSetsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      position: position ?? this.position,
      reps: reps ?? this.reps,
      kg: kg ?? this.kg,
      inputValue: inputValue ?? this.inputValue,
      inputUnit: inputUnit ?? this.inputUnit,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (sessionExerciseId.present) {
      map['session_exercise_id'] = Variable<String>(sessionExerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (kg.present) {
      map['kg'] = Variable<double>(kg.value);
    }
    if (inputValue.present) {
      map['input_value'] = Variable<double>(inputValue.value);
    }
    if (inputUnit.present) {
      map['input_unit'] = Variable<String>(inputUnit.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('position: $position, ')
          ..write('reps: $reps, ')
          ..write('kg: $kg, ')
          ..write('inputValue: $inputValue, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplateItemsTable extends WorkoutTemplateItems
    with TableInfo<$WorkoutTemplateItemsTable, WorkoutTemplateItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplateItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    check: () => ComparableExpr(position).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSetsMeta = const VerificationMeta(
    'targetSets',
  );
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    false,
    check: () => ComparableExpr(targetSets).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
    'target_reps',
    aliasedName,
    false,
    check: () => ComparableExpr(targetReps).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    templateId,
    exerciseId,
    position,
    targetSets,
    targetReps,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_template_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplateItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('target_sets')) {
      context.handle(
        _targetSetsMeta,
        targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetSetsMeta);
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    } else if (isInserting) {
      context.missing(_targetRepsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplateItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplateItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      targetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets'],
      )!,
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps'],
      )!,
    );
  }

  @override
  $WorkoutTemplateItemsTable createAlias(String alias) {
    return $WorkoutTemplateItemsTable(attachedDatabase, alias);
  }
}

class WorkoutTemplateItemRow extends DataClass
    implements Insertable<WorkoutTemplateItemRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The template.
  final String templateId;

  /// The exercise.
  final String exerciseId;

  /// Order within the template, from 0.
  final int position;

  /// Target sets.
  final int targetSets;

  /// Target reps.
  final int targetReps;
  const WorkoutTemplateItemRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.templateId,
    required this.exerciseId,
    required this.position,
    required this.targetSets,
    required this.targetReps,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['template_id'] = Variable<String>(templateId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    map['target_sets'] = Variable<int>(targetSets);
    map['target_reps'] = Variable<int>(targetReps);
    return map;
  }

  WorkoutTemplateItemsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplateItemsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      templateId: Value(templateId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      targetSets: Value(targetSets),
      targetReps: Value(targetReps),
    );
  }

  factory WorkoutTemplateItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplateItemRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      templateId: serializer.fromJson<String>(json['templateId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      targetSets: serializer.fromJson<int>(json['targetSets']),
      targetReps: serializer.fromJson<int>(json['targetReps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'templateId': serializer.toJson<String>(templateId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
      'targetSets': serializer.toJson<int>(targetSets),
      'targetReps': serializer.toJson<int>(targetReps),
    };
  }

  WorkoutTemplateItemRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? templateId,
    String? exerciseId,
    int? position,
    int? targetSets,
    int? targetReps,
  }) => WorkoutTemplateItemRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    templateId: templateId ?? this.templateId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    targetSets: targetSets ?? this.targetSets,
    targetReps: targetReps ?? this.targetReps,
  );
  WorkoutTemplateItemRow copyWithCompanion(WorkoutTemplateItemsCompanion data) {
    return WorkoutTemplateItemRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      targetSets: data.targetSets.present
          ? data.targetSets.value
          : this.targetSets,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplateItemRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('templateId: $templateId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    templateId,
    exerciseId,
    position,
    targetSets,
    targetReps,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplateItemRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.templateId == this.templateId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.targetSets == this.targetSets &&
          other.targetReps == this.targetReps);
}

class WorkoutTemplateItemsCompanion
    extends UpdateCompanion<WorkoutTemplateItemRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> templateId;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<int> targetSets;
  final Value<int> targetReps;
  final Value<int> rowid;
  const WorkoutTemplateItemsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.templateId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutTemplateItemsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String templateId,
    required String exerciseId,
    required int position,
    required int targetSets,
    required int targetReps,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       templateId = Value(templateId),
       exerciseId = Value(exerciseId),
       position = Value(position),
       targetSets = Value(targetSets),
       targetReps = Value(targetReps);
  static Insertable<WorkoutTemplateItemRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? templateId,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<int>? targetSets,
    Expression<int>? targetReps,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (templateId != null) 'template_id': templateId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutTemplateItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? templateId,
    Value<String>? exerciseId,
    Value<int>? position,
    Value<int>? targetSets,
    Value<int>? targetReps,
    Value<int>? rowid,
  }) {
    return WorkoutTemplateItemsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      templateId: templateId ?? this.templateId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplateItemsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('templateId: $templateId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeeklyPlanDaysTable extends WeeklyPlanDays
    with TableInfo<$WeeklyPlanDaysTable, WeeklyPlanDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyPlanDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    check: () => ComparableExpr(weekday).isBetweenValues(1, 7),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    weekday,
    templateId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_plan_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyPlanDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklyPlanDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyPlanDayRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
    );
  }

  @override
  $WeeklyPlanDaysTable createAlias(String alias) {
    return $WeeklyPlanDaysTable(attachedDatabase, alias);
  }
}

class WeeklyPlanDayRow extends DataClass
    implements Insertable<WeeklyPlanDayRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// ISO weekday, 1 (Monday) to 7.
  final int weekday;

  /// The template, or null for rest.
  final String? templateId;
  const WeeklyPlanDayRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.weekday,
    this.templateId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['weekday'] = Variable<int>(weekday);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    return map;
  }

  WeeklyPlanDaysCompanion toCompanion(bool nullToAbsent) {
    return WeeklyPlanDaysCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      weekday: Value(weekday),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
    );
  }

  factory WeeklyPlanDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyPlanDayRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      weekday: serializer.fromJson<int>(json['weekday']),
      templateId: serializer.fromJson<String?>(json['templateId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'weekday': serializer.toJson<int>(weekday),
      'templateId': serializer.toJson<String?>(templateId),
    };
  }

  WeeklyPlanDayRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    int? weekday,
    Value<String?> templateId = const Value.absent(),
  }) => WeeklyPlanDayRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    weekday: weekday ?? this.weekday,
    templateId: templateId.present ? templateId.value : this.templateId,
  );
  WeeklyPlanDayRow copyWithCompanion(WeeklyPlanDaysCompanion data) {
    return WeeklyPlanDayRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyPlanDayRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('weekday: $weekday, ')
          ..write('templateId: $templateId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    weekday,
    templateId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyPlanDayRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.weekday == this.weekday &&
          other.templateId == this.templateId);
}

class WeeklyPlanDaysCompanion extends UpdateCompanion<WeeklyPlanDayRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<int> weekday;
  final Value<String?> templateId;
  final Value<int> rowid;
  const WeeklyPlanDaysCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.weekday = const Value.absent(),
    this.templateId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeeklyPlanDaysCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required int weekday,
    this.templateId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       weekday = Value(weekday);
  static Insertable<WeeklyPlanDayRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<int>? weekday,
    Expression<String>? templateId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (weekday != null) 'weekday': weekday,
      if (templateId != null) 'template_id': templateId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeeklyPlanDaysCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<int>? weekday,
    Value<String?>? templateId,
    Value<int>? rowid,
  }) {
    return WeeklyPlanDaysCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      weekday: weekday ?? this.weekday,
      templateId: templateId ?? this.templateId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyPlanDaysCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('weekday: $weekday, ')
          ..write('templateId: $templateId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomExercisesTable extends CustomExercises
    with TableInfo<$CustomExercisesTable, CustomExerciseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasesJsonMeta = const VerificationMeta(
    'aliasesJson',
  );
  @override
  late final GeneratedColumn<String> aliasesJson = GeneratedColumn<String>(
    'aliases_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _exerciseTypeMeta = const VerificationMeta(
    'exerciseType',
  );
  @override
  late final GeneratedColumn<String> exerciseType = GeneratedColumn<String>(
    'exercise_type',
    aliasedName,
    false,
    check: () => exerciseType.isIn(const [
      'weight_reps',
      'bodyweight_reps',
      'assisted',
      'reps_only',
      'duration',
      'distance_duration',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    check: () => equipment.isIn(const [
      'barbell',
      'dumbbell',
      'cable',
      'machine',
      'kettlebell',
      'bodyweight',
      'other',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primaryMuscleMeta = const VerificationMeta(
    'primaryMuscle',
  );
  @override
  late final GeneratedColumn<String> primaryMuscle = GeneratedColumn<String>(
    'primary_muscle',
    aliasedName,
    true,
    check: () => primaryMuscle.isIn(const [
      'chest',
      'shoulders',
      'biceps',
      'triceps',
      'forearms',
      'traps',
      'upper_back',
      'lower_back',
      'abs',
      'obliques',
      'quadriceps',
      'hamstrings',
      'glutes',
      'calves',
      'adductors',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secondaryMusclesJsonMeta =
      const VerificationMeta('secondaryMusclesJson');
  @override
  late final GeneratedColumn<String> secondaryMusclesJson =
      GeneratedColumn<String>(
        'secondary_muscles_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    name,
    aliasesJson,
    exerciseType,
    equipment,
    primaryMuscle,
    secondaryMusclesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomExerciseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('aliases_json')) {
      context.handle(
        _aliasesJsonMeta,
        aliasesJson.isAcceptableOrUnknown(
          data['aliases_json']!,
          _aliasesJsonMeta,
        ),
      );
    }
    if (data.containsKey('exercise_type')) {
      context.handle(
        _exerciseTypeMeta,
        exerciseType.isAcceptableOrUnknown(
          data['exercise_type']!,
          _exerciseTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseTypeMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    } else if (isInserting) {
      context.missing(_equipmentMeta);
    }
    if (data.containsKey('primary_muscle')) {
      context.handle(
        _primaryMuscleMeta,
        primaryMuscle.isAcceptableOrUnknown(
          data['primary_muscle']!,
          _primaryMuscleMeta,
        ),
      );
    }
    if (data.containsKey('secondary_muscles_json')) {
      context.handle(
        _secondaryMusclesJsonMeta,
        secondaryMusclesJson.isAcceptableOrUnknown(
          data['secondary_muscles_json']!,
          _secondaryMusclesJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomExerciseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomExerciseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      aliasesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases_json'],
      )!,
      exerciseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_type'],
      )!,
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      primaryMuscle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_muscle'],
      ),
      secondaryMusclesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_muscles_json'],
      )!,
    );
  }

  @override
  $CustomExercisesTable createAlias(String alias) {
    return $CustomExercisesTable(attachedDatabase, alias);
  }
}

class CustomExerciseRow extends DataClass
    implements Insertable<CustomExerciseRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The display name. User content.
  final String name;

  /// Search aliases, a JSON array of strings. User content.
  final String aliasesJson;

  /// The WO-004 type code.
  final String exerciseType;

  /// The equipment code (WO-002, WO-005).
  final String equipment;

  /// The main muscle code (WO-007, A37 D2, D6), or null: rows from before
  /// v11, or synced without one.
  final String? primaryMuscle;

  /// Secondary muscle codes, a JSON array (at most 4, never the primary).
  final String secondaryMusclesJson;
  const CustomExerciseRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.name,
    required this.aliasesJson,
    required this.exerciseType,
    required this.equipment,
    this.primaryMuscle,
    required this.secondaryMusclesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['name'] = Variable<String>(name);
    map['aliases_json'] = Variable<String>(aliasesJson);
    map['exercise_type'] = Variable<String>(exerciseType);
    map['equipment'] = Variable<String>(equipment);
    if (!nullToAbsent || primaryMuscle != null) {
      map['primary_muscle'] = Variable<String>(primaryMuscle);
    }
    map['secondary_muscles_json'] = Variable<String>(secondaryMusclesJson);
    return map;
  }

  CustomExercisesCompanion toCompanion(bool nullToAbsent) {
    return CustomExercisesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      name: Value(name),
      aliasesJson: Value(aliasesJson),
      exerciseType: Value(exerciseType),
      equipment: Value(equipment),
      primaryMuscle: primaryMuscle == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryMuscle),
      secondaryMusclesJson: Value(secondaryMusclesJson),
    );
  }

  factory CustomExerciseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomExerciseRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      name: serializer.fromJson<String>(json['name']),
      aliasesJson: serializer.fromJson<String>(json['aliasesJson']),
      exerciseType: serializer.fromJson<String>(json['exerciseType']),
      equipment: serializer.fromJson<String>(json['equipment']),
      primaryMuscle: serializer.fromJson<String?>(json['primaryMuscle']),
      secondaryMusclesJson: serializer.fromJson<String>(
        json['secondaryMusclesJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'name': serializer.toJson<String>(name),
      'aliasesJson': serializer.toJson<String>(aliasesJson),
      'exerciseType': serializer.toJson<String>(exerciseType),
      'equipment': serializer.toJson<String>(equipment),
      'primaryMuscle': serializer.toJson<String?>(primaryMuscle),
      'secondaryMusclesJson': serializer.toJson<String>(secondaryMusclesJson),
    };
  }

  CustomExerciseRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? name,
    String? aliasesJson,
    String? exerciseType,
    String? equipment,
    Value<String?> primaryMuscle = const Value.absent(),
    String? secondaryMusclesJson,
  }) => CustomExerciseRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    name: name ?? this.name,
    aliasesJson: aliasesJson ?? this.aliasesJson,
    exerciseType: exerciseType ?? this.exerciseType,
    equipment: equipment ?? this.equipment,
    primaryMuscle: primaryMuscle.present
        ? primaryMuscle.value
        : this.primaryMuscle,
    secondaryMusclesJson: secondaryMusclesJson ?? this.secondaryMusclesJson,
  );
  CustomExerciseRow copyWithCompanion(CustomExercisesCompanion data) {
    return CustomExerciseRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      name: data.name.present ? data.name.value : this.name,
      aliasesJson: data.aliasesJson.present
          ? data.aliasesJson.value
          : this.aliasesJson,
      exerciseType: data.exerciseType.present
          ? data.exerciseType.value
          : this.exerciseType,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      primaryMuscle: data.primaryMuscle.present
          ? data.primaryMuscle.value
          : this.primaryMuscle,
      secondaryMusclesJson: data.secondaryMusclesJson.present
          ? data.secondaryMusclesJson.value
          : this.secondaryMusclesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomExerciseRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('name: $name, ')
          ..write('aliasesJson: $aliasesJson, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('equipment: $equipment, ')
          ..write('primaryMuscle: $primaryMuscle, ')
          ..write('secondaryMusclesJson: $secondaryMusclesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    name,
    aliasesJson,
    exerciseType,
    equipment,
    primaryMuscle,
    secondaryMusclesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomExerciseRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.name == this.name &&
          other.aliasesJson == this.aliasesJson &&
          other.exerciseType == this.exerciseType &&
          other.equipment == this.equipment &&
          other.primaryMuscle == this.primaryMuscle &&
          other.secondaryMusclesJson == this.secondaryMusclesJson);
}

class CustomExercisesCompanion extends UpdateCompanion<CustomExerciseRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> name;
  final Value<String> aliasesJson;
  final Value<String> exerciseType;
  final Value<String> equipment;
  final Value<String?> primaryMuscle;
  final Value<String> secondaryMusclesJson;
  final Value<int> rowid;
  const CustomExercisesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.name = const Value.absent(),
    this.aliasesJson = const Value.absent(),
    this.exerciseType = const Value.absent(),
    this.equipment = const Value.absent(),
    this.primaryMuscle = const Value.absent(),
    this.secondaryMusclesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomExercisesCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String name,
    this.aliasesJson = const Value.absent(),
    required String exerciseType,
    required String equipment,
    this.primaryMuscle = const Value.absent(),
    this.secondaryMusclesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       name = Value(name),
       exerciseType = Value(exerciseType),
       equipment = Value(equipment);
  static Insertable<CustomExerciseRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? name,
    Expression<String>? aliasesJson,
    Expression<String>? exerciseType,
    Expression<String>? equipment,
    Expression<String>? primaryMuscle,
    Expression<String>? secondaryMusclesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (name != null) 'name': name,
      if (aliasesJson != null) 'aliases_json': aliasesJson,
      if (exerciseType != null) 'exercise_type': exerciseType,
      if (equipment != null) 'equipment': equipment,
      if (primaryMuscle != null) 'primary_muscle': primaryMuscle,
      if (secondaryMusclesJson != null)
        'secondary_muscles_json': secondaryMusclesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomExercisesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? name,
    Value<String>? aliasesJson,
    Value<String>? exerciseType,
    Value<String>? equipment,
    Value<String?>? primaryMuscle,
    Value<String>? secondaryMusclesJson,
    Value<int>? rowid,
  }) {
    return CustomExercisesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      name: name ?? this.name,
      aliasesJson: aliasesJson ?? this.aliasesJson,
      exerciseType: exerciseType ?? this.exerciseType,
      equipment: equipment ?? this.equipment,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMusclesJson: secondaryMusclesJson ?? this.secondaryMusclesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (aliasesJson.present) {
      map['aliases_json'] = Variable<String>(aliasesJson.value);
    }
    if (exerciseType.present) {
      map['exercise_type'] = Variable<String>(exerciseType.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (primaryMuscle.present) {
      map['primary_muscle'] = Variable<String>(primaryMuscle.value);
    }
    if (secondaryMusclesJson.present) {
      map['secondary_muscles_json'] = Variable<String>(
        secondaryMusclesJson.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomExercisesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('name: $name, ')
          ..write('aliasesJson: $aliasesJson, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('equipment: $equipment, ')
          ..write('primaryMuscle: $primaryMuscle, ')
          ..write('secondaryMusclesJson: $secondaryMusclesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplatesTable extends WorkoutTemplates
    with TableInfo<$WorkoutTemplatesTable, WorkoutTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $WorkoutTemplatesTable createAlias(String alias) {
    return $WorkoutTemplatesTable(attachedDatabase, alias);
  }
}

class WorkoutTemplateRow extends DataClass
    implements Insertable<WorkoutTemplateRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// "Push". User content.
  final String name;
  const WorkoutTemplateRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['name'] = Variable<String>(name);
    return map;
  }

  WorkoutTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      name: Value(name),
    );
  }

  factory WorkoutTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'name': serializer.toJson<String>(name),
    };
  }

  WorkoutTemplateRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? name,
  }) => WorkoutTemplateRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    name: name ?? this.name,
  );
  WorkoutTemplateRow copyWithCompanion(WorkoutTemplatesCompanion data) {
    return WorkoutTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplateRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    name,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplateRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.name == this.name);
}

class WorkoutTemplatesCompanion extends UpdateCompanion<WorkoutTemplateRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> name;
  final Value<int> rowid;
  const WorkoutTemplatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutTemplatesCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       name = Value(name);
  static Insertable<WorkoutTemplateRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutTemplatesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return WorkoutTemplatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    check: () => role.isIn(const ['user', 'assistant']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageTextMeta = const VerificationMeta(
    'messageText',
  );
  @override
  late final GeneratedColumn<String> messageText = GeneratedColumn<String>(
    'message_text',
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
    check: () => status.isIn(const [
      'queued',
      'pending_offline',
      'processing',
      'done',
      'failed',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyToMessageIdMeta = const VerificationMeta(
    'replyToMessageId',
  );
  @override
  late final GeneratedColumn<String> replyToMessageId = GeneratedColumn<String>(
    'reply_to_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codecVersionMeta = const VerificationMeta(
    'codecVersion',
  );
  @override
  late final GeneratedColumn<int> codecVersion = GeneratedColumn<int>(
    'codec_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _budgetJsonMeta = const VerificationMeta(
    'budgetJson',
  );
  @override
  late final GeneratedColumn<String> budgetJson = GeneratedColumn<String>(
    'budget_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requestJsonMeta = const VerificationMeta(
    'requestJson',
  );
  @override
  late final GeneratedColumn<String> requestJson = GeneratedColumn<String>(
    'request_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerJsonMeta = const VerificationMeta(
    'answerJson',
  );
  @override
  late final GeneratedColumn<String> answerJson = GeneratedColumn<String>(
    'answer_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    role,
    messageText,
    status,
    language,
    replyToMessageId,
    codecVersion,
    budgetJson,
    requestJson,
    answerJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('message_text')) {
      context.handle(
        _messageTextMeta,
        messageText.isAcceptableOrUnknown(
          data['message_text']!,
          _messageTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageTextMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('reply_to_message_id')) {
      context.handle(
        _replyToMessageIdMeta,
        replyToMessageId.isAcceptableOrUnknown(
          data['reply_to_message_id']!,
          _replyToMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('codec_version')) {
      context.handle(
        _codecVersionMeta,
        codecVersion.isAcceptableOrUnknown(
          data['codec_version']!,
          _codecVersionMeta,
        ),
      );
    }
    if (data.containsKey('budget_json')) {
      context.handle(
        _budgetJsonMeta,
        budgetJson.isAcceptableOrUnknown(data['budget_json']!, _budgetJsonMeta),
      );
    }
    if (data.containsKey('request_json')) {
      context.handle(
        _requestJsonMeta,
        requestJson.isAcceptableOrUnknown(
          data['request_json']!,
          _requestJsonMeta,
        ),
      );
    }
    if (data.containsKey('answer_json')) {
      context.handle(
        _answerJsonMeta,
        answerJson.isAcceptableOrUnknown(data['answer_json']!, _answerJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      messageText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_text'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      replyToMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_message_id'],
      ),
      codecVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}codec_version'],
      ),
      budgetJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}budget_json'],
      ),
      requestJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_json'],
      ),
      answerJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_json'],
      ),
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessageRow extends DataClass implements Insertable<ChatMessageRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// `user` or `assistant`.
  final String role;

  /// The message text (`chatMessage.text`; a column named `text` would
  /// shadow drift's `text()`). User content: never logged.
  final String messageText;

  /// `queued`, `pending_offline`, `processing`, `done` or `failed`.
  final String status;

  /// A short language tag (`en`, `ar`, `ar-Latn`) or `null`.
  final String? language;

  /// The user message an assistant row answers.
  final String? replyToMessageId;

  /// Version of [budgetJson]'s engine format.
  final int? codecVersion;

  /// The shared question budget, on the assistant row only. Bounded JSON.
  final String? budgetJson;

  /// Local-only (TD-102, A23 D4): the frozen interpret request of a user row
  /// while it waits (A23b), nulled at a terminal status. Never synced or
  /// logged; exported as the user's own data.
  final String? requestJson;

  /// Local-only (TD-102, A23 D14): the raw interpret answer of an assistant
  /// row, so a stale restored card rebuilds offline; nulled once no card of
  /// the message is pending. Never synced or logged; exported.
  final String? answerJson;
  const ChatMessageRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.role,
    required this.messageText,
    required this.status,
    this.language,
    this.replyToMessageId,
    this.codecVersion,
    this.budgetJson,
    this.requestJson,
    this.answerJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['role'] = Variable<String>(role);
    map['message_text'] = Variable<String>(messageText);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    if (!nullToAbsent || replyToMessageId != null) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId);
    }
    if (!nullToAbsent || codecVersion != null) {
      map['codec_version'] = Variable<int>(codecVersion);
    }
    if (!nullToAbsent || budgetJson != null) {
      map['budget_json'] = Variable<String>(budgetJson);
    }
    if (!nullToAbsent || requestJson != null) {
      map['request_json'] = Variable<String>(requestJson);
    }
    if (!nullToAbsent || answerJson != null) {
      map['answer_json'] = Variable<String>(answerJson);
    }
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      role: Value(role),
      messageText: Value(messageText),
      status: Value(status),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      replyToMessageId: replyToMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToMessageId),
      codecVersion: codecVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(codecVersion),
      budgetJson: budgetJson == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetJson),
      requestJson: requestJson == null && nullToAbsent
          ? const Value.absent()
          : Value(requestJson),
      answerJson: answerJson == null && nullToAbsent
          ? const Value.absent()
          : Value(answerJson),
    );
  }

  factory ChatMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      role: serializer.fromJson<String>(json['role']),
      messageText: serializer.fromJson<String>(json['messageText']),
      status: serializer.fromJson<String>(json['status']),
      language: serializer.fromJson<String?>(json['language']),
      replyToMessageId: serializer.fromJson<String?>(json['replyToMessageId']),
      codecVersion: serializer.fromJson<int?>(json['codecVersion']),
      budgetJson: serializer.fromJson<String?>(json['budgetJson']),
      requestJson: serializer.fromJson<String?>(json['requestJson']),
      answerJson: serializer.fromJson<String?>(json['answerJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'role': serializer.toJson<String>(role),
      'messageText': serializer.toJson<String>(messageText),
      'status': serializer.toJson<String>(status),
      'language': serializer.toJson<String?>(language),
      'replyToMessageId': serializer.toJson<String?>(replyToMessageId),
      'codecVersion': serializer.toJson<int?>(codecVersion),
      'budgetJson': serializer.toJson<String?>(budgetJson),
      'requestJson': serializer.toJson<String?>(requestJson),
      'answerJson': serializer.toJson<String?>(answerJson),
    };
  }

  ChatMessageRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? role,
    String? messageText,
    String? status,
    Value<String?> language = const Value.absent(),
    Value<String?> replyToMessageId = const Value.absent(),
    Value<int?> codecVersion = const Value.absent(),
    Value<String?> budgetJson = const Value.absent(),
    Value<String?> requestJson = const Value.absent(),
    Value<String?> answerJson = const Value.absent(),
  }) => ChatMessageRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    role: role ?? this.role,
    messageText: messageText ?? this.messageText,
    status: status ?? this.status,
    language: language.present ? language.value : this.language,
    replyToMessageId: replyToMessageId.present
        ? replyToMessageId.value
        : this.replyToMessageId,
    codecVersion: codecVersion.present ? codecVersion.value : this.codecVersion,
    budgetJson: budgetJson.present ? budgetJson.value : this.budgetJson,
    requestJson: requestJson.present ? requestJson.value : this.requestJson,
    answerJson: answerJson.present ? answerJson.value : this.answerJson,
  );
  ChatMessageRow copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessageRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      role: data.role.present ? data.role.value : this.role,
      messageText: data.messageText.present
          ? data.messageText.value
          : this.messageText,
      status: data.status.present ? data.status.value : this.status,
      language: data.language.present ? data.language.value : this.language,
      replyToMessageId: data.replyToMessageId.present
          ? data.replyToMessageId.value
          : this.replyToMessageId,
      codecVersion: data.codecVersion.present
          ? data.codecVersion.value
          : this.codecVersion,
      budgetJson: data.budgetJson.present
          ? data.budgetJson.value
          : this.budgetJson,
      requestJson: data.requestJson.present
          ? data.requestJson.value
          : this.requestJson,
      answerJson: data.answerJson.present
          ? data.answerJson.value
          : this.answerJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('role: $role, ')
          ..write('messageText: $messageText, ')
          ..write('status: $status, ')
          ..write('language: $language, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('codecVersion: $codecVersion, ')
          ..write('budgetJson: $budgetJson, ')
          ..write('requestJson: $requestJson, ')
          ..write('answerJson: $answerJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    role,
    messageText,
    status,
    language,
    replyToMessageId,
    codecVersion,
    budgetJson,
    requestJson,
    answerJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.role == this.role &&
          other.messageText == this.messageText &&
          other.status == this.status &&
          other.language == this.language &&
          other.replyToMessageId == this.replyToMessageId &&
          other.codecVersion == this.codecVersion &&
          other.budgetJson == this.budgetJson &&
          other.requestJson == this.requestJson &&
          other.answerJson == this.answerJson);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessageRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> role;
  final Value<String> messageText;
  final Value<String> status;
  final Value<String?> language;
  final Value<String?> replyToMessageId;
  final Value<int?> codecVersion;
  final Value<String?> budgetJson;
  final Value<String?> requestJson;
  final Value<String?> answerJson;
  final Value<int> rowid;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.role = const Value.absent(),
    this.messageText = const Value.absent(),
    this.status = const Value.absent(),
    this.language = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.codecVersion = const Value.absent(),
    this.budgetJson = const Value.absent(),
    this.requestJson = const Value.absent(),
    this.answerJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String role,
    required String messageText,
    required String status,
    this.language = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.codecVersion = const Value.absent(),
    this.budgetJson = const Value.absent(),
    this.requestJson = const Value.absent(),
    this.answerJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       role = Value(role),
       messageText = Value(messageText),
       status = Value(status);
  static Insertable<ChatMessageRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? role,
    Expression<String>? messageText,
    Expression<String>? status,
    Expression<String>? language,
    Expression<String>? replyToMessageId,
    Expression<int>? codecVersion,
    Expression<String>? budgetJson,
    Expression<String>? requestJson,
    Expression<String>? answerJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (role != null) 'role': role,
      if (messageText != null) 'message_text': messageText,
      if (status != null) 'status': status,
      if (language != null) 'language': language,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (codecVersion != null) 'codec_version': codecVersion,
      if (budgetJson != null) 'budget_json': budgetJson,
      if (requestJson != null) 'request_json': requestJson,
      if (answerJson != null) 'answer_json': answerJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? role,
    Value<String>? messageText,
    Value<String>? status,
    Value<String?>? language,
    Value<String?>? replyToMessageId,
    Value<int?>? codecVersion,
    Value<String?>? budgetJson,
    Value<String?>? requestJson,
    Value<String?>? answerJson,
    Value<int>? rowid,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      role: role ?? this.role,
      messageText: messageText ?? this.messageText,
      status: status ?? this.status,
      language: language ?? this.language,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      codecVersion: codecVersion ?? this.codecVersion,
      budgetJson: budgetJson ?? this.budgetJson,
      requestJson: requestJson ?? this.requestJson,
      answerJson: answerJson ?? this.answerJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (messageText.present) {
      map['message_text'] = Variable<String>(messageText.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (replyToMessageId.present) {
      map['reply_to_message_id'] = Variable<String>(replyToMessageId.value);
    }
    if (codecVersion.present) {
      map['codec_version'] = Variable<int>(codecVersion.value);
    }
    if (budgetJson.present) {
      map['budget_json'] = Variable<String>(budgetJson.value);
    }
    if (requestJson.present) {
      map['request_json'] = Variable<String>(requestJson.value);
    }
    if (answerJson.present) {
      map['answer_json'] = Variable<String>(answerJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('role: $role, ')
          ..write('messageText: $messageText, ')
          ..write('status: $status, ')
          ..write('language: $language, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('codecVersion: $codecVersion, ')
          ..write('budgetJson: $budgetJson, ')
          ..write('requestJson: $requestJson, ')
          ..write('answerJson: $answerJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProposalsTable extends Proposals
    with TableInfo<$ProposalsTable, ProposalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProposalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
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
    check: () =>
        status.isIn(const ['pending', 'confirmed', 'discarded', 'superseded']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    true,
    check: () => outcome.isIn(const ['unchanged', 'adjusted', 'discarded']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<int> resolvedAt = GeneratedColumn<int>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originMessageIdMeta = const VerificationMeta(
    'originMessageId',
  );
  @override
  late final GeneratedColumn<String> originMessageId = GeneratedColumn<String>(
    'origin_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _budgetMessageIdMeta = const VerificationMeta(
    'budgetMessageId',
  );
  @override
  late final GeneratedColumn<String> budgetMessageId = GeneratedColumn<String>(
    'budget_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codecVersionMeta = const VerificationMeta(
    'codecVersion',
  );
  @override
  late final GeneratedColumn<int> codecVersion = GeneratedColumn<int>(
    'codec_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interpretationJsonMeta =
      const VerificationMeta('interpretationJson');
  @override
  late final GeneratedColumn<String> interpretationJson =
      GeneratedColumn<String>(
        'interpretation_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _draftJsonMeta = const VerificationMeta(
    'draftJson',
  );
  @override
  late final GeneratedColumn<String> draftJson = GeneratedColumn<String>(
    'draft_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    kind,
    status,
    outcome,
    resolvedAt,
    originMessageId,
    budgetMessageId,
    codecVersion,
    interpretationJson,
    draftJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'proposals';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProposalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('origin_message_id')) {
      context.handle(
        _originMessageIdMeta,
        originMessageId.isAcceptableOrUnknown(
          data['origin_message_id']!,
          _originMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('budget_message_id')) {
      context.handle(
        _budgetMessageIdMeta,
        budgetMessageId.isAcceptableOrUnknown(
          data['budget_message_id']!,
          _budgetMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('codec_version')) {
      context.handle(
        _codecVersionMeta,
        codecVersion.isAcceptableOrUnknown(
          data['codec_version']!,
          _codecVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codecVersionMeta);
    }
    if (data.containsKey('interpretation_json')) {
      context.handle(
        _interpretationJsonMeta,
        interpretationJson.isAcceptableOrUnknown(
          data['interpretation_json']!,
          _interpretationJsonMeta,
        ),
      );
    }
    if (data.containsKey('draft_json')) {
      context.handle(
        _draftJsonMeta,
        draftJson.isAcceptableOrUnknown(data['draft_json']!, _draftJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_draftJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProposalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProposalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      ),
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolved_at'],
      ),
      originMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_message_id'],
      ),
      budgetMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}budget_message_id'],
      ),
      codecVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}codec_version'],
      )!,
      interpretationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interpretation_json'],
      ),
      draftJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_json'],
      )!,
    );
  }

  @override
  $ProposalsTable createAlias(String alias) {
    return $ProposalsTable(attachedDatabase, alias);
  }
}

class ProposalRow extends DataClass implements Insertable<ProposalRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The open kind vocabulary (`foodLog`).
  final String kind;

  /// `pending`, `confirmed`, `discarded` or `superseded`.
  final String status;

  /// `unchanged`, `adjusted`, `discarded`, or `null` while pending.
  final String? outcome;

  /// When it was resolved, UTC ms; `null` while pending.
  final int? resolvedAt;

  /// The creating assistant message; immutable.
  final String? originMessageId;

  /// The assistant message whose budget the card belongs to now.
  final String? budgetMessageId;

  /// Version of the engine JSON format.
  final int codecVersion;

  /// This card's normalized intents.
  final String? interpretationJson;

  /// The compact card draft.
  final String draftJson;
  const ProposalRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.kind,
    required this.status,
    this.outcome,
    this.resolvedAt,
    this.originMessageId,
    this.budgetMessageId,
    required this.codecVersion,
    this.interpretationJson,
    required this.draftJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['kind'] = Variable<String>(kind);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(outcome);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<int>(resolvedAt);
    }
    if (!nullToAbsent || originMessageId != null) {
      map['origin_message_id'] = Variable<String>(originMessageId);
    }
    if (!nullToAbsent || budgetMessageId != null) {
      map['budget_message_id'] = Variable<String>(budgetMessageId);
    }
    map['codec_version'] = Variable<int>(codecVersion);
    if (!nullToAbsent || interpretationJson != null) {
      map['interpretation_json'] = Variable<String>(interpretationJson);
    }
    map['draft_json'] = Variable<String>(draftJson);
    return map;
  }

  ProposalsCompanion toCompanion(bool nullToAbsent) {
    return ProposalsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      kind: Value(kind),
      status: Value(status),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      originMessageId: originMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(originMessageId),
      budgetMessageId: budgetMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetMessageId),
      codecVersion: Value(codecVersion),
      interpretationJson: interpretationJson == null && nullToAbsent
          ? const Value.absent()
          : Value(interpretationJson),
      draftJson: Value(draftJson),
    );
  }

  factory ProposalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProposalRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      kind: serializer.fromJson<String>(json['kind']),
      status: serializer.fromJson<String>(json['status']),
      outcome: serializer.fromJson<String?>(json['outcome']),
      resolvedAt: serializer.fromJson<int?>(json['resolvedAt']),
      originMessageId: serializer.fromJson<String?>(json['originMessageId']),
      budgetMessageId: serializer.fromJson<String?>(json['budgetMessageId']),
      codecVersion: serializer.fromJson<int>(json['codecVersion']),
      interpretationJson: serializer.fromJson<String?>(
        json['interpretationJson'],
      ),
      draftJson: serializer.fromJson<String>(json['draftJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'kind': serializer.toJson<String>(kind),
      'status': serializer.toJson<String>(status),
      'outcome': serializer.toJson<String?>(outcome),
      'resolvedAt': serializer.toJson<int?>(resolvedAt),
      'originMessageId': serializer.toJson<String?>(originMessageId),
      'budgetMessageId': serializer.toJson<String?>(budgetMessageId),
      'codecVersion': serializer.toJson<int>(codecVersion),
      'interpretationJson': serializer.toJson<String?>(interpretationJson),
      'draftJson': serializer.toJson<String>(draftJson),
    };
  }

  ProposalRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? kind,
    String? status,
    Value<String?> outcome = const Value.absent(),
    Value<int?> resolvedAt = const Value.absent(),
    Value<String?> originMessageId = const Value.absent(),
    Value<String?> budgetMessageId = const Value.absent(),
    int? codecVersion,
    Value<String?> interpretationJson = const Value.absent(),
    String? draftJson,
  }) => ProposalRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    kind: kind ?? this.kind,
    status: status ?? this.status,
    outcome: outcome.present ? outcome.value : this.outcome,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    originMessageId: originMessageId.present
        ? originMessageId.value
        : this.originMessageId,
    budgetMessageId: budgetMessageId.present
        ? budgetMessageId.value
        : this.budgetMessageId,
    codecVersion: codecVersion ?? this.codecVersion,
    interpretationJson: interpretationJson.present
        ? interpretationJson.value
        : this.interpretationJson,
    draftJson: draftJson ?? this.draftJson,
  );
  ProposalRow copyWithCompanion(ProposalsCompanion data) {
    return ProposalRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      kind: data.kind.present ? data.kind.value : this.kind,
      status: data.status.present ? data.status.value : this.status,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      originMessageId: data.originMessageId.present
          ? data.originMessageId.value
          : this.originMessageId,
      budgetMessageId: data.budgetMessageId.present
          ? data.budgetMessageId.value
          : this.budgetMessageId,
      codecVersion: data.codecVersion.present
          ? data.codecVersion.value
          : this.codecVersion,
      interpretationJson: data.interpretationJson.present
          ? data.interpretationJson.value
          : this.interpretationJson,
      draftJson: data.draftJson.present ? data.draftJson.value : this.draftJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProposalRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('outcome: $outcome, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('originMessageId: $originMessageId, ')
          ..write('budgetMessageId: $budgetMessageId, ')
          ..write('codecVersion: $codecVersion, ')
          ..write('interpretationJson: $interpretationJson, ')
          ..write('draftJson: $draftJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    kind,
    status,
    outcome,
    resolvedAt,
    originMessageId,
    budgetMessageId,
    codecVersion,
    interpretationJson,
    draftJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProposalRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.kind == this.kind &&
          other.status == this.status &&
          other.outcome == this.outcome &&
          other.resolvedAt == this.resolvedAt &&
          other.originMessageId == this.originMessageId &&
          other.budgetMessageId == this.budgetMessageId &&
          other.codecVersion == this.codecVersion &&
          other.interpretationJson == this.interpretationJson &&
          other.draftJson == this.draftJson);
}

class ProposalsCompanion extends UpdateCompanion<ProposalRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> kind;
  final Value<String> status;
  final Value<String?> outcome;
  final Value<int?> resolvedAt;
  final Value<String?> originMessageId;
  final Value<String?> budgetMessageId;
  final Value<int> codecVersion;
  final Value<String?> interpretationJson;
  final Value<String> draftJson;
  final Value<int> rowid;
  const ProposalsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.outcome = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.originMessageId = const Value.absent(),
    this.budgetMessageId = const Value.absent(),
    this.codecVersion = const Value.absent(),
    this.interpretationJson = const Value.absent(),
    this.draftJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProposalsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String kind,
    required String status,
    this.outcome = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.originMessageId = const Value.absent(),
    this.budgetMessageId = const Value.absent(),
    required int codecVersion,
    this.interpretationJson = const Value.absent(),
    required String draftJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       kind = Value(kind),
       status = Value(status),
       codecVersion = Value(codecVersion),
       draftJson = Value(draftJson);
  static Insertable<ProposalRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? kind,
    Expression<String>? status,
    Expression<String>? outcome,
    Expression<int>? resolvedAt,
    Expression<String>? originMessageId,
    Expression<String>? budgetMessageId,
    Expression<int>? codecVersion,
    Expression<String>? interpretationJson,
    Expression<String>? draftJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (kind != null) 'kind': kind,
      if (status != null) 'status': status,
      if (outcome != null) 'outcome': outcome,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (originMessageId != null) 'origin_message_id': originMessageId,
      if (budgetMessageId != null) 'budget_message_id': budgetMessageId,
      if (codecVersion != null) 'codec_version': codecVersion,
      if (interpretationJson != null) 'interpretation_json': interpretationJson,
      if (draftJson != null) 'draft_json': draftJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProposalsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? kind,
    Value<String>? status,
    Value<String?>? outcome,
    Value<int?>? resolvedAt,
    Value<String?>? originMessageId,
    Value<String?>? budgetMessageId,
    Value<int>? codecVersion,
    Value<String?>? interpretationJson,
    Value<String>? draftJson,
    Value<int>? rowid,
  }) {
    return ProposalsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      originMessageId: originMessageId ?? this.originMessageId,
      budgetMessageId: budgetMessageId ?? this.budgetMessageId,
      codecVersion: codecVersion ?? this.codecVersion,
      interpretationJson: interpretationJson ?? this.interpretationJson,
      draftJson: draftJson ?? this.draftJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<int>(resolvedAt.value);
    }
    if (originMessageId.present) {
      map['origin_message_id'] = Variable<String>(originMessageId.value);
    }
    if (budgetMessageId.present) {
      map['budget_message_id'] = Variable<String>(budgetMessageId.value);
    }
    if (codecVersion.present) {
      map['codec_version'] = Variable<int>(codecVersion.value);
    }
    if (interpretationJson.present) {
      map['interpretation_json'] = Variable<String>(interpretationJson.value);
    }
    if (draftJson.present) {
      map['draft_json'] = Variable<String>(draftJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProposalsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('outcome: $outcome, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('originMessageId: $originMessageId, ')
          ..write('budgetMessageId: $budgetMessageId, ')
          ..write('codecVersion: $codecVersion, ')
          ..write('interpretationJson: $interpretationJson, ')
          ..write('draftJson: $draftJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeighInsTable extends WeighIns
    with TableInfo<$WeighInsTable, WeighInRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeighInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _measuredAtUtcMeta = const VerificationMeta(
    'measuredAtUtc',
  );
  @override
  late final GeneratedColumn<int> measuredAtUtc = GeneratedColumn<int>(
    'measured_at_utc',
    aliasedName,
    false,
    check: () => ComparableExpr(measuredAtUtc).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinMeta = const VerificationMeta(
    'tzOffsetMin',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMin = GeneratedColumn<int>(
    'tz_offset_min',
    aliasedName,
    false,
    check: () => ComparableExpr(tzOffsetMin).isBetweenValues(-720, 840),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kgMeta = const VerificationMeta('kg');
  @override
  late final GeneratedColumn<double> kg = GeneratedColumn<double>(
    'kg',
    aliasedName,
    false,
    check: () => ComparableExpr(kg).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputValueMeta = const VerificationMeta(
    'inputValue',
  );
  @override
  late final GeneratedColumn<double> inputValue = GeneratedColumn<double>(
    'input_value',
    aliasedName,
    false,
    check: () => ComparableExpr(inputValue).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputUnitMeta = const VerificationMeta(
    'inputUnit',
  );
  @override
  late final GeneratedColumn<String> inputUnit = GeneratedColumn<String>(
    'input_unit',
    aliasedName,
    false,
    check: () => inputUnit.isIn(const ['kg', 'lb']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredForDayMeta = const VerificationMeta(
    'preferredForDay',
  );
  @override
  late final GeneratedColumn<bool> preferredForDay = GeneratedColumn<bool>(
    'preferred_for_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("preferred_for_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    measuredAtUtc,
    tzOffsetMin,
    localDate,
    kg,
    inputValue,
    inputUnit,
    note,
    preferredForDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weigh_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeighInRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('measured_at_utc')) {
      context.handle(
        _measuredAtUtcMeta,
        measuredAtUtc.isAcceptableOrUnknown(
          data['measured_at_utc']!,
          _measuredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measuredAtUtcMeta);
    }
    if (data.containsKey('tz_offset_min')) {
      context.handle(
        _tzOffsetMinMeta,
        tzOffsetMin.isAcceptableOrUnknown(
          data['tz_offset_min']!,
          _tzOffsetMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('kg')) {
      context.handle(_kgMeta, kg.isAcceptableOrUnknown(data['kg']!, _kgMeta));
    } else if (isInserting) {
      context.missing(_kgMeta);
    }
    if (data.containsKey('input_value')) {
      context.handle(
        _inputValueMeta,
        inputValue.isAcceptableOrUnknown(data['input_value']!, _inputValueMeta),
      );
    } else if (isInserting) {
      context.missing(_inputValueMeta);
    }
    if (data.containsKey('input_unit')) {
      context.handle(
        _inputUnitMeta,
        inputUnit.isAcceptableOrUnknown(data['input_unit']!, _inputUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_inputUnitMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('preferred_for_day')) {
      context.handle(
        _preferredForDayMeta,
        preferredForDay.isAcceptableOrUnknown(
          data['preferred_for_day']!,
          _preferredForDayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeighInRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeighInRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      measuredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}measured_at_utc'],
      )!,
      tzOffsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_min'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      kg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kg'],
      )!,
      inputValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}input_value'],
      )!,
      inputUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_unit'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      preferredForDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}preferred_for_day'],
      )!,
    );
  }

  @override
  $WeighInsTable createAlias(String alias) {
    return $WeighInsTable(attachedDatabase, alias);
  }
}

class WeighInRow extends DataClass implements Insertable<WeighInRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// When it was measured, UTC ms (≥ 0, the wire's minimum; A14 PA9).
  final int measuredAtUtc;

  /// The zone offset where it was measured, minutes ahead of UTC.
  final int tzOffsetMin;

  /// The day, `YYYY-MM-DD`, from the stored offset (DY-002).
  final String localDate;

  /// The canonical value in kg, rounded once to storage precision.
  final double kg;

  /// The value as typed (TD-017).
  final double inputValue;

  /// The unit as typed: `kg` or `lb`.
  final String inputUnit;

  /// The optional note. User content.
  final String? note;

  /// The user picked it for the trend on its day (WB-003, A14 D3).
  final bool preferredForDay;
  const WeighInRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.measuredAtUtc,
    required this.tzOffsetMin,
    required this.localDate,
    required this.kg,
    required this.inputValue,
    required this.inputUnit,
    this.note,
    required this.preferredForDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['measured_at_utc'] = Variable<int>(measuredAtUtc);
    map['tz_offset_min'] = Variable<int>(tzOffsetMin);
    map['local_date'] = Variable<String>(localDate);
    map['kg'] = Variable<double>(kg);
    map['input_value'] = Variable<double>(inputValue);
    map['input_unit'] = Variable<String>(inputUnit);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['preferred_for_day'] = Variable<bool>(preferredForDay);
    return map;
  }

  WeighInsCompanion toCompanion(bool nullToAbsent) {
    return WeighInsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      measuredAtUtc: Value(measuredAtUtc),
      tzOffsetMin: Value(tzOffsetMin),
      localDate: Value(localDate),
      kg: Value(kg),
      inputValue: Value(inputValue),
      inputUnit: Value(inputUnit),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      preferredForDay: Value(preferredForDay),
    );
  }

  factory WeighInRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeighInRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      measuredAtUtc: serializer.fromJson<int>(json['measuredAtUtc']),
      tzOffsetMin: serializer.fromJson<int>(json['tzOffsetMin']),
      localDate: serializer.fromJson<String>(json['localDate']),
      kg: serializer.fromJson<double>(json['kg']),
      inputValue: serializer.fromJson<double>(json['inputValue']),
      inputUnit: serializer.fromJson<String>(json['inputUnit']),
      note: serializer.fromJson<String?>(json['note']),
      preferredForDay: serializer.fromJson<bool>(json['preferredForDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'measuredAtUtc': serializer.toJson<int>(measuredAtUtc),
      'tzOffsetMin': serializer.toJson<int>(tzOffsetMin),
      'localDate': serializer.toJson<String>(localDate),
      'kg': serializer.toJson<double>(kg),
      'inputValue': serializer.toJson<double>(inputValue),
      'inputUnit': serializer.toJson<String>(inputUnit),
      'note': serializer.toJson<String?>(note),
      'preferredForDay': serializer.toJson<bool>(preferredForDay),
    };
  }

  WeighInRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    int? measuredAtUtc,
    int? tzOffsetMin,
    String? localDate,
    double? kg,
    double? inputValue,
    String? inputUnit,
    Value<String?> note = const Value.absent(),
    bool? preferredForDay,
  }) => WeighInRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    measuredAtUtc: measuredAtUtc ?? this.measuredAtUtc,
    tzOffsetMin: tzOffsetMin ?? this.tzOffsetMin,
    localDate: localDate ?? this.localDate,
    kg: kg ?? this.kg,
    inputValue: inputValue ?? this.inputValue,
    inputUnit: inputUnit ?? this.inputUnit,
    note: note.present ? note.value : this.note,
    preferredForDay: preferredForDay ?? this.preferredForDay,
  );
  WeighInRow copyWithCompanion(WeighInsCompanion data) {
    return WeighInRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      measuredAtUtc: data.measuredAtUtc.present
          ? data.measuredAtUtc.value
          : this.measuredAtUtc,
      tzOffsetMin: data.tzOffsetMin.present
          ? data.tzOffsetMin.value
          : this.tzOffsetMin,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      kg: data.kg.present ? data.kg.value : this.kg,
      inputValue: data.inputValue.present
          ? data.inputValue.value
          : this.inputValue,
      inputUnit: data.inputUnit.present ? data.inputUnit.value : this.inputUnit,
      note: data.note.present ? data.note.value : this.note,
      preferredForDay: data.preferredForDay.present
          ? data.preferredForDay.value
          : this.preferredForDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeighInRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('measuredAtUtc: $measuredAtUtc, ')
          ..write('tzOffsetMin: $tzOffsetMin, ')
          ..write('localDate: $localDate, ')
          ..write('kg: $kg, ')
          ..write('inputValue: $inputValue, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('note: $note, ')
          ..write('preferredForDay: $preferredForDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    measuredAtUtc,
    tzOffsetMin,
    localDate,
    kg,
    inputValue,
    inputUnit,
    note,
    preferredForDay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeighInRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.measuredAtUtc == this.measuredAtUtc &&
          other.tzOffsetMin == this.tzOffsetMin &&
          other.localDate == this.localDate &&
          other.kg == this.kg &&
          other.inputValue == this.inputValue &&
          other.inputUnit == this.inputUnit &&
          other.note == this.note &&
          other.preferredForDay == this.preferredForDay);
}

class WeighInsCompanion extends UpdateCompanion<WeighInRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<int> measuredAtUtc;
  final Value<int> tzOffsetMin;
  final Value<String> localDate;
  final Value<double> kg;
  final Value<double> inputValue;
  final Value<String> inputUnit;
  final Value<String?> note;
  final Value<bool> preferredForDay;
  final Value<int> rowid;
  const WeighInsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.measuredAtUtc = const Value.absent(),
    this.tzOffsetMin = const Value.absent(),
    this.localDate = const Value.absent(),
    this.kg = const Value.absent(),
    this.inputValue = const Value.absent(),
    this.inputUnit = const Value.absent(),
    this.note = const Value.absent(),
    this.preferredForDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeighInsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required int measuredAtUtc,
    required int tzOffsetMin,
    required String localDate,
    required double kg,
    required double inputValue,
    required String inputUnit,
    this.note = const Value.absent(),
    this.preferredForDay = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       measuredAtUtc = Value(measuredAtUtc),
       tzOffsetMin = Value(tzOffsetMin),
       localDate = Value(localDate),
       kg = Value(kg),
       inputValue = Value(inputValue),
       inputUnit = Value(inputUnit);
  static Insertable<WeighInRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<int>? measuredAtUtc,
    Expression<int>? tzOffsetMin,
    Expression<String>? localDate,
    Expression<double>? kg,
    Expression<double>? inputValue,
    Expression<String>? inputUnit,
    Expression<String>? note,
    Expression<bool>? preferredForDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (measuredAtUtc != null) 'measured_at_utc': measuredAtUtc,
      if (tzOffsetMin != null) 'tz_offset_min': tzOffsetMin,
      if (localDate != null) 'local_date': localDate,
      if (kg != null) 'kg': kg,
      if (inputValue != null) 'input_value': inputValue,
      if (inputUnit != null) 'input_unit': inputUnit,
      if (note != null) 'note': note,
      if (preferredForDay != null) 'preferred_for_day': preferredForDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeighInsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<int>? measuredAtUtc,
    Value<int>? tzOffsetMin,
    Value<String>? localDate,
    Value<double>? kg,
    Value<double>? inputValue,
    Value<String>? inputUnit,
    Value<String?>? note,
    Value<bool>? preferredForDay,
    Value<int>? rowid,
  }) {
    return WeighInsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      measuredAtUtc: measuredAtUtc ?? this.measuredAtUtc,
      tzOffsetMin: tzOffsetMin ?? this.tzOffsetMin,
      localDate: localDate ?? this.localDate,
      kg: kg ?? this.kg,
      inputValue: inputValue ?? this.inputValue,
      inputUnit: inputUnit ?? this.inputUnit,
      note: note ?? this.note,
      preferredForDay: preferredForDay ?? this.preferredForDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (measuredAtUtc.present) {
      map['measured_at_utc'] = Variable<int>(measuredAtUtc.value);
    }
    if (tzOffsetMin.present) {
      map['tz_offset_min'] = Variable<int>(tzOffsetMin.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (kg.present) {
      map['kg'] = Variable<double>(kg.value);
    }
    if (inputValue.present) {
      map['input_value'] = Variable<double>(inputValue.value);
    }
    if (inputUnit.present) {
      map['input_unit'] = Variable<String>(inputUnit.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (preferredForDay.present) {
      map['preferred_for_day'] = Variable<bool>(preferredForDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeighInsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('measuredAtUtc: $measuredAtUtc, ')
          ..write('tzOffsetMin: $tzOffsetMin, ')
          ..write('localDate: $localDate, ')
          ..write('kg: $kg, ')
          ..write('inputValue: $inputValue, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('note: $note, ')
          ..write('preferredForDay: $preferredForDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, MeasurementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(const [
      'waist',
      'chest',
      'hips',
      'arm',
      'thigh',
      'neck',
      'bodyFat',
      'custom',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customTypeIdMeta = const VerificationMeta(
    'customTypeId',
  );
  @override
  late final GeneratedColumn<String> customTypeId = GeneratedColumn<String>(
    'custom_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _measuredAtUtcMeta = const VerificationMeta(
    'measuredAtUtc',
  );
  @override
  late final GeneratedColumn<int> measuredAtUtc = GeneratedColumn<int>(
    'measured_at_utc',
    aliasedName,
    false,
    check: () => ComparableExpr(measuredAtUtc).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinMeta = const VerificationMeta(
    'tzOffsetMin',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMin = GeneratedColumn<int>(
    'tz_offset_min',
    aliasedName,
    false,
    check: () => ComparableExpr(tzOffsetMin).isBetweenValues(-720, 840),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    check: () => ComparableExpr(value).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputValueMeta = const VerificationMeta(
    'inputValue',
  );
  @override
  late final GeneratedColumn<double> inputValue = GeneratedColumn<double>(
    'input_value',
    aliasedName,
    false,
    check: () => ComparableExpr(inputValue).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputUnitMeta = const VerificationMeta(
    'inputUnit',
  );
  @override
  late final GeneratedColumn<String> inputUnit = GeneratedColumn<String>(
    'input_unit',
    aliasedName,
    false,
    check: () => inputUnit.isIn(const ['cm', 'in', 'percent']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    kind,
    customTypeId,
    measuredAtUtc,
    tzOffsetMin,
    localDate,
    value,
    inputValue,
    inputUnit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeasurementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('custom_type_id')) {
      context.handle(
        _customTypeIdMeta,
        customTypeId.isAcceptableOrUnknown(
          data['custom_type_id']!,
          _customTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('measured_at_utc')) {
      context.handle(
        _measuredAtUtcMeta,
        measuredAtUtc.isAcceptableOrUnknown(
          data['measured_at_utc']!,
          _measuredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measuredAtUtcMeta);
    }
    if (data.containsKey('tz_offset_min')) {
      context.handle(
        _tzOffsetMinMeta,
        tzOffsetMin.isAcceptableOrUnknown(
          data['tz_offset_min']!,
          _tzOffsetMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('input_value')) {
      context.handle(
        _inputValueMeta,
        inputValue.isAcceptableOrUnknown(data['input_value']!, _inputValueMeta),
      );
    } else if (isInserting) {
      context.missing(_inputValueMeta);
    }
    if (data.containsKey('input_unit')) {
      context.handle(
        _inputUnitMeta,
        inputUnit.isAcceptableOrUnknown(data['input_unit']!, _inputUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_inputUnitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeasurementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeasurementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      customTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_type_id'],
      ),
      measuredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}measured_at_utc'],
      )!,
      tzOffsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_min'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      inputValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}input_value'],
      )!,
      inputUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_unit'],
      )!,
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }
}

class MeasurementRow extends DataClass implements Insertable<MeasurementRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The kind: a built-in code or `custom`.
  final String kind;

  /// The custom type for `custom` (no FK: synced rows may arrive in any
  /// order), else null.
  final String? customTypeId;

  /// When it was measured, UTC ms (≥ 0, the wire's minimum).
  final int measuredAtUtc;

  /// The zone offset where it was measured, minutes ahead of UTC.
  final int tzOffsetMin;

  /// The day, `YYYY-MM-DD`, from the stored offset (DY-002).
  final String localDate;

  /// The canonical value: cm for lengths, % for body fat, rounded once to
  /// storage precision.
  final double value;

  /// The value as typed (TD-017).
  final double inputValue;

  /// The unit as typed: `cm`, `in` or `percent`.
  final String inputUnit;
  const MeasurementRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.kind,
    this.customTypeId,
    required this.measuredAtUtc,
    required this.tzOffsetMin,
    required this.localDate,
    required this.value,
    required this.inputValue,
    required this.inputUnit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || customTypeId != null) {
      map['custom_type_id'] = Variable<String>(customTypeId);
    }
    map['measured_at_utc'] = Variable<int>(measuredAtUtc);
    map['tz_offset_min'] = Variable<int>(tzOffsetMin);
    map['local_date'] = Variable<String>(localDate);
    map['value'] = Variable<double>(value);
    map['input_value'] = Variable<double>(inputValue);
    map['input_unit'] = Variable<String>(inputUnit);
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      kind: Value(kind),
      customTypeId: customTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(customTypeId),
      measuredAtUtc: Value(measuredAtUtc),
      tzOffsetMin: Value(tzOffsetMin),
      localDate: Value(localDate),
      value: Value(value),
      inputValue: Value(inputValue),
      inputUnit: Value(inputUnit),
    );
  }

  factory MeasurementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeasurementRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      kind: serializer.fromJson<String>(json['kind']),
      customTypeId: serializer.fromJson<String?>(json['customTypeId']),
      measuredAtUtc: serializer.fromJson<int>(json['measuredAtUtc']),
      tzOffsetMin: serializer.fromJson<int>(json['tzOffsetMin']),
      localDate: serializer.fromJson<String>(json['localDate']),
      value: serializer.fromJson<double>(json['value']),
      inputValue: serializer.fromJson<double>(json['inputValue']),
      inputUnit: serializer.fromJson<String>(json['inputUnit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'kind': serializer.toJson<String>(kind),
      'customTypeId': serializer.toJson<String?>(customTypeId),
      'measuredAtUtc': serializer.toJson<int>(measuredAtUtc),
      'tzOffsetMin': serializer.toJson<int>(tzOffsetMin),
      'localDate': serializer.toJson<String>(localDate),
      'value': serializer.toJson<double>(value),
      'inputValue': serializer.toJson<double>(inputValue),
      'inputUnit': serializer.toJson<String>(inputUnit),
    };
  }

  MeasurementRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? kind,
    Value<String?> customTypeId = const Value.absent(),
    int? measuredAtUtc,
    int? tzOffsetMin,
    String? localDate,
    double? value,
    double? inputValue,
    String? inputUnit,
  }) => MeasurementRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    kind: kind ?? this.kind,
    customTypeId: customTypeId.present ? customTypeId.value : this.customTypeId,
    measuredAtUtc: measuredAtUtc ?? this.measuredAtUtc,
    tzOffsetMin: tzOffsetMin ?? this.tzOffsetMin,
    localDate: localDate ?? this.localDate,
    value: value ?? this.value,
    inputValue: inputValue ?? this.inputValue,
    inputUnit: inputUnit ?? this.inputUnit,
  );
  MeasurementRow copyWithCompanion(MeasurementsCompanion data) {
    return MeasurementRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      kind: data.kind.present ? data.kind.value : this.kind,
      customTypeId: data.customTypeId.present
          ? data.customTypeId.value
          : this.customTypeId,
      measuredAtUtc: data.measuredAtUtc.present
          ? data.measuredAtUtc.value
          : this.measuredAtUtc,
      tzOffsetMin: data.tzOffsetMin.present
          ? data.tzOffsetMin.value
          : this.tzOffsetMin,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      value: data.value.present ? data.value.value : this.value,
      inputValue: data.inputValue.present
          ? data.inputValue.value
          : this.inputValue,
      inputUnit: data.inputUnit.present ? data.inputUnit.value : this.inputUnit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('kind: $kind, ')
          ..write('customTypeId: $customTypeId, ')
          ..write('measuredAtUtc: $measuredAtUtc, ')
          ..write('tzOffsetMin: $tzOffsetMin, ')
          ..write('localDate: $localDate, ')
          ..write('value: $value, ')
          ..write('inputValue: $inputValue, ')
          ..write('inputUnit: $inputUnit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    kind,
    customTypeId,
    measuredAtUtc,
    tzOffsetMin,
    localDate,
    value,
    inputValue,
    inputUnit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeasurementRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.kind == this.kind &&
          other.customTypeId == this.customTypeId &&
          other.measuredAtUtc == this.measuredAtUtc &&
          other.tzOffsetMin == this.tzOffsetMin &&
          other.localDate == this.localDate &&
          other.value == this.value &&
          other.inputValue == this.inputValue &&
          other.inputUnit == this.inputUnit);
}

class MeasurementsCompanion extends UpdateCompanion<MeasurementRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> kind;
  final Value<String?> customTypeId;
  final Value<int> measuredAtUtc;
  final Value<int> tzOffsetMin;
  final Value<String> localDate;
  final Value<double> value;
  final Value<double> inputValue;
  final Value<String> inputUnit;
  final Value<int> rowid;
  const MeasurementsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.kind = const Value.absent(),
    this.customTypeId = const Value.absent(),
    this.measuredAtUtc = const Value.absent(),
    this.tzOffsetMin = const Value.absent(),
    this.localDate = const Value.absent(),
    this.value = const Value.absent(),
    this.inputValue = const Value.absent(),
    this.inputUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String kind,
    this.customTypeId = const Value.absent(),
    required int measuredAtUtc,
    required int tzOffsetMin,
    required String localDate,
    required double value,
    required double inputValue,
    required String inputUnit,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       kind = Value(kind),
       measuredAtUtc = Value(measuredAtUtc),
       tzOffsetMin = Value(tzOffsetMin),
       localDate = Value(localDate),
       value = Value(value),
       inputValue = Value(inputValue),
       inputUnit = Value(inputUnit);
  static Insertable<MeasurementRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? kind,
    Expression<String>? customTypeId,
    Expression<int>? measuredAtUtc,
    Expression<int>? tzOffsetMin,
    Expression<String>? localDate,
    Expression<double>? value,
    Expression<double>? inputValue,
    Expression<String>? inputUnit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (kind != null) 'kind': kind,
      if (customTypeId != null) 'custom_type_id': customTypeId,
      if (measuredAtUtc != null) 'measured_at_utc': measuredAtUtc,
      if (tzOffsetMin != null) 'tz_offset_min': tzOffsetMin,
      if (localDate != null) 'local_date': localDate,
      if (value != null) 'value': value,
      if (inputValue != null) 'input_value': inputValue,
      if (inputUnit != null) 'input_unit': inputUnit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeasurementsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? kind,
    Value<String?>? customTypeId,
    Value<int>? measuredAtUtc,
    Value<int>? tzOffsetMin,
    Value<String>? localDate,
    Value<double>? value,
    Value<double>? inputValue,
    Value<String>? inputUnit,
    Value<int>? rowid,
  }) {
    return MeasurementsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      kind: kind ?? this.kind,
      customTypeId: customTypeId ?? this.customTypeId,
      measuredAtUtc: measuredAtUtc ?? this.measuredAtUtc,
      tzOffsetMin: tzOffsetMin ?? this.tzOffsetMin,
      localDate: localDate ?? this.localDate,
      value: value ?? this.value,
      inputValue: inputValue ?? this.inputValue,
      inputUnit: inputUnit ?? this.inputUnit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (customTypeId.present) {
      map['custom_type_id'] = Variable<String>(customTypeId.value);
    }
    if (measuredAtUtc.present) {
      map['measured_at_utc'] = Variable<int>(measuredAtUtc.value);
    }
    if (tzOffsetMin.present) {
      map['tz_offset_min'] = Variable<int>(tzOffsetMin.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (inputValue.present) {
      map['input_value'] = Variable<double>(inputValue.value);
    }
    if (inputUnit.present) {
      map['input_unit'] = Variable<String>(inputUnit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('kind: $kind, ')
          ..write('customTypeId: $customTypeId, ')
          ..write('measuredAtUtc: $measuredAtUtc, ')
          ..write('tzOffsetMin: $tzOffsetMin, ')
          ..write('localDate: $localDate, ')
          ..write('value: $value, ')
          ..write('inputValue: $inputValue, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeasurementTypesTable extends MeasurementTypes
    with TableInfo<$MeasurementTypesTable, MeasurementTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurement_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeasurementTypeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeasurementTypeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeasurementTypeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $MeasurementTypesTable createAlias(String alias) {
    return $MeasurementTypesTable(attachedDatabase, alias);
  }
}

class MeasurementTypeRow extends DataClass
    implements Insertable<MeasurementTypeRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The type's name ("Left arm"). User content.
  final String name;
  const MeasurementTypeRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['name'] = Variable<String>(name);
    return map;
  }

  MeasurementTypesCompanion toCompanion(bool nullToAbsent) {
    return MeasurementTypesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      name: Value(name),
    );
  }

  factory MeasurementTypeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeasurementTypeRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'name': serializer.toJson<String>(name),
    };
  }

  MeasurementTypeRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? name,
  }) => MeasurementTypeRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    name: name ?? this.name,
  );
  MeasurementTypeRow copyWithCompanion(MeasurementTypesCompanion data) {
    return MeasurementTypeRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementTypeRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    name,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeasurementTypeRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.name == this.name);
}

class MeasurementTypesCompanion extends UpdateCompanion<MeasurementTypeRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> name;
  final Value<int> rowid;
  const MeasurementTypesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeasurementTypesCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       name = Value(name);
  static Insertable<MeasurementTypeRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeasurementTypesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return MeasurementTypesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementTypesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalPhasesTable extends GoalPhases
    with TableInfo<$GoalPhasesTable, GoalPhaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalPhasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalTypeMeta = const VerificationMeta(
    'goalType',
  );
  @override
  late final GeneratedColumn<String> goalType = GeneratedColumn<String>(
    'goal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expressionKindMeta = const VerificationMeta(
    'expressionKind',
  );
  @override
  late final GeneratedColumn<String> expressionKind = GeneratedColumn<String>(
    'expression_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetKgMeta = const VerificationMeta(
    'targetKg',
  );
  @override
  late final GeneratedColumn<double> targetKg = GeneratedColumn<double>(
    'target_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kgPerWeekMeta = const VerificationMeta(
    'kgPerWeek',
  );
  @override
  late final GeneratedColumn<double> kgPerWeek = GeneratedColumn<double>(
    'kg_per_week',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthKgMeta = const VerificationMeta(
    'monthKg',
  );
  @override
  late final GeneratedColumn<double> monthKg = GeneratedColumn<double>(
    'month_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightInputUnitMeta = const VerificationMeta(
    'weightInputUnit',
  );
  @override
  late final GeneratedColumn<String> weightInputUnit = GeneratedColumn<String>(
    'weight_input_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    revision,
    name,
    startDate,
    endDate,
    goalType,
    expressionKind,
    targetKg,
    targetDate,
    kgPerWeek,
    monthKg,
    month,
    weightInputUnit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_phases';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalPhaseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('goal_type')) {
      context.handle(
        _goalTypeMeta,
        goalType.isAcceptableOrUnknown(data['goal_type']!, _goalTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_goalTypeMeta);
    }
    if (data.containsKey('expression_kind')) {
      context.handle(
        _expressionKindMeta,
        expressionKind.isAcceptableOrUnknown(
          data['expression_kind']!,
          _expressionKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expressionKindMeta);
    }
    if (data.containsKey('target_kg')) {
      context.handle(
        _targetKgMeta,
        targetKg.isAcceptableOrUnknown(data['target_kg']!, _targetKgMeta),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('kg_per_week')) {
      context.handle(
        _kgPerWeekMeta,
        kgPerWeek.isAcceptableOrUnknown(data['kg_per_week']!, _kgPerWeekMeta),
      );
    }
    if (data.containsKey('month_kg')) {
      context.handle(
        _monthKgMeta,
        monthKg.isAcceptableOrUnknown(data['month_kg']!, _monthKgMeta),
      );
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    }
    if (data.containsKey('weight_input_unit')) {
      context.handle(
        _weightInputUnitMeta,
        weightInputUnit.isAcceptableOrUnknown(
          data['weight_input_unit']!,
          _weightInputUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weightInputUnitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalPhaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalPhaseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      goalType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_type'],
      )!,
      expressionKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expression_kind'],
      )!,
      targetKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_kg'],
      ),
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      ),
      kgPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kg_per_week'],
      ),
      monthKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}month_kg'],
      ),
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      ),
      weightInputUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight_input_unit'],
      )!,
    );
  }

  @override
  $GoalPhasesTable createAlias(String alias) {
    return $GoalPhasesTable(attachedDatabase, alias);
  }
}

class GoalPhaseRow extends DataClass implements Insertable<GoalPhaseRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The domain revision (≥ 1), separate from the row version.
  final int revision;

  /// The user's name, `null` for the default label. User content.
  final String? name;

  /// The first day, `YYYY-MM-DD`.
  final String startDate;

  /// The last day, `YYYY-MM-DD`, or `null` while open.
  final String? endDate;

  /// `lose`, `maintain` or `gain`.
  final String goalType;

  /// `targetDate`, `targetRate`, `weekly` or `monthly`; maintain is
  /// `weekly` 0.
  final String expressionKind;

  /// Target weight, kg (`targetDate`, `targetRate`).
  final double? targetKg;

  /// Target date, `YYYY-MM-DD` (`targetDate`).
  final String? targetDate;

  /// kg a week: a positive speed (`targetRate`) or signed (`weekly`).
  final double? kgPerWeek;

  /// Signed kg over the named month (`monthly`).
  final double? monthKg;

  /// The named month's first day, `YYYY-MM-DD` (`monthly`).
  final String? month;

  /// The unit the goal's weights and rates were typed in: `kg` or `lb`
  /// (TD-017). Stored values are canonical kg.
  final String weightInputUnit;
  const GoalPhaseRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.revision,
    this.name,
    required this.startDate,
    this.endDate,
    required this.goalType,
    required this.expressionKind,
    this.targetKg,
    this.targetDate,
    this.kgPerWeek,
    this.monthKg,
    this.month,
    required this.weightInputUnit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    map['goal_type'] = Variable<String>(goalType);
    map['expression_kind'] = Variable<String>(expressionKind);
    if (!nullToAbsent || targetKg != null) {
      map['target_kg'] = Variable<double>(targetKg);
    }
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(targetDate);
    }
    if (!nullToAbsent || kgPerWeek != null) {
      map['kg_per_week'] = Variable<double>(kgPerWeek);
    }
    if (!nullToAbsent || monthKg != null) {
      map['month_kg'] = Variable<double>(monthKg);
    }
    if (!nullToAbsent || month != null) {
      map['month'] = Variable<String>(month);
    }
    map['weight_input_unit'] = Variable<String>(weightInputUnit);
    return map;
  }

  GoalPhasesCompanion toCompanion(bool nullToAbsent) {
    return GoalPhasesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      revision: Value(revision),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      goalType: Value(goalType),
      expressionKind: Value(expressionKind),
      targetKg: targetKg == null && nullToAbsent
          ? const Value.absent()
          : Value(targetKg),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      kgPerWeek: kgPerWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(kgPerWeek),
      monthKg: monthKg == null && nullToAbsent
          ? const Value.absent()
          : Value(monthKg),
      month: month == null && nullToAbsent
          ? const Value.absent()
          : Value(month),
      weightInputUnit: Value(weightInputUnit),
    );
  }

  factory GoalPhaseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalPhaseRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      revision: serializer.fromJson<int>(json['revision']),
      name: serializer.fromJson<String?>(json['name']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      goalType: serializer.fromJson<String>(json['goalType']),
      expressionKind: serializer.fromJson<String>(json['expressionKind']),
      targetKg: serializer.fromJson<double?>(json['targetKg']),
      targetDate: serializer.fromJson<String?>(json['targetDate']),
      kgPerWeek: serializer.fromJson<double?>(json['kgPerWeek']),
      monthKg: serializer.fromJson<double?>(json['monthKg']),
      month: serializer.fromJson<String?>(json['month']),
      weightInputUnit: serializer.fromJson<String>(json['weightInputUnit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'revision': serializer.toJson<int>(revision),
      'name': serializer.toJson<String?>(name),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'goalType': serializer.toJson<String>(goalType),
      'expressionKind': serializer.toJson<String>(expressionKind),
      'targetKg': serializer.toJson<double?>(targetKg),
      'targetDate': serializer.toJson<String?>(targetDate),
      'kgPerWeek': serializer.toJson<double?>(kgPerWeek),
      'monthKg': serializer.toJson<double?>(monthKg),
      'month': serializer.toJson<String?>(month),
      'weightInputUnit': serializer.toJson<String>(weightInputUnit),
    };
  }

  GoalPhaseRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    int? revision,
    Value<String?> name = const Value.absent(),
    String? startDate,
    Value<String?> endDate = const Value.absent(),
    String? goalType,
    String? expressionKind,
    Value<double?> targetKg = const Value.absent(),
    Value<String?> targetDate = const Value.absent(),
    Value<double?> kgPerWeek = const Value.absent(),
    Value<double?> monthKg = const Value.absent(),
    Value<String?> month = const Value.absent(),
    String? weightInputUnit,
  }) => GoalPhaseRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    revision: revision ?? this.revision,
    name: name.present ? name.value : this.name,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    goalType: goalType ?? this.goalType,
    expressionKind: expressionKind ?? this.expressionKind,
    targetKg: targetKg.present ? targetKg.value : this.targetKg,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    kgPerWeek: kgPerWeek.present ? kgPerWeek.value : this.kgPerWeek,
    monthKg: monthKg.present ? monthKg.value : this.monthKg,
    month: month.present ? month.value : this.month,
    weightInputUnit: weightInputUnit ?? this.weightInputUnit,
  );
  GoalPhaseRow copyWithCompanion(GoalPhasesCompanion data) {
    return GoalPhaseRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      revision: data.revision.present ? data.revision.value : this.revision,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      goalType: data.goalType.present ? data.goalType.value : this.goalType,
      expressionKind: data.expressionKind.present
          ? data.expressionKind.value
          : this.expressionKind,
      targetKg: data.targetKg.present ? data.targetKg.value : this.targetKg,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      kgPerWeek: data.kgPerWeek.present ? data.kgPerWeek.value : this.kgPerWeek,
      monthKg: data.monthKg.present ? data.monthKg.value : this.monthKg,
      month: data.month.present ? data.month.value : this.month,
      weightInputUnit: data.weightInputUnit.present
          ? data.weightInputUnit.value
          : this.weightInputUnit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalPhaseRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('revision: $revision, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('goalType: $goalType, ')
          ..write('expressionKind: $expressionKind, ')
          ..write('targetKg: $targetKg, ')
          ..write('targetDate: $targetDate, ')
          ..write('kgPerWeek: $kgPerWeek, ')
          ..write('monthKg: $monthKg, ')
          ..write('month: $month, ')
          ..write('weightInputUnit: $weightInputUnit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    revision,
    name,
    startDate,
    endDate,
    goalType,
    expressionKind,
    targetKg,
    targetDate,
    kgPerWeek,
    monthKg,
    month,
    weightInputUnit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalPhaseRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.revision == this.revision &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.goalType == this.goalType &&
          other.expressionKind == this.expressionKind &&
          other.targetKg == this.targetKg &&
          other.targetDate == this.targetDate &&
          other.kgPerWeek == this.kgPerWeek &&
          other.monthKg == this.monthKg &&
          other.month == this.month &&
          other.weightInputUnit == this.weightInputUnit);
}

class GoalPhasesCompanion extends UpdateCompanion<GoalPhaseRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<int> revision;
  final Value<String?> name;
  final Value<String> startDate;
  final Value<String?> endDate;
  final Value<String> goalType;
  final Value<String> expressionKind;
  final Value<double?> targetKg;
  final Value<String?> targetDate;
  final Value<double?> kgPerWeek;
  final Value<double?> monthKg;
  final Value<String?> month;
  final Value<String> weightInputUnit;
  final Value<int> rowid;
  const GoalPhasesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.revision = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.goalType = const Value.absent(),
    this.expressionKind = const Value.absent(),
    this.targetKg = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.kgPerWeek = const Value.absent(),
    this.monthKg = const Value.absent(),
    this.month = const Value.absent(),
    this.weightInputUnit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalPhasesCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required int revision,
    this.name = const Value.absent(),
    required String startDate,
    this.endDate = const Value.absent(),
    required String goalType,
    required String expressionKind,
    this.targetKg = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.kgPerWeek = const Value.absent(),
    this.monthKg = const Value.absent(),
    this.month = const Value.absent(),
    required String weightInputUnit,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       revision = Value(revision),
       startDate = Value(startDate),
       goalType = Value(goalType),
       expressionKind = Value(expressionKind),
       weightInputUnit = Value(weightInputUnit);
  static Insertable<GoalPhaseRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<int>? revision,
    Expression<String>? name,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? goalType,
    Expression<String>? expressionKind,
    Expression<double>? targetKg,
    Expression<String>? targetDate,
    Expression<double>? kgPerWeek,
    Expression<double>? monthKg,
    Expression<String>? month,
    Expression<String>? weightInputUnit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (revision != null) 'revision': revision,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (goalType != null) 'goal_type': goalType,
      if (expressionKind != null) 'expression_kind': expressionKind,
      if (targetKg != null) 'target_kg': targetKg,
      if (targetDate != null) 'target_date': targetDate,
      if (kgPerWeek != null) 'kg_per_week': kgPerWeek,
      if (monthKg != null) 'month_kg': monthKg,
      if (month != null) 'month': month,
      if (weightInputUnit != null) 'weight_input_unit': weightInputUnit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalPhasesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<int>? revision,
    Value<String?>? name,
    Value<String>? startDate,
    Value<String?>? endDate,
    Value<String>? goalType,
    Value<String>? expressionKind,
    Value<double?>? targetKg,
    Value<String?>? targetDate,
    Value<double?>? kgPerWeek,
    Value<double?>? monthKg,
    Value<String?>? month,
    Value<String>? weightInputUnit,
    Value<int>? rowid,
  }) {
    return GoalPhasesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      revision: revision ?? this.revision,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      goalType: goalType ?? this.goalType,
      expressionKind: expressionKind ?? this.expressionKind,
      targetKg: targetKg ?? this.targetKg,
      targetDate: targetDate ?? this.targetDate,
      kgPerWeek: kgPerWeek ?? this.kgPerWeek,
      monthKg: monthKg ?? this.monthKg,
      month: month ?? this.month,
      weightInputUnit: weightInputUnit ?? this.weightInputUnit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (goalType.present) {
      map['goal_type'] = Variable<String>(goalType.value);
    }
    if (expressionKind.present) {
      map['expression_kind'] = Variable<String>(expressionKind.value);
    }
    if (targetKg.present) {
      map['target_kg'] = Variable<double>(targetKg.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (kgPerWeek.present) {
      map['kg_per_week'] = Variable<double>(kgPerWeek.value);
    }
    if (monthKg.present) {
      map['month_kg'] = Variable<double>(monthKg.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (weightInputUnit.present) {
      map['weight_input_unit'] = Variable<String>(weightInputUnit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalPhasesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('revision: $revision, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('goalType: $goalType, ')
          ..write('expressionKind: $expressionKind, ')
          ..write('targetKg: $targetKg, ')
          ..write('targetDate: $targetDate, ')
          ..write('kgPerWeek: $kgPerWeek, ')
          ..write('monthKg: $monthKg, ')
          ..write('month: $month, ')
          ..write('weightInputUnit: $weightInputUnit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TargetSettingsRowsTable extends TargetSettingsRows
    with TableInfo<$TargetSettingsRowsTable, TargetSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TargetSettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  @override
  late final GeneratedColumn<String> effectiveFrom = GeneratedColumn<String>(
    'effective_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rebalancingMeta = const VerificationMeta(
    'rebalancing',
  );
  @override
  late final GeneratedColumn<bool> rebalancing = GeneratedColumn<bool>(
    'rebalancing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rebalancing" IN (0, 1))',
    ),
  );
  static const VerificationMeta _baseKcalMeta = const VerificationMeta(
    'baseKcal',
  );
  @override
  late final GeneratedColumn<double> baseKcal = GeneratedColumn<double>(
    'base_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manualMeta = const VerificationMeta('manual');
  @override
  late final GeneratedColumn<bool> manual = GeneratedColumn<bool>(
    'manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("manual" IN (0, 1))',
    ),
  );
  static const VerificationMeta _acknowledgedMeta = const VerificationMeta(
    'acknowledged',
  );
  @override
  late final GeneratedColumn<bool> acknowledged = GeneratedColumn<bool>(
    'acknowledged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("acknowledged" IN (0, 1))',
    ),
  );
  static const VerificationMeta _basisWeightKgMeta = const VerificationMeta(
    'basisWeightKg',
  );
  @override
  late final GeneratedColumn<double> basisWeightKg = GeneratedColumn<double>(
    'basis_weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftMonMeta = const VerificationMeta(
    'shiftMon',
  );
  @override
  late final GeneratedColumn<double> shiftMon = GeneratedColumn<double>(
    'shift_mon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shiftTueMeta = const VerificationMeta(
    'shiftTue',
  );
  @override
  late final GeneratedColumn<double> shiftTue = GeneratedColumn<double>(
    'shift_tue',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shiftWedMeta = const VerificationMeta(
    'shiftWed',
  );
  @override
  late final GeneratedColumn<double> shiftWed = GeneratedColumn<double>(
    'shift_wed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shiftThuMeta = const VerificationMeta(
    'shiftThu',
  );
  @override
  late final GeneratedColumn<double> shiftThu = GeneratedColumn<double>(
    'shift_thu',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shiftFriMeta = const VerificationMeta(
    'shiftFri',
  );
  @override
  late final GeneratedColumn<double> shiftFri = GeneratedColumn<double>(
    'shift_fri',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shiftSatMeta = const VerificationMeta(
    'shiftSat',
  );
  @override
  late final GeneratedColumn<double> shiftSat = GeneratedColumn<double>(
    'shift_sat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shiftSunMeta = const VerificationMeta(
    'shiftSun',
  );
  @override
  late final GeneratedColumn<double> shiftSun = GeneratedColumn<double>(
    'shift_sun',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinValueMeta = const VerificationMeta(
    'proteinValue',
  );
  @override
  late final GeneratedColumn<double> proteinValue = GeneratedColumn<double>(
    'protein_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinIsPercentMeta = const VerificationMeta(
    'proteinIsPercent',
  );
  @override
  late final GeneratedColumn<bool> proteinIsPercent = GeneratedColumn<bool>(
    'protein_is_percent',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("protein_is_percent" IN (0, 1))',
    ),
  );
  static const VerificationMeta _fatValueMeta = const VerificationMeta(
    'fatValue',
  );
  @override
  late final GeneratedColumn<double> fatValue = GeneratedColumn<double>(
    'fat_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatIsPercentMeta = const VerificationMeta(
    'fatIsPercent',
  );
  @override
  late final GeneratedColumn<bool> fatIsPercent = GeneratedColumn<bool>(
    'fat_is_percent',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fat_is_percent" IN (0, 1))',
    ),
  );
  static const VerificationMeta _carbsValueMeta = const VerificationMeta(
    'carbsValue',
  );
  @override
  late final GeneratedColumn<double> carbsValue = GeneratedColumn<double>(
    'carbs_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsIsPercentMeta = const VerificationMeta(
    'carbsIsPercent',
  );
  @override
  late final GeneratedColumn<bool> carbsIsPercent = GeneratedColumn<bool>(
    'carbs_is_percent',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("carbs_is_percent" IN (0, 1))',
    ),
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesProteinOnlyMeta =
      const VerificationMeta('caloriesProteinOnly');
  @override
  late final GeneratedColumn<bool> caloriesProteinOnly = GeneratedColumn<bool>(
    'calories_protein_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("calories_protein_only" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    revision,
    effectiveFrom,
    mode,
    rebalancing,
    baseKcal,
    manual,
    acknowledged,
    basisWeightKg,
    shiftMon,
    shiftTue,
    shiftWed,
    shiftThu,
    shiftFri,
    shiftSat,
    shiftSun,
    proteinValue,
    proteinIsPercent,
    fatValue,
    fatIsPercent,
    carbsValue,
    carbsIsPercent,
    fiberG,
    caloriesProteinOnly,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'target_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<TargetSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveFromMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('rebalancing')) {
      context.handle(
        _rebalancingMeta,
        rebalancing.isAcceptableOrUnknown(
          data['rebalancing']!,
          _rebalancingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rebalancingMeta);
    }
    if (data.containsKey('base_kcal')) {
      context.handle(
        _baseKcalMeta,
        baseKcal.isAcceptableOrUnknown(data['base_kcal']!, _baseKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_baseKcalMeta);
    }
    if (data.containsKey('manual')) {
      context.handle(
        _manualMeta,
        manual.isAcceptableOrUnknown(data['manual']!, _manualMeta),
      );
    } else if (isInserting) {
      context.missing(_manualMeta);
    }
    if (data.containsKey('acknowledged')) {
      context.handle(
        _acknowledgedMeta,
        acknowledged.isAcceptableOrUnknown(
          data['acknowledged']!,
          _acknowledgedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_acknowledgedMeta);
    }
    if (data.containsKey('basis_weight_kg')) {
      context.handle(
        _basisWeightKgMeta,
        basisWeightKg.isAcceptableOrUnknown(
          data['basis_weight_kg']!,
          _basisWeightKgMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_basisWeightKgMeta);
    }
    if (data.containsKey('shift_mon')) {
      context.handle(
        _shiftMonMeta,
        shiftMon.isAcceptableOrUnknown(data['shift_mon']!, _shiftMonMeta),
      );
    }
    if (data.containsKey('shift_tue')) {
      context.handle(
        _shiftTueMeta,
        shiftTue.isAcceptableOrUnknown(data['shift_tue']!, _shiftTueMeta),
      );
    }
    if (data.containsKey('shift_wed')) {
      context.handle(
        _shiftWedMeta,
        shiftWed.isAcceptableOrUnknown(data['shift_wed']!, _shiftWedMeta),
      );
    }
    if (data.containsKey('shift_thu')) {
      context.handle(
        _shiftThuMeta,
        shiftThu.isAcceptableOrUnknown(data['shift_thu']!, _shiftThuMeta),
      );
    }
    if (data.containsKey('shift_fri')) {
      context.handle(
        _shiftFriMeta,
        shiftFri.isAcceptableOrUnknown(data['shift_fri']!, _shiftFriMeta),
      );
    }
    if (data.containsKey('shift_sat')) {
      context.handle(
        _shiftSatMeta,
        shiftSat.isAcceptableOrUnknown(data['shift_sat']!, _shiftSatMeta),
      );
    }
    if (data.containsKey('shift_sun')) {
      context.handle(
        _shiftSunMeta,
        shiftSun.isAcceptableOrUnknown(data['shift_sun']!, _shiftSunMeta),
      );
    }
    if (data.containsKey('protein_value')) {
      context.handle(
        _proteinValueMeta,
        proteinValue.isAcceptableOrUnknown(
          data['protein_value']!,
          _proteinValueMeta,
        ),
      );
    }
    if (data.containsKey('protein_is_percent')) {
      context.handle(
        _proteinIsPercentMeta,
        proteinIsPercent.isAcceptableOrUnknown(
          data['protein_is_percent']!,
          _proteinIsPercentMeta,
        ),
      );
    }
    if (data.containsKey('fat_value')) {
      context.handle(
        _fatValueMeta,
        fatValue.isAcceptableOrUnknown(data['fat_value']!, _fatValueMeta),
      );
    }
    if (data.containsKey('fat_is_percent')) {
      context.handle(
        _fatIsPercentMeta,
        fatIsPercent.isAcceptableOrUnknown(
          data['fat_is_percent']!,
          _fatIsPercentMeta,
        ),
      );
    }
    if (data.containsKey('carbs_value')) {
      context.handle(
        _carbsValueMeta,
        carbsValue.isAcceptableOrUnknown(data['carbs_value']!, _carbsValueMeta),
      );
    }
    if (data.containsKey('carbs_is_percent')) {
      context.handle(
        _carbsIsPercentMeta,
        carbsIsPercent.isAcceptableOrUnknown(
          data['carbs_is_percent']!,
          _carbsIsPercentMeta,
        ),
      );
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    }
    if (data.containsKey('calories_protein_only')) {
      context.handle(
        _caloriesProteinOnlyMeta,
        caloriesProteinOnly.isAcceptableOrUnknown(
          data['calories_protein_only']!,
          _caloriesProteinOnlyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_caloriesProteinOnlyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TargetSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TargetSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_from'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      rebalancing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rebalancing'],
      )!,
      baseKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_kcal'],
      )!,
      manual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}manual'],
      )!,
      acknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}acknowledged'],
      )!,
      basisWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}basis_weight_kg'],
      )!,
      shiftMon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shift_mon'],
      ),
      shiftTue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shift_tue'],
      ),
      shiftWed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shift_wed'],
      ),
      shiftThu: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shift_thu'],
      ),
      shiftFri: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shift_fri'],
      ),
      shiftSat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shift_sat'],
      ),
      shiftSun: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}shift_sun'],
      ),
      proteinValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_value'],
      ),
      proteinIsPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}protein_is_percent'],
      ),
      fatValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_value'],
      ),
      fatIsPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fat_is_percent'],
      ),
      carbsValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_value'],
      ),
      carbsIsPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}carbs_is_percent'],
      ),
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      ),
      caloriesProteinOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}calories_protein_only'],
      )!,
    );
  }

  @override
  $TargetSettingsRowsTable createAlias(String alias) {
    return $TargetSettingsRowsTable(attachedDatabase, alias);
  }
}

class TargetSettingsRow extends DataClass
    implements Insertable<TargetSettingsRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The domain revision (≥ 1), separate from the row version.
  final int revision;

  /// The first day this version applies, `YYYY-MM-DD`.
  final String effectiveFrom;

  /// `weekly` or `fixed`.
  final String mode;

  /// Whether earlier intake rebalances the remaining days.
  final bool rebalancing;

  /// The daily base, kcal (generated or manual), unrounded.
  final double baseKcal;

  /// Whether the base is the user's own target.
  final bool manual;

  /// Whether the user acknowledged a below-limit manual target (SF-012).
  final bool acknowledged;

  /// The weight the base was computed with, kg.
  final double basisWeightKg;

  /// Monday's shifting weight; `null` = 1.0 (PA5).
  final double? shiftMon;

  /// Tuesday's shifting weight; `null` = 1.0.
  final double? shiftTue;

  /// Wednesday's shifting weight; `null` = 1.0.
  final double? shiftWed;

  /// Thursday's shifting weight; `null` = 1.0.
  final double? shiftThu;

  /// Friday's shifting weight; `null` = 1.0.
  final double? shiftFri;

  /// Saturday's shifting weight; `null` = 1.0.
  final double? shiftSat;

  /// Sunday's shifting weight; `null` = 1.0.
  final double? shiftSun;

  /// Protein override value (with [proteinIsPercent]), or `null`.
  final double? proteinValue;

  /// Whether [proteinValue] is a percent of base energy.
  final bool? proteinIsPercent;

  /// Fat override value (with [fatIsPercent]), or `null`.
  final double? fatValue;

  /// Whether [fatValue] is a percent of base energy.
  final bool? fatIsPercent;

  /// Carbs override value (with [carbsIsPercent]), or `null`.
  final double? carbsValue;

  /// Whether [carbsValue] is a percent of base energy.
  final bool? carbsIsPercent;

  /// Daily fiber, g, or `null` for the default.
  final double? fiberG;

  /// Whether fat and carbs have no targets (TG-054).
  final bool caloriesProteinOnly;
  const TargetSettingsRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.revision,
    required this.effectiveFrom,
    required this.mode,
    required this.rebalancing,
    required this.baseKcal,
    required this.manual,
    required this.acknowledged,
    required this.basisWeightKg,
    this.shiftMon,
    this.shiftTue,
    this.shiftWed,
    this.shiftThu,
    this.shiftFri,
    this.shiftSat,
    this.shiftSun,
    this.proteinValue,
    this.proteinIsPercent,
    this.fatValue,
    this.fatIsPercent,
    this.carbsValue,
    this.carbsIsPercent,
    this.fiberG,
    required this.caloriesProteinOnly,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['revision'] = Variable<int>(revision);
    map['effective_from'] = Variable<String>(effectiveFrom);
    map['mode'] = Variable<String>(mode);
    map['rebalancing'] = Variable<bool>(rebalancing);
    map['base_kcal'] = Variable<double>(baseKcal);
    map['manual'] = Variable<bool>(manual);
    map['acknowledged'] = Variable<bool>(acknowledged);
    map['basis_weight_kg'] = Variable<double>(basisWeightKg);
    if (!nullToAbsent || shiftMon != null) {
      map['shift_mon'] = Variable<double>(shiftMon);
    }
    if (!nullToAbsent || shiftTue != null) {
      map['shift_tue'] = Variable<double>(shiftTue);
    }
    if (!nullToAbsent || shiftWed != null) {
      map['shift_wed'] = Variable<double>(shiftWed);
    }
    if (!nullToAbsent || shiftThu != null) {
      map['shift_thu'] = Variable<double>(shiftThu);
    }
    if (!nullToAbsent || shiftFri != null) {
      map['shift_fri'] = Variable<double>(shiftFri);
    }
    if (!nullToAbsent || shiftSat != null) {
      map['shift_sat'] = Variable<double>(shiftSat);
    }
    if (!nullToAbsent || shiftSun != null) {
      map['shift_sun'] = Variable<double>(shiftSun);
    }
    if (!nullToAbsent || proteinValue != null) {
      map['protein_value'] = Variable<double>(proteinValue);
    }
    if (!nullToAbsent || proteinIsPercent != null) {
      map['protein_is_percent'] = Variable<bool>(proteinIsPercent);
    }
    if (!nullToAbsent || fatValue != null) {
      map['fat_value'] = Variable<double>(fatValue);
    }
    if (!nullToAbsent || fatIsPercent != null) {
      map['fat_is_percent'] = Variable<bool>(fatIsPercent);
    }
    if (!nullToAbsent || carbsValue != null) {
      map['carbs_value'] = Variable<double>(carbsValue);
    }
    if (!nullToAbsent || carbsIsPercent != null) {
      map['carbs_is_percent'] = Variable<bool>(carbsIsPercent);
    }
    if (!nullToAbsent || fiberG != null) {
      map['fiber_g'] = Variable<double>(fiberG);
    }
    map['calories_protein_only'] = Variable<bool>(caloriesProteinOnly);
    return map;
  }

  TargetSettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return TargetSettingsRowsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      revision: Value(revision),
      effectiveFrom: Value(effectiveFrom),
      mode: Value(mode),
      rebalancing: Value(rebalancing),
      baseKcal: Value(baseKcal),
      manual: Value(manual),
      acknowledged: Value(acknowledged),
      basisWeightKg: Value(basisWeightKg),
      shiftMon: shiftMon == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftMon),
      shiftTue: shiftTue == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftTue),
      shiftWed: shiftWed == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftWed),
      shiftThu: shiftThu == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftThu),
      shiftFri: shiftFri == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftFri),
      shiftSat: shiftSat == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftSat),
      shiftSun: shiftSun == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftSun),
      proteinValue: proteinValue == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinValue),
      proteinIsPercent: proteinIsPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinIsPercent),
      fatValue: fatValue == null && nullToAbsent
          ? const Value.absent()
          : Value(fatValue),
      fatIsPercent: fatIsPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(fatIsPercent),
      carbsValue: carbsValue == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsValue),
      carbsIsPercent: carbsIsPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsIsPercent),
      fiberG: fiberG == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberG),
      caloriesProteinOnly: Value(caloriesProteinOnly),
    );
  }

  factory TargetSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TargetSettingsRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      revision: serializer.fromJson<int>(json['revision']),
      effectiveFrom: serializer.fromJson<String>(json['effectiveFrom']),
      mode: serializer.fromJson<String>(json['mode']),
      rebalancing: serializer.fromJson<bool>(json['rebalancing']),
      baseKcal: serializer.fromJson<double>(json['baseKcal']),
      manual: serializer.fromJson<bool>(json['manual']),
      acknowledged: serializer.fromJson<bool>(json['acknowledged']),
      basisWeightKg: serializer.fromJson<double>(json['basisWeightKg']),
      shiftMon: serializer.fromJson<double?>(json['shiftMon']),
      shiftTue: serializer.fromJson<double?>(json['shiftTue']),
      shiftWed: serializer.fromJson<double?>(json['shiftWed']),
      shiftThu: serializer.fromJson<double?>(json['shiftThu']),
      shiftFri: serializer.fromJson<double?>(json['shiftFri']),
      shiftSat: serializer.fromJson<double?>(json['shiftSat']),
      shiftSun: serializer.fromJson<double?>(json['shiftSun']),
      proteinValue: serializer.fromJson<double?>(json['proteinValue']),
      proteinIsPercent: serializer.fromJson<bool?>(json['proteinIsPercent']),
      fatValue: serializer.fromJson<double?>(json['fatValue']),
      fatIsPercent: serializer.fromJson<bool?>(json['fatIsPercent']),
      carbsValue: serializer.fromJson<double?>(json['carbsValue']),
      carbsIsPercent: serializer.fromJson<bool?>(json['carbsIsPercent']),
      fiberG: serializer.fromJson<double?>(json['fiberG']),
      caloriesProteinOnly: serializer.fromJson<bool>(
        json['caloriesProteinOnly'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'revision': serializer.toJson<int>(revision),
      'effectiveFrom': serializer.toJson<String>(effectiveFrom),
      'mode': serializer.toJson<String>(mode),
      'rebalancing': serializer.toJson<bool>(rebalancing),
      'baseKcal': serializer.toJson<double>(baseKcal),
      'manual': serializer.toJson<bool>(manual),
      'acknowledged': serializer.toJson<bool>(acknowledged),
      'basisWeightKg': serializer.toJson<double>(basisWeightKg),
      'shiftMon': serializer.toJson<double?>(shiftMon),
      'shiftTue': serializer.toJson<double?>(shiftTue),
      'shiftWed': serializer.toJson<double?>(shiftWed),
      'shiftThu': serializer.toJson<double?>(shiftThu),
      'shiftFri': serializer.toJson<double?>(shiftFri),
      'shiftSat': serializer.toJson<double?>(shiftSat),
      'shiftSun': serializer.toJson<double?>(shiftSun),
      'proteinValue': serializer.toJson<double?>(proteinValue),
      'proteinIsPercent': serializer.toJson<bool?>(proteinIsPercent),
      'fatValue': serializer.toJson<double?>(fatValue),
      'fatIsPercent': serializer.toJson<bool?>(fatIsPercent),
      'carbsValue': serializer.toJson<double?>(carbsValue),
      'carbsIsPercent': serializer.toJson<bool?>(carbsIsPercent),
      'fiberG': serializer.toJson<double?>(fiberG),
      'caloriesProteinOnly': serializer.toJson<bool>(caloriesProteinOnly),
    };
  }

  TargetSettingsRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    int? revision,
    String? effectiveFrom,
    String? mode,
    bool? rebalancing,
    double? baseKcal,
    bool? manual,
    bool? acknowledged,
    double? basisWeightKg,
    Value<double?> shiftMon = const Value.absent(),
    Value<double?> shiftTue = const Value.absent(),
    Value<double?> shiftWed = const Value.absent(),
    Value<double?> shiftThu = const Value.absent(),
    Value<double?> shiftFri = const Value.absent(),
    Value<double?> shiftSat = const Value.absent(),
    Value<double?> shiftSun = const Value.absent(),
    Value<double?> proteinValue = const Value.absent(),
    Value<bool?> proteinIsPercent = const Value.absent(),
    Value<double?> fatValue = const Value.absent(),
    Value<bool?> fatIsPercent = const Value.absent(),
    Value<double?> carbsValue = const Value.absent(),
    Value<bool?> carbsIsPercent = const Value.absent(),
    Value<double?> fiberG = const Value.absent(),
    bool? caloriesProteinOnly,
  }) => TargetSettingsRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    revision: revision ?? this.revision,
    effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    mode: mode ?? this.mode,
    rebalancing: rebalancing ?? this.rebalancing,
    baseKcal: baseKcal ?? this.baseKcal,
    manual: manual ?? this.manual,
    acknowledged: acknowledged ?? this.acknowledged,
    basisWeightKg: basisWeightKg ?? this.basisWeightKg,
    shiftMon: shiftMon.present ? shiftMon.value : this.shiftMon,
    shiftTue: shiftTue.present ? shiftTue.value : this.shiftTue,
    shiftWed: shiftWed.present ? shiftWed.value : this.shiftWed,
    shiftThu: shiftThu.present ? shiftThu.value : this.shiftThu,
    shiftFri: shiftFri.present ? shiftFri.value : this.shiftFri,
    shiftSat: shiftSat.present ? shiftSat.value : this.shiftSat,
    shiftSun: shiftSun.present ? shiftSun.value : this.shiftSun,
    proteinValue: proteinValue.present ? proteinValue.value : this.proteinValue,
    proteinIsPercent: proteinIsPercent.present
        ? proteinIsPercent.value
        : this.proteinIsPercent,
    fatValue: fatValue.present ? fatValue.value : this.fatValue,
    fatIsPercent: fatIsPercent.present ? fatIsPercent.value : this.fatIsPercent,
    carbsValue: carbsValue.present ? carbsValue.value : this.carbsValue,
    carbsIsPercent: carbsIsPercent.present
        ? carbsIsPercent.value
        : this.carbsIsPercent,
    fiberG: fiberG.present ? fiberG.value : this.fiberG,
    caloriesProteinOnly: caloriesProteinOnly ?? this.caloriesProteinOnly,
  );
  TargetSettingsRow copyWithCompanion(TargetSettingsRowsCompanion data) {
    return TargetSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      revision: data.revision.present ? data.revision.value : this.revision,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      mode: data.mode.present ? data.mode.value : this.mode,
      rebalancing: data.rebalancing.present
          ? data.rebalancing.value
          : this.rebalancing,
      baseKcal: data.baseKcal.present ? data.baseKcal.value : this.baseKcal,
      manual: data.manual.present ? data.manual.value : this.manual,
      acknowledged: data.acknowledged.present
          ? data.acknowledged.value
          : this.acknowledged,
      basisWeightKg: data.basisWeightKg.present
          ? data.basisWeightKg.value
          : this.basisWeightKg,
      shiftMon: data.shiftMon.present ? data.shiftMon.value : this.shiftMon,
      shiftTue: data.shiftTue.present ? data.shiftTue.value : this.shiftTue,
      shiftWed: data.shiftWed.present ? data.shiftWed.value : this.shiftWed,
      shiftThu: data.shiftThu.present ? data.shiftThu.value : this.shiftThu,
      shiftFri: data.shiftFri.present ? data.shiftFri.value : this.shiftFri,
      shiftSat: data.shiftSat.present ? data.shiftSat.value : this.shiftSat,
      shiftSun: data.shiftSun.present ? data.shiftSun.value : this.shiftSun,
      proteinValue: data.proteinValue.present
          ? data.proteinValue.value
          : this.proteinValue,
      proteinIsPercent: data.proteinIsPercent.present
          ? data.proteinIsPercent.value
          : this.proteinIsPercent,
      fatValue: data.fatValue.present ? data.fatValue.value : this.fatValue,
      fatIsPercent: data.fatIsPercent.present
          ? data.fatIsPercent.value
          : this.fatIsPercent,
      carbsValue: data.carbsValue.present
          ? data.carbsValue.value
          : this.carbsValue,
      carbsIsPercent: data.carbsIsPercent.present
          ? data.carbsIsPercent.value
          : this.carbsIsPercent,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      caloriesProteinOnly: data.caloriesProteinOnly.present
          ? data.caloriesProteinOnly.value
          : this.caloriesProteinOnly,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TargetSettingsRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('revision: $revision, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('mode: $mode, ')
          ..write('rebalancing: $rebalancing, ')
          ..write('baseKcal: $baseKcal, ')
          ..write('manual: $manual, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('basisWeightKg: $basisWeightKg, ')
          ..write('shiftMon: $shiftMon, ')
          ..write('shiftTue: $shiftTue, ')
          ..write('shiftWed: $shiftWed, ')
          ..write('shiftThu: $shiftThu, ')
          ..write('shiftFri: $shiftFri, ')
          ..write('shiftSat: $shiftSat, ')
          ..write('shiftSun: $shiftSun, ')
          ..write('proteinValue: $proteinValue, ')
          ..write('proteinIsPercent: $proteinIsPercent, ')
          ..write('fatValue: $fatValue, ')
          ..write('fatIsPercent: $fatIsPercent, ')
          ..write('carbsValue: $carbsValue, ')
          ..write('carbsIsPercent: $carbsIsPercent, ')
          ..write('fiberG: $fiberG, ')
          ..write('caloriesProteinOnly: $caloriesProteinOnly')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    revision,
    effectiveFrom,
    mode,
    rebalancing,
    baseKcal,
    manual,
    acknowledged,
    basisWeightKg,
    shiftMon,
    shiftTue,
    shiftWed,
    shiftThu,
    shiftFri,
    shiftSat,
    shiftSun,
    proteinValue,
    proteinIsPercent,
    fatValue,
    fatIsPercent,
    carbsValue,
    carbsIsPercent,
    fiberG,
    caloriesProteinOnly,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TargetSettingsRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.revision == this.revision &&
          other.effectiveFrom == this.effectiveFrom &&
          other.mode == this.mode &&
          other.rebalancing == this.rebalancing &&
          other.baseKcal == this.baseKcal &&
          other.manual == this.manual &&
          other.acknowledged == this.acknowledged &&
          other.basisWeightKg == this.basisWeightKg &&
          other.shiftMon == this.shiftMon &&
          other.shiftTue == this.shiftTue &&
          other.shiftWed == this.shiftWed &&
          other.shiftThu == this.shiftThu &&
          other.shiftFri == this.shiftFri &&
          other.shiftSat == this.shiftSat &&
          other.shiftSun == this.shiftSun &&
          other.proteinValue == this.proteinValue &&
          other.proteinIsPercent == this.proteinIsPercent &&
          other.fatValue == this.fatValue &&
          other.fatIsPercent == this.fatIsPercent &&
          other.carbsValue == this.carbsValue &&
          other.carbsIsPercent == this.carbsIsPercent &&
          other.fiberG == this.fiberG &&
          other.caloriesProteinOnly == this.caloriesProteinOnly);
}

class TargetSettingsRowsCompanion extends UpdateCompanion<TargetSettingsRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<int> revision;
  final Value<String> effectiveFrom;
  final Value<String> mode;
  final Value<bool> rebalancing;
  final Value<double> baseKcal;
  final Value<bool> manual;
  final Value<bool> acknowledged;
  final Value<double> basisWeightKg;
  final Value<double?> shiftMon;
  final Value<double?> shiftTue;
  final Value<double?> shiftWed;
  final Value<double?> shiftThu;
  final Value<double?> shiftFri;
  final Value<double?> shiftSat;
  final Value<double?> shiftSun;
  final Value<double?> proteinValue;
  final Value<bool?> proteinIsPercent;
  final Value<double?> fatValue;
  final Value<bool?> fatIsPercent;
  final Value<double?> carbsValue;
  final Value<bool?> carbsIsPercent;
  final Value<double?> fiberG;
  final Value<bool> caloriesProteinOnly;
  final Value<int> rowid;
  const TargetSettingsRowsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.revision = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.mode = const Value.absent(),
    this.rebalancing = const Value.absent(),
    this.baseKcal = const Value.absent(),
    this.manual = const Value.absent(),
    this.acknowledged = const Value.absent(),
    this.basisWeightKg = const Value.absent(),
    this.shiftMon = const Value.absent(),
    this.shiftTue = const Value.absent(),
    this.shiftWed = const Value.absent(),
    this.shiftThu = const Value.absent(),
    this.shiftFri = const Value.absent(),
    this.shiftSat = const Value.absent(),
    this.shiftSun = const Value.absent(),
    this.proteinValue = const Value.absent(),
    this.proteinIsPercent = const Value.absent(),
    this.fatValue = const Value.absent(),
    this.fatIsPercent = const Value.absent(),
    this.carbsValue = const Value.absent(),
    this.carbsIsPercent = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.caloriesProteinOnly = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TargetSettingsRowsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required int revision,
    required String effectiveFrom,
    required String mode,
    required bool rebalancing,
    required double baseKcal,
    required bool manual,
    required bool acknowledged,
    required double basisWeightKg,
    this.shiftMon = const Value.absent(),
    this.shiftTue = const Value.absent(),
    this.shiftWed = const Value.absent(),
    this.shiftThu = const Value.absent(),
    this.shiftFri = const Value.absent(),
    this.shiftSat = const Value.absent(),
    this.shiftSun = const Value.absent(),
    this.proteinValue = const Value.absent(),
    this.proteinIsPercent = const Value.absent(),
    this.fatValue = const Value.absent(),
    this.fatIsPercent = const Value.absent(),
    this.carbsValue = const Value.absent(),
    this.carbsIsPercent = const Value.absent(),
    this.fiberG = const Value.absent(),
    required bool caloriesProteinOnly,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       revision = Value(revision),
       effectiveFrom = Value(effectiveFrom),
       mode = Value(mode),
       rebalancing = Value(rebalancing),
       baseKcal = Value(baseKcal),
       manual = Value(manual),
       acknowledged = Value(acknowledged),
       basisWeightKg = Value(basisWeightKg),
       caloriesProteinOnly = Value(caloriesProteinOnly);
  static Insertable<TargetSettingsRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<int>? revision,
    Expression<String>? effectiveFrom,
    Expression<String>? mode,
    Expression<bool>? rebalancing,
    Expression<double>? baseKcal,
    Expression<bool>? manual,
    Expression<bool>? acknowledged,
    Expression<double>? basisWeightKg,
    Expression<double>? shiftMon,
    Expression<double>? shiftTue,
    Expression<double>? shiftWed,
    Expression<double>? shiftThu,
    Expression<double>? shiftFri,
    Expression<double>? shiftSat,
    Expression<double>? shiftSun,
    Expression<double>? proteinValue,
    Expression<bool>? proteinIsPercent,
    Expression<double>? fatValue,
    Expression<bool>? fatIsPercent,
    Expression<double>? carbsValue,
    Expression<bool>? carbsIsPercent,
    Expression<double>? fiberG,
    Expression<bool>? caloriesProteinOnly,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (revision != null) 'revision': revision,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (mode != null) 'mode': mode,
      if (rebalancing != null) 'rebalancing': rebalancing,
      if (baseKcal != null) 'base_kcal': baseKcal,
      if (manual != null) 'manual': manual,
      if (acknowledged != null) 'acknowledged': acknowledged,
      if (basisWeightKg != null) 'basis_weight_kg': basisWeightKg,
      if (shiftMon != null) 'shift_mon': shiftMon,
      if (shiftTue != null) 'shift_tue': shiftTue,
      if (shiftWed != null) 'shift_wed': shiftWed,
      if (shiftThu != null) 'shift_thu': shiftThu,
      if (shiftFri != null) 'shift_fri': shiftFri,
      if (shiftSat != null) 'shift_sat': shiftSat,
      if (shiftSun != null) 'shift_sun': shiftSun,
      if (proteinValue != null) 'protein_value': proteinValue,
      if (proteinIsPercent != null) 'protein_is_percent': proteinIsPercent,
      if (fatValue != null) 'fat_value': fatValue,
      if (fatIsPercent != null) 'fat_is_percent': fatIsPercent,
      if (carbsValue != null) 'carbs_value': carbsValue,
      if (carbsIsPercent != null) 'carbs_is_percent': carbsIsPercent,
      if (fiberG != null) 'fiber_g': fiberG,
      if (caloriesProteinOnly != null)
        'calories_protein_only': caloriesProteinOnly,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TargetSettingsRowsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<int>? revision,
    Value<String>? effectiveFrom,
    Value<String>? mode,
    Value<bool>? rebalancing,
    Value<double>? baseKcal,
    Value<bool>? manual,
    Value<bool>? acknowledged,
    Value<double>? basisWeightKg,
    Value<double?>? shiftMon,
    Value<double?>? shiftTue,
    Value<double?>? shiftWed,
    Value<double?>? shiftThu,
    Value<double?>? shiftFri,
    Value<double?>? shiftSat,
    Value<double?>? shiftSun,
    Value<double?>? proteinValue,
    Value<bool?>? proteinIsPercent,
    Value<double?>? fatValue,
    Value<bool?>? fatIsPercent,
    Value<double?>? carbsValue,
    Value<bool?>? carbsIsPercent,
    Value<double?>? fiberG,
    Value<bool>? caloriesProteinOnly,
    Value<int>? rowid,
  }) {
    return TargetSettingsRowsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      revision: revision ?? this.revision,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      mode: mode ?? this.mode,
      rebalancing: rebalancing ?? this.rebalancing,
      baseKcal: baseKcal ?? this.baseKcal,
      manual: manual ?? this.manual,
      acknowledged: acknowledged ?? this.acknowledged,
      basisWeightKg: basisWeightKg ?? this.basisWeightKg,
      shiftMon: shiftMon ?? this.shiftMon,
      shiftTue: shiftTue ?? this.shiftTue,
      shiftWed: shiftWed ?? this.shiftWed,
      shiftThu: shiftThu ?? this.shiftThu,
      shiftFri: shiftFri ?? this.shiftFri,
      shiftSat: shiftSat ?? this.shiftSat,
      shiftSun: shiftSun ?? this.shiftSun,
      proteinValue: proteinValue ?? this.proteinValue,
      proteinIsPercent: proteinIsPercent ?? this.proteinIsPercent,
      fatValue: fatValue ?? this.fatValue,
      fatIsPercent: fatIsPercent ?? this.fatIsPercent,
      carbsValue: carbsValue ?? this.carbsValue,
      carbsIsPercent: carbsIsPercent ?? this.carbsIsPercent,
      fiberG: fiberG ?? this.fiberG,
      caloriesProteinOnly: caloriesProteinOnly ?? this.caloriesProteinOnly,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<String>(effectiveFrom.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (rebalancing.present) {
      map['rebalancing'] = Variable<bool>(rebalancing.value);
    }
    if (baseKcal.present) {
      map['base_kcal'] = Variable<double>(baseKcal.value);
    }
    if (manual.present) {
      map['manual'] = Variable<bool>(manual.value);
    }
    if (acknowledged.present) {
      map['acknowledged'] = Variable<bool>(acknowledged.value);
    }
    if (basisWeightKg.present) {
      map['basis_weight_kg'] = Variable<double>(basisWeightKg.value);
    }
    if (shiftMon.present) {
      map['shift_mon'] = Variable<double>(shiftMon.value);
    }
    if (shiftTue.present) {
      map['shift_tue'] = Variable<double>(shiftTue.value);
    }
    if (shiftWed.present) {
      map['shift_wed'] = Variable<double>(shiftWed.value);
    }
    if (shiftThu.present) {
      map['shift_thu'] = Variable<double>(shiftThu.value);
    }
    if (shiftFri.present) {
      map['shift_fri'] = Variable<double>(shiftFri.value);
    }
    if (shiftSat.present) {
      map['shift_sat'] = Variable<double>(shiftSat.value);
    }
    if (shiftSun.present) {
      map['shift_sun'] = Variable<double>(shiftSun.value);
    }
    if (proteinValue.present) {
      map['protein_value'] = Variable<double>(proteinValue.value);
    }
    if (proteinIsPercent.present) {
      map['protein_is_percent'] = Variable<bool>(proteinIsPercent.value);
    }
    if (fatValue.present) {
      map['fat_value'] = Variable<double>(fatValue.value);
    }
    if (fatIsPercent.present) {
      map['fat_is_percent'] = Variable<bool>(fatIsPercent.value);
    }
    if (carbsValue.present) {
      map['carbs_value'] = Variable<double>(carbsValue.value);
    }
    if (carbsIsPercent.present) {
      map['carbs_is_percent'] = Variable<bool>(carbsIsPercent.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (caloriesProteinOnly.present) {
      map['calories_protein_only'] = Variable<bool>(caloriesProteinOnly.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TargetSettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('revision: $revision, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('mode: $mode, ')
          ..write('rebalancing: $rebalancing, ')
          ..write('baseKcal: $baseKcal, ')
          ..write('manual: $manual, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('basisWeightKg: $basisWeightKg, ')
          ..write('shiftMon: $shiftMon, ')
          ..write('shiftTue: $shiftTue, ')
          ..write('shiftWed: $shiftWed, ')
          ..write('shiftThu: $shiftThu, ')
          ..write('shiftFri: $shiftFri, ')
          ..write('shiftSat: $shiftSat, ')
          ..write('shiftSun: $shiftSun, ')
          ..write('proteinValue: $proteinValue, ')
          ..write('proteinIsPercent: $proteinIsPercent, ')
          ..write('fatValue: $fatValue, ')
          ..write('fatIsPercent: $fatIsPercent, ')
          ..write('carbsValue: $carbsValue, ')
          ..write('carbsIsPercent: $carbsIsPercent, ')
          ..write('fiberG: $fiberG, ')
          ..write('caloriesProteinOnly: $caloriesProteinOnly, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthYearMeta = const VerificationMeta(
    'birthYear',
  );
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
    'birth_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightInputUnitMeta = const VerificationMeta(
    'heightInputUnit',
  );
  @override
  late final GeneratedColumn<String> heightInputUnit = GeneratedColumn<String>(
    'height_input_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityMeta = const VerificationMeta(
    'activity',
  );
  @override
  late final GeneratedColumn<String> activity = GeneratedColumn<String>(
    'activity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    sex,
    birthYear,
    heightCm,
    heightInputUnit,
    activity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('birth_year')) {
      context.handle(
        _birthYearMeta,
        birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta),
      );
    } else if (isInserting) {
      context.missing(_birthYearMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('height_input_unit')) {
      context.handle(
        _heightInputUnitMeta,
        heightInputUnit.isAcceptableOrUnknown(
          data['height_input_unit']!,
          _heightInputUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_heightInputUnitMeta);
    }
    if (data.containsKey('activity')) {
      context.handle(
        _activityMeta,
        activity.isAcceptableOrUnknown(data['activity']!, _activityMeta),
      );
    } else if (isInserting) {
      context.missing(_activityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      )!,
      birthYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_year'],
      )!,
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      heightInputUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}height_input_unit'],
      )!,
      activity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// `male` or `female`.
  final String sex;

  /// Birth year (age = evaluation year − this).
  final int birthYear;

  /// Height, cm.
  final double heightCm;

  /// How the height was typed: `cm` or `ft_in` (TD-017).
  final String heightInputUnit;

  /// `sedentary`, `light`, `moderate` or `high`.
  final String activity;
  const ProfileRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.sex,
    required this.birthYear,
    required this.heightCm,
    required this.heightInputUnit,
    required this.activity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['sex'] = Variable<String>(sex);
    map['birth_year'] = Variable<int>(birthYear);
    map['height_cm'] = Variable<double>(heightCm);
    map['height_input_unit'] = Variable<String>(heightInputUnit);
    map['activity'] = Variable<String>(activity);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      sex: Value(sex),
      birthYear: Value(birthYear),
      heightCm: Value(heightCm),
      heightInputUnit: Value(heightInputUnit),
      activity: Value(activity),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      sex: serializer.fromJson<String>(json['sex']),
      birthYear: serializer.fromJson<int>(json['birthYear']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      heightInputUnit: serializer.fromJson<String>(json['heightInputUnit']),
      activity: serializer.fromJson<String>(json['activity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'sex': serializer.toJson<String>(sex),
      'birthYear': serializer.toJson<int>(birthYear),
      'heightCm': serializer.toJson<double>(heightCm),
      'heightInputUnit': serializer.toJson<String>(heightInputUnit),
      'activity': serializer.toJson<String>(activity),
    };
  }

  ProfileRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? sex,
    int? birthYear,
    double? heightCm,
    String? heightInputUnit,
    String? activity,
  }) => ProfileRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    sex: sex ?? this.sex,
    birthYear: birthYear ?? this.birthYear,
    heightCm: heightCm ?? this.heightCm,
    heightInputUnit: heightInputUnit ?? this.heightInputUnit,
    activity: activity ?? this.activity,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      sex: data.sex.present ? data.sex.value : this.sex,
      birthYear: data.birthYear.present ? data.birthYear.value : this.birthYear,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      heightInputUnit: data.heightInputUnit.present
          ? data.heightInputUnit.value
          : this.heightInputUnit,
      activity: data.activity.present ? data.activity.value : this.activity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('sex: $sex, ')
          ..write('birthYear: $birthYear, ')
          ..write('heightCm: $heightCm, ')
          ..write('heightInputUnit: $heightInputUnit, ')
          ..write('activity: $activity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    sex,
    birthYear,
    heightCm,
    heightInputUnit,
    activity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.sex == this.sex &&
          other.birthYear == this.birthYear &&
          other.heightCm == this.heightCm &&
          other.heightInputUnit == this.heightInputUnit &&
          other.activity == this.activity);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> sex;
  final Value<int> birthYear;
  final Value<double> heightCm;
  final Value<String> heightInputUnit;
  final Value<String> activity;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.sex = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.heightInputUnit = const Value.absent(),
    this.activity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String sex,
    required int birthYear,
    required double heightCm,
    required String heightInputUnit,
    required String activity,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       sex = Value(sex),
       birthYear = Value(birthYear),
       heightCm = Value(heightCm),
       heightInputUnit = Value(heightInputUnit),
       activity = Value(activity);
  static Insertable<ProfileRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? sex,
    Expression<int>? birthYear,
    Expression<double>? heightCm,
    Expression<String>? heightInputUnit,
    Expression<String>? activity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (sex != null) 'sex': sex,
      if (birthYear != null) 'birth_year': birthYear,
      if (heightCm != null) 'height_cm': heightCm,
      if (heightInputUnit != null) 'height_input_unit': heightInputUnit,
      if (activity != null) 'activity': activity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? sex,
    Value<int>? birthYear,
    Value<double>? heightCm,
    Value<String>? heightInputUnit,
    Value<String>? activity,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      sex: sex ?? this.sex,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      heightInputUnit: heightInputUnit ?? this.heightInputUnit,
      activity: activity ?? this.activity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (heightInputUnit.present) {
      map['height_input_unit'] = Variable<String>(heightInputUnit.value);
    }
    if (activity.present) {
      map['activity'] = Variable<String>(activity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('sex: $sex, ')
          ..write('birthYear: $birthYear, ')
          ..write('heightCm: $heightCm, ')
          ..write('heightInputUnit: $heightInputUnit, ')
          ..write('activity: $activity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiaryEntriesTable extends DiaryEntries
    with TableInfo<$DiaryEntriesTable, DiaryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _foodKindMeta = const VerificationMeta(
    'foodKind',
  );
  @override
  late final GeneratedColumn<String> foodKind = GeneratedColumn<String>(
    'food_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foodVersionMeta = const VerificationMeta(
    'foodVersion',
  );
  @override
  late final GeneratedColumn<String> foodVersion = GeneratedColumn<String>(
    'food_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputAmountMeta = const VerificationMeta(
    'inputAmount',
  );
  @override
  late final GeneratedColumn<double> inputAmount = GeneratedColumn<double>(
    'input_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputUnitMeta = const VerificationMeta(
    'inputUnit',
  );
  @override
  late final GeneratedColumn<String> inputUnit = GeneratedColumn<String>(
    'input_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountBasisMeta = const VerificationMeta(
    'amountBasis',
  );
  @override
  late final GeneratedColumn<String> amountBasis = GeneratedColumn<String>(
    'amount_basis',
    aliasedName,
    false,
    check: () => amountBasis.isIn(const ['g', 'ml']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100KcalMeta = const VerificationMeta(
    'per100Kcal',
  );
  @override
  late final GeneratedColumn<double> per100Kcal = GeneratedColumn<double>(
    'per100_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100ProteinGMeta = const VerificationMeta(
    'per100ProteinG',
  );
  @override
  late final GeneratedColumn<double> per100ProteinG = GeneratedColumn<double>(
    'per100_protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100CarbsGMeta = const VerificationMeta(
    'per100CarbsG',
  );
  @override
  late final GeneratedColumn<double> per100CarbsG = GeneratedColumn<double>(
    'per100_carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100FatGMeta = const VerificationMeta(
    'per100FatG',
  );
  @override
  late final GeneratedColumn<double> per100FatG = GeneratedColumn<double>(
    'per100_fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100FiberGMeta = const VerificationMeta(
    'per100FiberG',
  );
  @override
  late final GeneratedColumn<double> per100FiberG = GeneratedColumn<double>(
    'per100_fiber_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100ExtrasJsonMeta = const VerificationMeta(
    'per100ExtrasJson',
  );
  @override
  late final GeneratedColumn<String> per100ExtrasJson = GeneratedColumn<String>(
    'per100_extras_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    check: () => ComparableExpr(kcal).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    check: () => ComparableExpr(proteinG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    check: () => ComparableExpr(carbsG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    check: () => ComparableExpr(fatG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    false,
    check: () => ComparableExpr(fiberG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extrasJsonMeta = const VerificationMeta(
    'extrasJson',
  );
  @override
  late final GeneratedColumn<String> extrasJson = GeneratedColumn<String>(
    'extras_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEstimateMeta = const VerificationMeta(
    'isEstimate',
  );
  @override
  late final GeneratedColumn<bool> isEstimate = GeneratedColumn<bool>(
    'is_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimate" IN (0, 1))',
    ),
  );
  static const VerificationMeta _estimateRangeJsonMeta = const VerificationMeta(
    'estimateRangeJson',
  );
  @override
  late final GeneratedColumn<String> estimateRangeJson =
      GeneratedColumn<String>(
        'estimate_range_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _assumptionsJsonMeta = const VerificationMeta(
    'assumptionsJson',
  );
  @override
  late final GeneratedColumn<String> assumptionsJson = GeneratedColumn<String>(
    'assumptions_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtUtcMeta = const VerificationMeta(
    'occurredAtUtc',
  );
  @override
  late final GeneratedColumn<int> occurredAtUtc = GeneratedColumn<int>(
    'occurred_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinMeta = const VerificationMeta(
    'tzOffsetMin',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMin = GeneratedColumn<int>(
    'tz_offset_min',
    aliasedName,
    false,
    check: () => ComparableExpr(tzOffsetMin).isBetweenValues(-720, 840),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotIdMeta = const VerificationMeta('slotId');
  @override
  late final GeneratedColumn<String> slotId = GeneratedColumn<String>(
    'slot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dishGroupIdMeta = const VerificationMeta(
    'dishGroupId',
  );
  @override
  late final GeneratedColumn<String> dishGroupId = GeneratedColumn<String>(
    'dish_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    foodKind,
    foodId,
    foodVersion,
    nameEn,
    nameAr,
    inputAmount,
    inputUnit,
    amount,
    amountBasis,
    per100Kcal,
    per100ProteinG,
    per100CarbsG,
    per100FatG,
    per100FiberG,
    per100ExtrasJson,
    kcal,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    extrasJson,
    source,
    isEstimate,
    estimateRangeJson,
    assumptionsJson,
    localDate,
    occurredAtUtc,
    tzOffsetMin,
    slotId,
    dishGroupId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiaryEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('food_kind')) {
      context.handle(
        _foodKindMeta,
        foodKind.isAcceptableOrUnknown(data['food_kind']!, _foodKindMeta),
      );
    } else if (isInserting) {
      context.missing(_foodKindMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('food_version')) {
      context.handle(
        _foodVersionMeta,
        foodVersion.isAcceptableOrUnknown(
          data['food_version']!,
          _foodVersionMeta,
        ),
      );
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    }
    if (data.containsKey('input_amount')) {
      context.handle(
        _inputAmountMeta,
        inputAmount.isAcceptableOrUnknown(
          data['input_amount']!,
          _inputAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputAmountMeta);
    }
    if (data.containsKey('input_unit')) {
      context.handle(
        _inputUnitMeta,
        inputUnit.isAcceptableOrUnknown(data['input_unit']!, _inputUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_inputUnitMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('amount_basis')) {
      context.handle(
        _amountBasisMeta,
        amountBasis.isAcceptableOrUnknown(
          data['amount_basis']!,
          _amountBasisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountBasisMeta);
    }
    if (data.containsKey('per100_kcal')) {
      context.handle(
        _per100KcalMeta,
        per100Kcal.isAcceptableOrUnknown(data['per100_kcal']!, _per100KcalMeta),
      );
    } else if (isInserting) {
      context.missing(_per100KcalMeta);
    }
    if (data.containsKey('per100_protein_g')) {
      context.handle(
        _per100ProteinGMeta,
        per100ProteinG.isAcceptableOrUnknown(
          data['per100_protein_g']!,
          _per100ProteinGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100ProteinGMeta);
    }
    if (data.containsKey('per100_carbs_g')) {
      context.handle(
        _per100CarbsGMeta,
        per100CarbsG.isAcceptableOrUnknown(
          data['per100_carbs_g']!,
          _per100CarbsGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100CarbsGMeta);
    }
    if (data.containsKey('per100_fat_g')) {
      context.handle(
        _per100FatGMeta,
        per100FatG.isAcceptableOrUnknown(
          data['per100_fat_g']!,
          _per100FatGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100FatGMeta);
    }
    if (data.containsKey('per100_fiber_g')) {
      context.handle(
        _per100FiberGMeta,
        per100FiberG.isAcceptableOrUnknown(
          data['per100_fiber_g']!,
          _per100FiberGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100FiberGMeta);
    }
    if (data.containsKey('per100_extras_json')) {
      context.handle(
        _per100ExtrasJsonMeta,
        per100ExtrasJson.isAcceptableOrUnknown(
          data['per100_extras_json']!,
          _per100ExtrasJsonMeta,
        ),
      );
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    } else if (isInserting) {
      context.missing(_fiberGMeta);
    }
    if (data.containsKey('extras_json')) {
      context.handle(
        _extrasJsonMeta,
        extrasJson.isAcceptableOrUnknown(data['extras_json']!, _extrasJsonMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('is_estimate')) {
      context.handle(
        _isEstimateMeta,
        isEstimate.isAcceptableOrUnknown(data['is_estimate']!, _isEstimateMeta),
      );
    } else if (isInserting) {
      context.missing(_isEstimateMeta);
    }
    if (data.containsKey('estimate_range_json')) {
      context.handle(
        _estimateRangeJsonMeta,
        estimateRangeJson.isAcceptableOrUnknown(
          data['estimate_range_json']!,
          _estimateRangeJsonMeta,
        ),
      );
    }
    if (data.containsKey('assumptions_json')) {
      context.handle(
        _assumptionsJsonMeta,
        assumptionsJson.isAcceptableOrUnknown(
          data['assumptions_json']!,
          _assumptionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
        _occurredAtUtcMeta,
        occurredAtUtc.isAcceptableOrUnknown(
          data['occurred_at_utc']!,
          _occurredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('tz_offset_min')) {
      context.handle(
        _tzOffsetMinMeta,
        tzOffsetMin.isAcceptableOrUnknown(
          data['tz_offset_min']!,
          _tzOffsetMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinMeta);
    }
    if (data.containsKey('slot_id')) {
      context.handle(
        _slotIdMeta,
        slotId.isAcceptableOrUnknown(data['slot_id']!, _slotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_slotIdMeta);
    }
    if (data.containsKey('dish_group_id')) {
      context.handle(
        _dishGroupIdMeta,
        dishGroupId.isAcceptableOrUnknown(
          data['dish_group_id']!,
          _dishGroupIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiaryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      foodKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_kind'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      ),
      foodVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_version'],
      ),
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      ),
      inputAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}input_amount'],
      )!,
      inputUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_unit'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      amountBasis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_basis'],
      )!,
      per100Kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_kcal'],
      )!,
      per100ProteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_protein_g'],
      )!,
      per100CarbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_carbs_g'],
      )!,
      per100FatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_fat_g'],
      )!,
      per100FiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_fiber_g'],
      )!,
      per100ExtrasJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}per100_extras_json'],
      ),
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      )!,
      extrasJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extras_json'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      isEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimate'],
      )!,
      estimateRangeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estimate_range_json'],
      ),
      assumptionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assumptions_json'],
      ),
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at_utc'],
      )!,
      tzOffsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_min'],
      )!,
      slotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot_id'],
      )!,
      dishGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dish_group_id'],
      ),
    );
  }

  @override
  $DiaryEntriesTable createAlias(String alias) {
    return $DiaryEntriesTable(attachedDatabase, alias);
  }
}

class DiaryEntryRow extends DataClass implements Insertable<DiaryEntryRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// `catalog`, `personal`, `estimate` (A27 adds `batch`).
  final String foodKind;

  /// The food's opaque id, `null` for an estimate.
  final String? foodId;

  /// The catalog pack version at log time (opaque), or `null`.
  final String? foodVersion;

  /// The English name. User or catalog content.
  final String nameEn;

  /// The Arabic name, when there is one.
  final String? nameAr;

  /// The amount as typed.
  final double inputAmount;

  /// The unit as typed.
  final String inputUnit;

  /// The canonical amount, grams or ml.
  final double amount;

  /// `g` or `ml`.
  final String amountBasis;

  /// Per-100 kcal.
  final double per100Kcal;

  /// Per-100 protein, g.
  final double per100ProteinG;

  /// Per-100 carbs, g.
  final double per100CarbsG;

  /// Per-100 fat, g.
  final double per100FatG;

  /// Per-100 fiber, g.
  final double per100FiberG;

  /// Per-100 extras as JSON (`{"sugar": 1.2}`), or `null`.
  final String? per100ExtrasJson;

  /// The snapshot kcal for [amount].
  final double kcal;

  /// The snapshot protein, g.
  final double proteinG;

  /// The snapshot carbs, g.
  final double carbsG;

  /// The snapshot fat, g.
  final double fatG;

  /// The snapshot fiber, g.
  final double fiberG;

  /// The snapshot extras as JSON, or `null`.
  final String? extrasJson;

  /// The badge: `yours`, `database`, `reference`, `estimate`.
  final String source;

  /// Whether the values are estimated.
  final bool isEstimate;

  /// `{"lowKcal": …, "highKcal": …}` for an estimate with a range.
  final String? estimateRangeJson;

  /// The assumptions behind the values, a JSON list of strings.
  final String? assumptionsJson;

  /// The diary day, `YYYY-MM-DD`; fixed at log time from the stored offset
  /// (DY-002).
  final String localDate;

  /// When it was eaten, UTC ms.
  final int occurredAtUtc;

  /// The zone offset where it was eaten, minutes ahead of UTC.
  final int tzOffsetMin;

  /// The meal slot's id.
  final String slotId;

  /// The dish group's id, or `null`.
  final String? dishGroupId;
  const DiaryEntryRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.foodKind,
    this.foodId,
    this.foodVersion,
    required this.nameEn,
    this.nameAr,
    required this.inputAmount,
    required this.inputUnit,
    required this.amount,
    required this.amountBasis,
    required this.per100Kcal,
    required this.per100ProteinG,
    required this.per100CarbsG,
    required this.per100FatG,
    required this.per100FiberG,
    this.per100ExtrasJson,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    this.extrasJson,
    required this.source,
    required this.isEstimate,
    this.estimateRangeJson,
    this.assumptionsJson,
    required this.localDate,
    required this.occurredAtUtc,
    required this.tzOffsetMin,
    required this.slotId,
    this.dishGroupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['food_kind'] = Variable<String>(foodKind);
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<String>(foodId);
    }
    if (!nullToAbsent || foodVersion != null) {
      map['food_version'] = Variable<String>(foodVersion);
    }
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || nameAr != null) {
      map['name_ar'] = Variable<String>(nameAr);
    }
    map['input_amount'] = Variable<double>(inputAmount);
    map['input_unit'] = Variable<String>(inputUnit);
    map['amount'] = Variable<double>(amount);
    map['amount_basis'] = Variable<String>(amountBasis);
    map['per100_kcal'] = Variable<double>(per100Kcal);
    map['per100_protein_g'] = Variable<double>(per100ProteinG);
    map['per100_carbs_g'] = Variable<double>(per100CarbsG);
    map['per100_fat_g'] = Variable<double>(per100FatG);
    map['per100_fiber_g'] = Variable<double>(per100FiberG);
    if (!nullToAbsent || per100ExtrasJson != null) {
      map['per100_extras_json'] = Variable<String>(per100ExtrasJson);
    }
    map['kcal'] = Variable<double>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    map['fiber_g'] = Variable<double>(fiberG);
    if (!nullToAbsent || extrasJson != null) {
      map['extras_json'] = Variable<String>(extrasJson);
    }
    map['source'] = Variable<String>(source);
    map['is_estimate'] = Variable<bool>(isEstimate);
    if (!nullToAbsent || estimateRangeJson != null) {
      map['estimate_range_json'] = Variable<String>(estimateRangeJson);
    }
    if (!nullToAbsent || assumptionsJson != null) {
      map['assumptions_json'] = Variable<String>(assumptionsJson);
    }
    map['local_date'] = Variable<String>(localDate);
    map['occurred_at_utc'] = Variable<int>(occurredAtUtc);
    map['tz_offset_min'] = Variable<int>(tzOffsetMin);
    map['slot_id'] = Variable<String>(slotId);
    if (!nullToAbsent || dishGroupId != null) {
      map['dish_group_id'] = Variable<String>(dishGroupId);
    }
    return map;
  }

  DiaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DiaryEntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      foodKind: Value(foodKind),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      foodVersion: foodVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(foodVersion),
      nameEn: Value(nameEn),
      nameAr: nameAr == null && nullToAbsent
          ? const Value.absent()
          : Value(nameAr),
      inputAmount: Value(inputAmount),
      inputUnit: Value(inputUnit),
      amount: Value(amount),
      amountBasis: Value(amountBasis),
      per100Kcal: Value(per100Kcal),
      per100ProteinG: Value(per100ProteinG),
      per100CarbsG: Value(per100CarbsG),
      per100FatG: Value(per100FatG),
      per100FiberG: Value(per100FiberG),
      per100ExtrasJson: per100ExtrasJson == null && nullToAbsent
          ? const Value.absent()
          : Value(per100ExtrasJson),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      fiberG: Value(fiberG),
      extrasJson: extrasJson == null && nullToAbsent
          ? const Value.absent()
          : Value(extrasJson),
      source: Value(source),
      isEstimate: Value(isEstimate),
      estimateRangeJson: estimateRangeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateRangeJson),
      assumptionsJson: assumptionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(assumptionsJson),
      localDate: Value(localDate),
      occurredAtUtc: Value(occurredAtUtc),
      tzOffsetMin: Value(tzOffsetMin),
      slotId: Value(slotId),
      dishGroupId: dishGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(dishGroupId),
    );
  }

  factory DiaryEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryEntryRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      foodKind: serializer.fromJson<String>(json['foodKind']),
      foodId: serializer.fromJson<String?>(json['foodId']),
      foodVersion: serializer.fromJson<String?>(json['foodVersion']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameAr: serializer.fromJson<String?>(json['nameAr']),
      inputAmount: serializer.fromJson<double>(json['inputAmount']),
      inputUnit: serializer.fromJson<String>(json['inputUnit']),
      amount: serializer.fromJson<double>(json['amount']),
      amountBasis: serializer.fromJson<String>(json['amountBasis']),
      per100Kcal: serializer.fromJson<double>(json['per100Kcal']),
      per100ProteinG: serializer.fromJson<double>(json['per100ProteinG']),
      per100CarbsG: serializer.fromJson<double>(json['per100CarbsG']),
      per100FatG: serializer.fromJson<double>(json['per100FatG']),
      per100FiberG: serializer.fromJson<double>(json['per100FiberG']),
      per100ExtrasJson: serializer.fromJson<String?>(json['per100ExtrasJson']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      fiberG: serializer.fromJson<double>(json['fiberG']),
      extrasJson: serializer.fromJson<String?>(json['extrasJson']),
      source: serializer.fromJson<String>(json['source']),
      isEstimate: serializer.fromJson<bool>(json['isEstimate']),
      estimateRangeJson: serializer.fromJson<String?>(
        json['estimateRangeJson'],
      ),
      assumptionsJson: serializer.fromJson<String?>(json['assumptionsJson']),
      localDate: serializer.fromJson<String>(json['localDate']),
      occurredAtUtc: serializer.fromJson<int>(json['occurredAtUtc']),
      tzOffsetMin: serializer.fromJson<int>(json['tzOffsetMin']),
      slotId: serializer.fromJson<String>(json['slotId']),
      dishGroupId: serializer.fromJson<String?>(json['dishGroupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'foodKind': serializer.toJson<String>(foodKind),
      'foodId': serializer.toJson<String?>(foodId),
      'foodVersion': serializer.toJson<String?>(foodVersion),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameAr': serializer.toJson<String?>(nameAr),
      'inputAmount': serializer.toJson<double>(inputAmount),
      'inputUnit': serializer.toJson<String>(inputUnit),
      'amount': serializer.toJson<double>(amount),
      'amountBasis': serializer.toJson<String>(amountBasis),
      'per100Kcal': serializer.toJson<double>(per100Kcal),
      'per100ProteinG': serializer.toJson<double>(per100ProteinG),
      'per100CarbsG': serializer.toJson<double>(per100CarbsG),
      'per100FatG': serializer.toJson<double>(per100FatG),
      'per100FiberG': serializer.toJson<double>(per100FiberG),
      'per100ExtrasJson': serializer.toJson<String?>(per100ExtrasJson),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'fiberG': serializer.toJson<double>(fiberG),
      'extrasJson': serializer.toJson<String?>(extrasJson),
      'source': serializer.toJson<String>(source),
      'isEstimate': serializer.toJson<bool>(isEstimate),
      'estimateRangeJson': serializer.toJson<String?>(estimateRangeJson),
      'assumptionsJson': serializer.toJson<String?>(assumptionsJson),
      'localDate': serializer.toJson<String>(localDate),
      'occurredAtUtc': serializer.toJson<int>(occurredAtUtc),
      'tzOffsetMin': serializer.toJson<int>(tzOffsetMin),
      'slotId': serializer.toJson<String>(slotId),
      'dishGroupId': serializer.toJson<String?>(dishGroupId),
    };
  }

  DiaryEntryRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? foodKind,
    Value<String?> foodId = const Value.absent(),
    Value<String?> foodVersion = const Value.absent(),
    String? nameEn,
    Value<String?> nameAr = const Value.absent(),
    double? inputAmount,
    String? inputUnit,
    double? amount,
    String? amountBasis,
    double? per100Kcal,
    double? per100ProteinG,
    double? per100CarbsG,
    double? per100FatG,
    double? per100FiberG,
    Value<String?> per100ExtrasJson = const Value.absent(),
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    Value<String?> extrasJson = const Value.absent(),
    String? source,
    bool? isEstimate,
    Value<String?> estimateRangeJson = const Value.absent(),
    Value<String?> assumptionsJson = const Value.absent(),
    String? localDate,
    int? occurredAtUtc,
    int? tzOffsetMin,
    String? slotId,
    Value<String?> dishGroupId = const Value.absent(),
  }) => DiaryEntryRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    foodKind: foodKind ?? this.foodKind,
    foodId: foodId.present ? foodId.value : this.foodId,
    foodVersion: foodVersion.present ? foodVersion.value : this.foodVersion,
    nameEn: nameEn ?? this.nameEn,
    nameAr: nameAr.present ? nameAr.value : this.nameAr,
    inputAmount: inputAmount ?? this.inputAmount,
    inputUnit: inputUnit ?? this.inputUnit,
    amount: amount ?? this.amount,
    amountBasis: amountBasis ?? this.amountBasis,
    per100Kcal: per100Kcal ?? this.per100Kcal,
    per100ProteinG: per100ProteinG ?? this.per100ProteinG,
    per100CarbsG: per100CarbsG ?? this.per100CarbsG,
    per100FatG: per100FatG ?? this.per100FatG,
    per100FiberG: per100FiberG ?? this.per100FiberG,
    per100ExtrasJson: per100ExtrasJson.present
        ? per100ExtrasJson.value
        : this.per100ExtrasJson,
    kcal: kcal ?? this.kcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    fiberG: fiberG ?? this.fiberG,
    extrasJson: extrasJson.present ? extrasJson.value : this.extrasJson,
    source: source ?? this.source,
    isEstimate: isEstimate ?? this.isEstimate,
    estimateRangeJson: estimateRangeJson.present
        ? estimateRangeJson.value
        : this.estimateRangeJson,
    assumptionsJson: assumptionsJson.present
        ? assumptionsJson.value
        : this.assumptionsJson,
    localDate: localDate ?? this.localDate,
    occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
    tzOffsetMin: tzOffsetMin ?? this.tzOffsetMin,
    slotId: slotId ?? this.slotId,
    dishGroupId: dishGroupId.present ? dishGroupId.value : this.dishGroupId,
  );
  DiaryEntryRow copyWithCompanion(DiaryEntriesCompanion data) {
    return DiaryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      foodKind: data.foodKind.present ? data.foodKind.value : this.foodKind,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      foodVersion: data.foodVersion.present
          ? data.foodVersion.value
          : this.foodVersion,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      inputAmount: data.inputAmount.present
          ? data.inputAmount.value
          : this.inputAmount,
      inputUnit: data.inputUnit.present ? data.inputUnit.value : this.inputUnit,
      amount: data.amount.present ? data.amount.value : this.amount,
      amountBasis: data.amountBasis.present
          ? data.amountBasis.value
          : this.amountBasis,
      per100Kcal: data.per100Kcal.present
          ? data.per100Kcal.value
          : this.per100Kcal,
      per100ProteinG: data.per100ProteinG.present
          ? data.per100ProteinG.value
          : this.per100ProteinG,
      per100CarbsG: data.per100CarbsG.present
          ? data.per100CarbsG.value
          : this.per100CarbsG,
      per100FatG: data.per100FatG.present
          ? data.per100FatG.value
          : this.per100FatG,
      per100FiberG: data.per100FiberG.present
          ? data.per100FiberG.value
          : this.per100FiberG,
      per100ExtrasJson: data.per100ExtrasJson.present
          ? data.per100ExtrasJson.value
          : this.per100ExtrasJson,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      extrasJson: data.extrasJson.present
          ? data.extrasJson.value
          : this.extrasJson,
      source: data.source.present ? data.source.value : this.source,
      isEstimate: data.isEstimate.present
          ? data.isEstimate.value
          : this.isEstimate,
      estimateRangeJson: data.estimateRangeJson.present
          ? data.estimateRangeJson.value
          : this.estimateRangeJson,
      assumptionsJson: data.assumptionsJson.present
          ? data.assumptionsJson.value
          : this.assumptionsJson,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      tzOffsetMin: data.tzOffsetMin.present
          ? data.tzOffsetMin.value
          : this.tzOffsetMin,
      slotId: data.slotId.present ? data.slotId.value : this.slotId,
      dishGroupId: data.dishGroupId.present
          ? data.dishGroupId.value
          : this.dishGroupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntryRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('foodKind: $foodKind, ')
          ..write('foodId: $foodId, ')
          ..write('foodVersion: $foodVersion, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameAr: $nameAr, ')
          ..write('inputAmount: $inputAmount, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('amount: $amount, ')
          ..write('amountBasis: $amountBasis, ')
          ..write('per100Kcal: $per100Kcal, ')
          ..write('per100ProteinG: $per100ProteinG, ')
          ..write('per100CarbsG: $per100CarbsG, ')
          ..write('per100FatG: $per100FatG, ')
          ..write('per100FiberG: $per100FiberG, ')
          ..write('per100ExtrasJson: $per100ExtrasJson, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('extrasJson: $extrasJson, ')
          ..write('source: $source, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('estimateRangeJson: $estimateRangeJson, ')
          ..write('assumptionsJson: $assumptionsJson, ')
          ..write('localDate: $localDate, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('tzOffsetMin: $tzOffsetMin, ')
          ..write('slotId: $slotId, ')
          ..write('dishGroupId: $dishGroupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    foodKind,
    foodId,
    foodVersion,
    nameEn,
    nameAr,
    inputAmount,
    inputUnit,
    amount,
    amountBasis,
    per100Kcal,
    per100ProteinG,
    per100CarbsG,
    per100FatG,
    per100FiberG,
    per100ExtrasJson,
    kcal,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    extrasJson,
    source,
    isEstimate,
    estimateRangeJson,
    assumptionsJson,
    localDate,
    occurredAtUtc,
    tzOffsetMin,
    slotId,
    dishGroupId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryEntryRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.foodKind == this.foodKind &&
          other.foodId == this.foodId &&
          other.foodVersion == this.foodVersion &&
          other.nameEn == this.nameEn &&
          other.nameAr == this.nameAr &&
          other.inputAmount == this.inputAmount &&
          other.inputUnit == this.inputUnit &&
          other.amount == this.amount &&
          other.amountBasis == this.amountBasis &&
          other.per100Kcal == this.per100Kcal &&
          other.per100ProteinG == this.per100ProteinG &&
          other.per100CarbsG == this.per100CarbsG &&
          other.per100FatG == this.per100FatG &&
          other.per100FiberG == this.per100FiberG &&
          other.per100ExtrasJson == this.per100ExtrasJson &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.fiberG == this.fiberG &&
          other.extrasJson == this.extrasJson &&
          other.source == this.source &&
          other.isEstimate == this.isEstimate &&
          other.estimateRangeJson == this.estimateRangeJson &&
          other.assumptionsJson == this.assumptionsJson &&
          other.localDate == this.localDate &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.tzOffsetMin == this.tzOffsetMin &&
          other.slotId == this.slotId &&
          other.dishGroupId == this.dishGroupId);
}

class DiaryEntriesCompanion extends UpdateCompanion<DiaryEntryRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> foodKind;
  final Value<String?> foodId;
  final Value<String?> foodVersion;
  final Value<String> nameEn;
  final Value<String?> nameAr;
  final Value<double> inputAmount;
  final Value<String> inputUnit;
  final Value<double> amount;
  final Value<String> amountBasis;
  final Value<double> per100Kcal;
  final Value<double> per100ProteinG;
  final Value<double> per100CarbsG;
  final Value<double> per100FatG;
  final Value<double> per100FiberG;
  final Value<String?> per100ExtrasJson;
  final Value<double> kcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<double> fiberG;
  final Value<String?> extrasJson;
  final Value<String> source;
  final Value<bool> isEstimate;
  final Value<String?> estimateRangeJson;
  final Value<String?> assumptionsJson;
  final Value<String> localDate;
  final Value<int> occurredAtUtc;
  final Value<int> tzOffsetMin;
  final Value<String> slotId;
  final Value<String?> dishGroupId;
  final Value<int> rowid;
  const DiaryEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.foodKind = const Value.absent(),
    this.foodId = const Value.absent(),
    this.foodVersion = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.inputAmount = const Value.absent(),
    this.inputUnit = const Value.absent(),
    this.amount = const Value.absent(),
    this.amountBasis = const Value.absent(),
    this.per100Kcal = const Value.absent(),
    this.per100ProteinG = const Value.absent(),
    this.per100CarbsG = const Value.absent(),
    this.per100FatG = const Value.absent(),
    this.per100FiberG = const Value.absent(),
    this.per100ExtrasJson = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.extrasJson = const Value.absent(),
    this.source = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.estimateRangeJson = const Value.absent(),
    this.assumptionsJson = const Value.absent(),
    this.localDate = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.tzOffsetMin = const Value.absent(),
    this.slotId = const Value.absent(),
    this.dishGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiaryEntriesCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String foodKind,
    this.foodId = const Value.absent(),
    this.foodVersion = const Value.absent(),
    required String nameEn,
    this.nameAr = const Value.absent(),
    required double inputAmount,
    required String inputUnit,
    required double amount,
    required String amountBasis,
    required double per100Kcal,
    required double per100ProteinG,
    required double per100CarbsG,
    required double per100FatG,
    required double per100FiberG,
    this.per100ExtrasJson = const Value.absent(),
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required double fiberG,
    this.extrasJson = const Value.absent(),
    required String source,
    required bool isEstimate,
    this.estimateRangeJson = const Value.absent(),
    this.assumptionsJson = const Value.absent(),
    required String localDate,
    required int occurredAtUtc,
    required int tzOffsetMin,
    required String slotId,
    this.dishGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       foodKind = Value(foodKind),
       nameEn = Value(nameEn),
       inputAmount = Value(inputAmount),
       inputUnit = Value(inputUnit),
       amount = Value(amount),
       amountBasis = Value(amountBasis),
       per100Kcal = Value(per100Kcal),
       per100ProteinG = Value(per100ProteinG),
       per100CarbsG = Value(per100CarbsG),
       per100FatG = Value(per100FatG),
       per100FiberG = Value(per100FiberG),
       kcal = Value(kcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG),
       fiberG = Value(fiberG),
       source = Value(source),
       isEstimate = Value(isEstimate),
       localDate = Value(localDate),
       occurredAtUtc = Value(occurredAtUtc),
       tzOffsetMin = Value(tzOffsetMin),
       slotId = Value(slotId);
  static Insertable<DiaryEntryRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? foodKind,
    Expression<String>? foodId,
    Expression<String>? foodVersion,
    Expression<String>? nameEn,
    Expression<String>? nameAr,
    Expression<double>? inputAmount,
    Expression<String>? inputUnit,
    Expression<double>? amount,
    Expression<String>? amountBasis,
    Expression<double>? per100Kcal,
    Expression<double>? per100ProteinG,
    Expression<double>? per100CarbsG,
    Expression<double>? per100FatG,
    Expression<double>? per100FiberG,
    Expression<String>? per100ExtrasJson,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<double>? fiberG,
    Expression<String>? extrasJson,
    Expression<String>? source,
    Expression<bool>? isEstimate,
    Expression<String>? estimateRangeJson,
    Expression<String>? assumptionsJson,
    Expression<String>? localDate,
    Expression<int>? occurredAtUtc,
    Expression<int>? tzOffsetMin,
    Expression<String>? slotId,
    Expression<String>? dishGroupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (foodKind != null) 'food_kind': foodKind,
      if (foodId != null) 'food_id': foodId,
      if (foodVersion != null) 'food_version': foodVersion,
      if (nameEn != null) 'name_en': nameEn,
      if (nameAr != null) 'name_ar': nameAr,
      if (inputAmount != null) 'input_amount': inputAmount,
      if (inputUnit != null) 'input_unit': inputUnit,
      if (amount != null) 'amount': amount,
      if (amountBasis != null) 'amount_basis': amountBasis,
      if (per100Kcal != null) 'per100_kcal': per100Kcal,
      if (per100ProteinG != null) 'per100_protein_g': per100ProteinG,
      if (per100CarbsG != null) 'per100_carbs_g': per100CarbsG,
      if (per100FatG != null) 'per100_fat_g': per100FatG,
      if (per100FiberG != null) 'per100_fiber_g': per100FiberG,
      if (per100ExtrasJson != null) 'per100_extras_json': per100ExtrasJson,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (extrasJson != null) 'extras_json': extrasJson,
      if (source != null) 'source': source,
      if (isEstimate != null) 'is_estimate': isEstimate,
      if (estimateRangeJson != null) 'estimate_range_json': estimateRangeJson,
      if (assumptionsJson != null) 'assumptions_json': assumptionsJson,
      if (localDate != null) 'local_date': localDate,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (tzOffsetMin != null) 'tz_offset_min': tzOffsetMin,
      if (slotId != null) 'slot_id': slotId,
      if (dishGroupId != null) 'dish_group_id': dishGroupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiaryEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? foodKind,
    Value<String?>? foodId,
    Value<String?>? foodVersion,
    Value<String>? nameEn,
    Value<String?>? nameAr,
    Value<double>? inputAmount,
    Value<String>? inputUnit,
    Value<double>? amount,
    Value<String>? amountBasis,
    Value<double>? per100Kcal,
    Value<double>? per100ProteinG,
    Value<double>? per100CarbsG,
    Value<double>? per100FatG,
    Value<double>? per100FiberG,
    Value<String?>? per100ExtrasJson,
    Value<double>? kcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<double>? fiberG,
    Value<String?>? extrasJson,
    Value<String>? source,
    Value<bool>? isEstimate,
    Value<String?>? estimateRangeJson,
    Value<String?>? assumptionsJson,
    Value<String>? localDate,
    Value<int>? occurredAtUtc,
    Value<int>? tzOffsetMin,
    Value<String>? slotId,
    Value<String?>? dishGroupId,
    Value<int>? rowid,
  }) {
    return DiaryEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      foodKind: foodKind ?? this.foodKind,
      foodId: foodId ?? this.foodId,
      foodVersion: foodVersion ?? this.foodVersion,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      inputAmount: inputAmount ?? this.inputAmount,
      inputUnit: inputUnit ?? this.inputUnit,
      amount: amount ?? this.amount,
      amountBasis: amountBasis ?? this.amountBasis,
      per100Kcal: per100Kcal ?? this.per100Kcal,
      per100ProteinG: per100ProteinG ?? this.per100ProteinG,
      per100CarbsG: per100CarbsG ?? this.per100CarbsG,
      per100FatG: per100FatG ?? this.per100FatG,
      per100FiberG: per100FiberG ?? this.per100FiberG,
      per100ExtrasJson: per100ExtrasJson ?? this.per100ExtrasJson,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      extrasJson: extrasJson ?? this.extrasJson,
      source: source ?? this.source,
      isEstimate: isEstimate ?? this.isEstimate,
      estimateRangeJson: estimateRangeJson ?? this.estimateRangeJson,
      assumptionsJson: assumptionsJson ?? this.assumptionsJson,
      localDate: localDate ?? this.localDate,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      tzOffsetMin: tzOffsetMin ?? this.tzOffsetMin,
      slotId: slotId ?? this.slotId,
      dishGroupId: dishGroupId ?? this.dishGroupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (foodKind.present) {
      map['food_kind'] = Variable<String>(foodKind.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (foodVersion.present) {
      map['food_version'] = Variable<String>(foodVersion.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (inputAmount.present) {
      map['input_amount'] = Variable<double>(inputAmount.value);
    }
    if (inputUnit.present) {
      map['input_unit'] = Variable<String>(inputUnit.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (amountBasis.present) {
      map['amount_basis'] = Variable<String>(amountBasis.value);
    }
    if (per100Kcal.present) {
      map['per100_kcal'] = Variable<double>(per100Kcal.value);
    }
    if (per100ProteinG.present) {
      map['per100_protein_g'] = Variable<double>(per100ProteinG.value);
    }
    if (per100CarbsG.present) {
      map['per100_carbs_g'] = Variable<double>(per100CarbsG.value);
    }
    if (per100FatG.present) {
      map['per100_fat_g'] = Variable<double>(per100FatG.value);
    }
    if (per100FiberG.present) {
      map['per100_fiber_g'] = Variable<double>(per100FiberG.value);
    }
    if (per100ExtrasJson.present) {
      map['per100_extras_json'] = Variable<String>(per100ExtrasJson.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (extrasJson.present) {
      map['extras_json'] = Variable<String>(extrasJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (isEstimate.present) {
      map['is_estimate'] = Variable<bool>(isEstimate.value);
    }
    if (estimateRangeJson.present) {
      map['estimate_range_json'] = Variable<String>(estimateRangeJson.value);
    }
    if (assumptionsJson.present) {
      map['assumptions_json'] = Variable<String>(assumptionsJson.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<int>(occurredAtUtc.value);
    }
    if (tzOffsetMin.present) {
      map['tz_offset_min'] = Variable<int>(tzOffsetMin.value);
    }
    if (slotId.present) {
      map['slot_id'] = Variable<String>(slotId.value);
    }
    if (dishGroupId.present) {
      map['dish_group_id'] = Variable<String>(dishGroupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('foodKind: $foodKind, ')
          ..write('foodId: $foodId, ')
          ..write('foodVersion: $foodVersion, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameAr: $nameAr, ')
          ..write('inputAmount: $inputAmount, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('amount: $amount, ')
          ..write('amountBasis: $amountBasis, ')
          ..write('per100Kcal: $per100Kcal, ')
          ..write('per100ProteinG: $per100ProteinG, ')
          ..write('per100CarbsG: $per100CarbsG, ')
          ..write('per100FatG: $per100FatG, ')
          ..write('per100FiberG: $per100FiberG, ')
          ..write('per100ExtrasJson: $per100ExtrasJson, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('extrasJson: $extrasJson, ')
          ..write('source: $source, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('estimateRangeJson: $estimateRangeJson, ')
          ..write('assumptionsJson: $assumptionsJson, ')
          ..write('localDate: $localDate, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('tzOffsetMin: $tzOffsetMin, ')
          ..write('slotId: $slotId, ')
          ..write('dishGroupId: $dishGroupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DishGroupsTable extends DishGroups
    with TableInfo<$DishGroupsTable, DishGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DishGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotIdMeta = const VerificationMeta('slotId');
  @override
  late final GeneratedColumn<String> slotId = GeneratedColumn<String>(
    'slot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    name,
    localDate,
    slotId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dish_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<DishGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('slot_id')) {
      context.handle(
        _slotIdMeta,
        slotId.isAcceptableOrUnknown(data['slot_id']!, _slotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_slotIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DishGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DishGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      slotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot_id'],
      )!,
    );
  }

  @override
  $DishGroupsTable createAlias(String alias) {
    return $DishGroupsTable(attachedDatabase, alias);
  }
}

class DishGroupRow extends DataClass implements Insertable<DishGroupRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The dish name. User content.
  final String name;

  /// The diary day, `YYYY-MM-DD`.
  final String localDate;

  /// The meal slot's id.
  final String slotId;
  const DishGroupRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.name,
    required this.localDate,
    required this.slotId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['name'] = Variable<String>(name);
    map['local_date'] = Variable<String>(localDate);
    map['slot_id'] = Variable<String>(slotId);
    return map;
  }

  DishGroupsCompanion toCompanion(bool nullToAbsent) {
    return DishGroupsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      name: Value(name),
      localDate: Value(localDate),
      slotId: Value(slotId),
    );
  }

  factory DishGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DishGroupRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      name: serializer.fromJson<String>(json['name']),
      localDate: serializer.fromJson<String>(json['localDate']),
      slotId: serializer.fromJson<String>(json['slotId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'name': serializer.toJson<String>(name),
      'localDate': serializer.toJson<String>(localDate),
      'slotId': serializer.toJson<String>(slotId),
    };
  }

  DishGroupRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? name,
    String? localDate,
    String? slotId,
  }) => DishGroupRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    name: name ?? this.name,
    localDate: localDate ?? this.localDate,
    slotId: slotId ?? this.slotId,
  );
  DishGroupRow copyWithCompanion(DishGroupsCompanion data) {
    return DishGroupRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      name: data.name.present ? data.name.value : this.name,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      slotId: data.slotId.present ? data.slotId.value : this.slotId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DishGroupRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('name: $name, ')
          ..write('localDate: $localDate, ')
          ..write('slotId: $slotId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    name,
    localDate,
    slotId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DishGroupRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.name == this.name &&
          other.localDate == this.localDate &&
          other.slotId == this.slotId);
}

class DishGroupsCompanion extends UpdateCompanion<DishGroupRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> name;
  final Value<String> localDate;
  final Value<String> slotId;
  final Value<int> rowid;
  const DishGroupsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.name = const Value.absent(),
    this.localDate = const Value.absent(),
    this.slotId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DishGroupsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String name,
    required String localDate,
    required String slotId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       name = Value(name),
       localDate = Value(localDate),
       slotId = Value(slotId);
  static Insertable<DishGroupRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? name,
    Expression<String>? localDate,
    Expression<String>? slotId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (name != null) 'name': name,
      if (localDate != null) 'local_date': localDate,
      if (slotId != null) 'slot_id': slotId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DishGroupsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? name,
    Value<String>? localDate,
    Value<String>? slotId,
    Value<int>? rowid,
  }) {
    return DishGroupsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      name: name ?? this.name,
      localDate: localDate ?? this.localDate,
      slotId: slotId ?? this.slotId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (slotId.present) {
      map['slot_id'] = Variable<String>(slotId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DishGroupsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('name: $name, ')
          ..write('localDate: $localDate, ')
          ..write('slotId: $slotId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedMealItemsTable extends SavedMealItems
    with TableInfo<$SavedMealItemsTable, SavedMealItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedMealItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _foodKindMeta = const VerificationMeta(
    'foodKind',
  );
  @override
  late final GeneratedColumn<String> foodKind = GeneratedColumn<String>(
    'food_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foodVersionMeta = const VerificationMeta(
    'foodVersion',
  );
  @override
  late final GeneratedColumn<String> foodVersion = GeneratedColumn<String>(
    'food_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputAmountMeta = const VerificationMeta(
    'inputAmount',
  );
  @override
  late final GeneratedColumn<double> inputAmount = GeneratedColumn<double>(
    'input_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputUnitMeta = const VerificationMeta(
    'inputUnit',
  );
  @override
  late final GeneratedColumn<String> inputUnit = GeneratedColumn<String>(
    'input_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountBasisMeta = const VerificationMeta(
    'amountBasis',
  );
  @override
  late final GeneratedColumn<String> amountBasis = GeneratedColumn<String>(
    'amount_basis',
    aliasedName,
    false,
    check: () => amountBasis.isIn(const ['g', 'ml']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100KcalMeta = const VerificationMeta(
    'per100Kcal',
  );
  @override
  late final GeneratedColumn<double> per100Kcal = GeneratedColumn<double>(
    'per100_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100ProteinGMeta = const VerificationMeta(
    'per100ProteinG',
  );
  @override
  late final GeneratedColumn<double> per100ProteinG = GeneratedColumn<double>(
    'per100_protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100CarbsGMeta = const VerificationMeta(
    'per100CarbsG',
  );
  @override
  late final GeneratedColumn<double> per100CarbsG = GeneratedColumn<double>(
    'per100_carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100FatGMeta = const VerificationMeta(
    'per100FatG',
  );
  @override
  late final GeneratedColumn<double> per100FatG = GeneratedColumn<double>(
    'per100_fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100FiberGMeta = const VerificationMeta(
    'per100FiberG',
  );
  @override
  late final GeneratedColumn<double> per100FiberG = GeneratedColumn<double>(
    'per100_fiber_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100ExtrasJsonMeta = const VerificationMeta(
    'per100ExtrasJson',
  );
  @override
  late final GeneratedColumn<String> per100ExtrasJson = GeneratedColumn<String>(
    'per100_extras_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    check: () => ComparableExpr(kcal).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    check: () => ComparableExpr(proteinG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    check: () => ComparableExpr(carbsG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    check: () => ComparableExpr(fatG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    false,
    check: () => ComparableExpr(fiberG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extrasJsonMeta = const VerificationMeta(
    'extrasJson',
  );
  @override
  late final GeneratedColumn<String> extrasJson = GeneratedColumn<String>(
    'extras_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEstimateMeta = const VerificationMeta(
    'isEstimate',
  );
  @override
  late final GeneratedColumn<bool> isEstimate = GeneratedColumn<bool>(
    'is_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimate" IN (0, 1))',
    ),
  );
  static const VerificationMeta _estimateRangeJsonMeta = const VerificationMeta(
    'estimateRangeJson',
  );
  @override
  late final GeneratedColumn<String> estimateRangeJson =
      GeneratedColumn<String>(
        'estimate_range_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _assumptionsJsonMeta = const VerificationMeta(
    'assumptionsJson',
  );
  @override
  late final GeneratedColumn<String> assumptionsJson = GeneratedColumn<String>(
    'assumptions_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedMealIdMeta = const VerificationMeta(
    'savedMealId',
  );
  @override
  late final GeneratedColumn<String> savedMealId = GeneratedColumn<String>(
    'saved_meal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    foodKind,
    foodId,
    foodVersion,
    nameEn,
    nameAr,
    inputAmount,
    inputUnit,
    amount,
    amountBasis,
    per100Kcal,
    per100ProteinG,
    per100CarbsG,
    per100FatG,
    per100FiberG,
    per100ExtrasJson,
    kcal,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    extrasJson,
    source,
    isEstimate,
    estimateRangeJson,
    assumptionsJson,
    savedMealId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_meal_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedMealItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('food_kind')) {
      context.handle(
        _foodKindMeta,
        foodKind.isAcceptableOrUnknown(data['food_kind']!, _foodKindMeta),
      );
    } else if (isInserting) {
      context.missing(_foodKindMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('food_version')) {
      context.handle(
        _foodVersionMeta,
        foodVersion.isAcceptableOrUnknown(
          data['food_version']!,
          _foodVersionMeta,
        ),
      );
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    }
    if (data.containsKey('input_amount')) {
      context.handle(
        _inputAmountMeta,
        inputAmount.isAcceptableOrUnknown(
          data['input_amount']!,
          _inputAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputAmountMeta);
    }
    if (data.containsKey('input_unit')) {
      context.handle(
        _inputUnitMeta,
        inputUnit.isAcceptableOrUnknown(data['input_unit']!, _inputUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_inputUnitMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('amount_basis')) {
      context.handle(
        _amountBasisMeta,
        amountBasis.isAcceptableOrUnknown(
          data['amount_basis']!,
          _amountBasisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountBasisMeta);
    }
    if (data.containsKey('per100_kcal')) {
      context.handle(
        _per100KcalMeta,
        per100Kcal.isAcceptableOrUnknown(data['per100_kcal']!, _per100KcalMeta),
      );
    } else if (isInserting) {
      context.missing(_per100KcalMeta);
    }
    if (data.containsKey('per100_protein_g')) {
      context.handle(
        _per100ProteinGMeta,
        per100ProteinG.isAcceptableOrUnknown(
          data['per100_protein_g']!,
          _per100ProteinGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100ProteinGMeta);
    }
    if (data.containsKey('per100_carbs_g')) {
      context.handle(
        _per100CarbsGMeta,
        per100CarbsG.isAcceptableOrUnknown(
          data['per100_carbs_g']!,
          _per100CarbsGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100CarbsGMeta);
    }
    if (data.containsKey('per100_fat_g')) {
      context.handle(
        _per100FatGMeta,
        per100FatG.isAcceptableOrUnknown(
          data['per100_fat_g']!,
          _per100FatGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100FatGMeta);
    }
    if (data.containsKey('per100_fiber_g')) {
      context.handle(
        _per100FiberGMeta,
        per100FiberG.isAcceptableOrUnknown(
          data['per100_fiber_g']!,
          _per100FiberGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100FiberGMeta);
    }
    if (data.containsKey('per100_extras_json')) {
      context.handle(
        _per100ExtrasJsonMeta,
        per100ExtrasJson.isAcceptableOrUnknown(
          data['per100_extras_json']!,
          _per100ExtrasJsonMeta,
        ),
      );
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    } else if (isInserting) {
      context.missing(_fiberGMeta);
    }
    if (data.containsKey('extras_json')) {
      context.handle(
        _extrasJsonMeta,
        extrasJson.isAcceptableOrUnknown(data['extras_json']!, _extrasJsonMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('is_estimate')) {
      context.handle(
        _isEstimateMeta,
        isEstimate.isAcceptableOrUnknown(data['is_estimate']!, _isEstimateMeta),
      );
    } else if (isInserting) {
      context.missing(_isEstimateMeta);
    }
    if (data.containsKey('estimate_range_json')) {
      context.handle(
        _estimateRangeJsonMeta,
        estimateRangeJson.isAcceptableOrUnknown(
          data['estimate_range_json']!,
          _estimateRangeJsonMeta,
        ),
      );
    }
    if (data.containsKey('assumptions_json')) {
      context.handle(
        _assumptionsJsonMeta,
        assumptionsJson.isAcceptableOrUnknown(
          data['assumptions_json']!,
          _assumptionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('saved_meal_id')) {
      context.handle(
        _savedMealIdMeta,
        savedMealId.isAcceptableOrUnknown(
          data['saved_meal_id']!,
          _savedMealIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_savedMealIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedMealItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedMealItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      foodKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_kind'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      ),
      foodVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_version'],
      ),
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      ),
      inputAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}input_amount'],
      )!,
      inputUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_unit'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      amountBasis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_basis'],
      )!,
      per100Kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_kcal'],
      )!,
      per100ProteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_protein_g'],
      )!,
      per100CarbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_carbs_g'],
      )!,
      per100FatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_fat_g'],
      )!,
      per100FiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_fiber_g'],
      )!,
      per100ExtrasJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}per100_extras_json'],
      ),
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      )!,
      extrasJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extras_json'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      isEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimate'],
      )!,
      estimateRangeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estimate_range_json'],
      ),
      assumptionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assumptions_json'],
      ),
      savedMealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saved_meal_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $SavedMealItemsTable createAlias(String alias) {
    return $SavedMealItemsTable(attachedDatabase, alias);
  }
}

class SavedMealItemRow extends DataClass
    implements Insertable<SavedMealItemRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// `catalog`, `personal`, `estimate` (A27 adds `batch`).
  final String foodKind;

  /// The food's opaque id, `null` for an estimate.
  final String? foodId;

  /// The catalog pack version at log time (opaque), or `null`.
  final String? foodVersion;

  /// The English name. User or catalog content.
  final String nameEn;

  /// The Arabic name, when there is one.
  final String? nameAr;

  /// The amount as typed.
  final double inputAmount;

  /// The unit as typed.
  final String inputUnit;

  /// The canonical amount, grams or ml.
  final double amount;

  /// `g` or `ml`.
  final String amountBasis;

  /// Per-100 kcal.
  final double per100Kcal;

  /// Per-100 protein, g.
  final double per100ProteinG;

  /// Per-100 carbs, g.
  final double per100CarbsG;

  /// Per-100 fat, g.
  final double per100FatG;

  /// Per-100 fiber, g.
  final double per100FiberG;

  /// Per-100 extras as JSON (`{"sugar": 1.2}`), or `null`.
  final String? per100ExtrasJson;

  /// The snapshot kcal for [amount].
  final double kcal;

  /// The snapshot protein, g.
  final double proteinG;

  /// The snapshot carbs, g.
  final double carbsG;

  /// The snapshot fat, g.
  final double fatG;

  /// The snapshot fiber, g.
  final double fiberG;

  /// The snapshot extras as JSON, or `null`.
  final String? extrasJson;

  /// The badge: `yours`, `database`, `reference`, `estimate`.
  final String source;

  /// Whether the values are estimated.
  final bool isEstimate;

  /// `{"lowKcal": …, "highKcal": …}` for an estimate with a range.
  final String? estimateRangeJson;

  /// The assumptions behind the values, a JSON list of strings.
  final String? assumptionsJson;

  /// The saved meal's id.
  final String savedMealId;

  /// The position in the meal.
  final int sortOrder;
  const SavedMealItemRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.foodKind,
    this.foodId,
    this.foodVersion,
    required this.nameEn,
    this.nameAr,
    required this.inputAmount,
    required this.inputUnit,
    required this.amount,
    required this.amountBasis,
    required this.per100Kcal,
    required this.per100ProteinG,
    required this.per100CarbsG,
    required this.per100FatG,
    required this.per100FiberG,
    this.per100ExtrasJson,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    this.extrasJson,
    required this.source,
    required this.isEstimate,
    this.estimateRangeJson,
    this.assumptionsJson,
    required this.savedMealId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['food_kind'] = Variable<String>(foodKind);
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<String>(foodId);
    }
    if (!nullToAbsent || foodVersion != null) {
      map['food_version'] = Variable<String>(foodVersion);
    }
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || nameAr != null) {
      map['name_ar'] = Variable<String>(nameAr);
    }
    map['input_amount'] = Variable<double>(inputAmount);
    map['input_unit'] = Variable<String>(inputUnit);
    map['amount'] = Variable<double>(amount);
    map['amount_basis'] = Variable<String>(amountBasis);
    map['per100_kcal'] = Variable<double>(per100Kcal);
    map['per100_protein_g'] = Variable<double>(per100ProteinG);
    map['per100_carbs_g'] = Variable<double>(per100CarbsG);
    map['per100_fat_g'] = Variable<double>(per100FatG);
    map['per100_fiber_g'] = Variable<double>(per100FiberG);
    if (!nullToAbsent || per100ExtrasJson != null) {
      map['per100_extras_json'] = Variable<String>(per100ExtrasJson);
    }
    map['kcal'] = Variable<double>(kcal);
    map['protein_g'] = Variable<double>(proteinG);
    map['carbs_g'] = Variable<double>(carbsG);
    map['fat_g'] = Variable<double>(fatG);
    map['fiber_g'] = Variable<double>(fiberG);
    if (!nullToAbsent || extrasJson != null) {
      map['extras_json'] = Variable<String>(extrasJson);
    }
    map['source'] = Variable<String>(source);
    map['is_estimate'] = Variable<bool>(isEstimate);
    if (!nullToAbsent || estimateRangeJson != null) {
      map['estimate_range_json'] = Variable<String>(estimateRangeJson);
    }
    if (!nullToAbsent || assumptionsJson != null) {
      map['assumptions_json'] = Variable<String>(assumptionsJson);
    }
    map['saved_meal_id'] = Variable<String>(savedMealId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  SavedMealItemsCompanion toCompanion(bool nullToAbsent) {
    return SavedMealItemsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      foodKind: Value(foodKind),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      foodVersion: foodVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(foodVersion),
      nameEn: Value(nameEn),
      nameAr: nameAr == null && nullToAbsent
          ? const Value.absent()
          : Value(nameAr),
      inputAmount: Value(inputAmount),
      inputUnit: Value(inputUnit),
      amount: Value(amount),
      amountBasis: Value(amountBasis),
      per100Kcal: Value(per100Kcal),
      per100ProteinG: Value(per100ProteinG),
      per100CarbsG: Value(per100CarbsG),
      per100FatG: Value(per100FatG),
      per100FiberG: Value(per100FiberG),
      per100ExtrasJson: per100ExtrasJson == null && nullToAbsent
          ? const Value.absent()
          : Value(per100ExtrasJson),
      kcal: Value(kcal),
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      fiberG: Value(fiberG),
      extrasJson: extrasJson == null && nullToAbsent
          ? const Value.absent()
          : Value(extrasJson),
      source: Value(source),
      isEstimate: Value(isEstimate),
      estimateRangeJson: estimateRangeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateRangeJson),
      assumptionsJson: assumptionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(assumptionsJson),
      savedMealId: Value(savedMealId),
      sortOrder: Value(sortOrder),
    );
  }

  factory SavedMealItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedMealItemRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      foodKind: serializer.fromJson<String>(json['foodKind']),
      foodId: serializer.fromJson<String?>(json['foodId']),
      foodVersion: serializer.fromJson<String?>(json['foodVersion']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameAr: serializer.fromJson<String?>(json['nameAr']),
      inputAmount: serializer.fromJson<double>(json['inputAmount']),
      inputUnit: serializer.fromJson<String>(json['inputUnit']),
      amount: serializer.fromJson<double>(json['amount']),
      amountBasis: serializer.fromJson<String>(json['amountBasis']),
      per100Kcal: serializer.fromJson<double>(json['per100Kcal']),
      per100ProteinG: serializer.fromJson<double>(json['per100ProteinG']),
      per100CarbsG: serializer.fromJson<double>(json['per100CarbsG']),
      per100FatG: serializer.fromJson<double>(json['per100FatG']),
      per100FiberG: serializer.fromJson<double>(json['per100FiberG']),
      per100ExtrasJson: serializer.fromJson<String?>(json['per100ExtrasJson']),
      kcal: serializer.fromJson<double>(json['kcal']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      fiberG: serializer.fromJson<double>(json['fiberG']),
      extrasJson: serializer.fromJson<String?>(json['extrasJson']),
      source: serializer.fromJson<String>(json['source']),
      isEstimate: serializer.fromJson<bool>(json['isEstimate']),
      estimateRangeJson: serializer.fromJson<String?>(
        json['estimateRangeJson'],
      ),
      assumptionsJson: serializer.fromJson<String?>(json['assumptionsJson']),
      savedMealId: serializer.fromJson<String>(json['savedMealId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'foodKind': serializer.toJson<String>(foodKind),
      'foodId': serializer.toJson<String?>(foodId),
      'foodVersion': serializer.toJson<String?>(foodVersion),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameAr': serializer.toJson<String?>(nameAr),
      'inputAmount': serializer.toJson<double>(inputAmount),
      'inputUnit': serializer.toJson<String>(inputUnit),
      'amount': serializer.toJson<double>(amount),
      'amountBasis': serializer.toJson<String>(amountBasis),
      'per100Kcal': serializer.toJson<double>(per100Kcal),
      'per100ProteinG': serializer.toJson<double>(per100ProteinG),
      'per100CarbsG': serializer.toJson<double>(per100CarbsG),
      'per100FatG': serializer.toJson<double>(per100FatG),
      'per100FiberG': serializer.toJson<double>(per100FiberG),
      'per100ExtrasJson': serializer.toJson<String?>(per100ExtrasJson),
      'kcal': serializer.toJson<double>(kcal),
      'proteinG': serializer.toJson<double>(proteinG),
      'carbsG': serializer.toJson<double>(carbsG),
      'fatG': serializer.toJson<double>(fatG),
      'fiberG': serializer.toJson<double>(fiberG),
      'extrasJson': serializer.toJson<String?>(extrasJson),
      'source': serializer.toJson<String>(source),
      'isEstimate': serializer.toJson<bool>(isEstimate),
      'estimateRangeJson': serializer.toJson<String?>(estimateRangeJson),
      'assumptionsJson': serializer.toJson<String?>(assumptionsJson),
      'savedMealId': serializer.toJson<String>(savedMealId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  SavedMealItemRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? foodKind,
    Value<String?> foodId = const Value.absent(),
    Value<String?> foodVersion = const Value.absent(),
    String? nameEn,
    Value<String?> nameAr = const Value.absent(),
    double? inputAmount,
    String? inputUnit,
    double? amount,
    String? amountBasis,
    double? per100Kcal,
    double? per100ProteinG,
    double? per100CarbsG,
    double? per100FatG,
    double? per100FiberG,
    Value<String?> per100ExtrasJson = const Value.absent(),
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    double? fiberG,
    Value<String?> extrasJson = const Value.absent(),
    String? source,
    bool? isEstimate,
    Value<String?> estimateRangeJson = const Value.absent(),
    Value<String?> assumptionsJson = const Value.absent(),
    String? savedMealId,
    int? sortOrder,
  }) => SavedMealItemRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    foodKind: foodKind ?? this.foodKind,
    foodId: foodId.present ? foodId.value : this.foodId,
    foodVersion: foodVersion.present ? foodVersion.value : this.foodVersion,
    nameEn: nameEn ?? this.nameEn,
    nameAr: nameAr.present ? nameAr.value : this.nameAr,
    inputAmount: inputAmount ?? this.inputAmount,
    inputUnit: inputUnit ?? this.inputUnit,
    amount: amount ?? this.amount,
    amountBasis: amountBasis ?? this.amountBasis,
    per100Kcal: per100Kcal ?? this.per100Kcal,
    per100ProteinG: per100ProteinG ?? this.per100ProteinG,
    per100CarbsG: per100CarbsG ?? this.per100CarbsG,
    per100FatG: per100FatG ?? this.per100FatG,
    per100FiberG: per100FiberG ?? this.per100FiberG,
    per100ExtrasJson: per100ExtrasJson.present
        ? per100ExtrasJson.value
        : this.per100ExtrasJson,
    kcal: kcal ?? this.kcal,
    proteinG: proteinG ?? this.proteinG,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    fiberG: fiberG ?? this.fiberG,
    extrasJson: extrasJson.present ? extrasJson.value : this.extrasJson,
    source: source ?? this.source,
    isEstimate: isEstimate ?? this.isEstimate,
    estimateRangeJson: estimateRangeJson.present
        ? estimateRangeJson.value
        : this.estimateRangeJson,
    assumptionsJson: assumptionsJson.present
        ? assumptionsJson.value
        : this.assumptionsJson,
    savedMealId: savedMealId ?? this.savedMealId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  SavedMealItemRow copyWithCompanion(SavedMealItemsCompanion data) {
    return SavedMealItemRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      foodKind: data.foodKind.present ? data.foodKind.value : this.foodKind,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      foodVersion: data.foodVersion.present
          ? data.foodVersion.value
          : this.foodVersion,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      inputAmount: data.inputAmount.present
          ? data.inputAmount.value
          : this.inputAmount,
      inputUnit: data.inputUnit.present ? data.inputUnit.value : this.inputUnit,
      amount: data.amount.present ? data.amount.value : this.amount,
      amountBasis: data.amountBasis.present
          ? data.amountBasis.value
          : this.amountBasis,
      per100Kcal: data.per100Kcal.present
          ? data.per100Kcal.value
          : this.per100Kcal,
      per100ProteinG: data.per100ProteinG.present
          ? data.per100ProteinG.value
          : this.per100ProteinG,
      per100CarbsG: data.per100CarbsG.present
          ? data.per100CarbsG.value
          : this.per100CarbsG,
      per100FatG: data.per100FatG.present
          ? data.per100FatG.value
          : this.per100FatG,
      per100FiberG: data.per100FiberG.present
          ? data.per100FiberG.value
          : this.per100FiberG,
      per100ExtrasJson: data.per100ExtrasJson.present
          ? data.per100ExtrasJson.value
          : this.per100ExtrasJson,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      extrasJson: data.extrasJson.present
          ? data.extrasJson.value
          : this.extrasJson,
      source: data.source.present ? data.source.value : this.source,
      isEstimate: data.isEstimate.present
          ? data.isEstimate.value
          : this.isEstimate,
      estimateRangeJson: data.estimateRangeJson.present
          ? data.estimateRangeJson.value
          : this.estimateRangeJson,
      assumptionsJson: data.assumptionsJson.present
          ? data.assumptionsJson.value
          : this.assumptionsJson,
      savedMealId: data.savedMealId.present
          ? data.savedMealId.value
          : this.savedMealId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedMealItemRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('foodKind: $foodKind, ')
          ..write('foodId: $foodId, ')
          ..write('foodVersion: $foodVersion, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameAr: $nameAr, ')
          ..write('inputAmount: $inputAmount, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('amount: $amount, ')
          ..write('amountBasis: $amountBasis, ')
          ..write('per100Kcal: $per100Kcal, ')
          ..write('per100ProteinG: $per100ProteinG, ')
          ..write('per100CarbsG: $per100CarbsG, ')
          ..write('per100FatG: $per100FatG, ')
          ..write('per100FiberG: $per100FiberG, ')
          ..write('per100ExtrasJson: $per100ExtrasJson, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('extrasJson: $extrasJson, ')
          ..write('source: $source, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('estimateRangeJson: $estimateRangeJson, ')
          ..write('assumptionsJson: $assumptionsJson, ')
          ..write('savedMealId: $savedMealId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    foodKind,
    foodId,
    foodVersion,
    nameEn,
    nameAr,
    inputAmount,
    inputUnit,
    amount,
    amountBasis,
    per100Kcal,
    per100ProteinG,
    per100CarbsG,
    per100FatG,
    per100FiberG,
    per100ExtrasJson,
    kcal,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    extrasJson,
    source,
    isEstimate,
    estimateRangeJson,
    assumptionsJson,
    savedMealId,
    sortOrder,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedMealItemRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.foodKind == this.foodKind &&
          other.foodId == this.foodId &&
          other.foodVersion == this.foodVersion &&
          other.nameEn == this.nameEn &&
          other.nameAr == this.nameAr &&
          other.inputAmount == this.inputAmount &&
          other.inputUnit == this.inputUnit &&
          other.amount == this.amount &&
          other.amountBasis == this.amountBasis &&
          other.per100Kcal == this.per100Kcal &&
          other.per100ProteinG == this.per100ProteinG &&
          other.per100CarbsG == this.per100CarbsG &&
          other.per100FatG == this.per100FatG &&
          other.per100FiberG == this.per100FiberG &&
          other.per100ExtrasJson == this.per100ExtrasJson &&
          other.kcal == this.kcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.fiberG == this.fiberG &&
          other.extrasJson == this.extrasJson &&
          other.source == this.source &&
          other.isEstimate == this.isEstimate &&
          other.estimateRangeJson == this.estimateRangeJson &&
          other.assumptionsJson == this.assumptionsJson &&
          other.savedMealId == this.savedMealId &&
          other.sortOrder == this.sortOrder);
}

class SavedMealItemsCompanion extends UpdateCompanion<SavedMealItemRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> foodKind;
  final Value<String?> foodId;
  final Value<String?> foodVersion;
  final Value<String> nameEn;
  final Value<String?> nameAr;
  final Value<double> inputAmount;
  final Value<String> inputUnit;
  final Value<double> amount;
  final Value<String> amountBasis;
  final Value<double> per100Kcal;
  final Value<double> per100ProteinG;
  final Value<double> per100CarbsG;
  final Value<double> per100FatG;
  final Value<double> per100FiberG;
  final Value<String?> per100ExtrasJson;
  final Value<double> kcal;
  final Value<double> proteinG;
  final Value<double> carbsG;
  final Value<double> fatG;
  final Value<double> fiberG;
  final Value<String?> extrasJson;
  final Value<String> source;
  final Value<bool> isEstimate;
  final Value<String?> estimateRangeJson;
  final Value<String?> assumptionsJson;
  final Value<String> savedMealId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const SavedMealItemsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.foodKind = const Value.absent(),
    this.foodId = const Value.absent(),
    this.foodVersion = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.inputAmount = const Value.absent(),
    this.inputUnit = const Value.absent(),
    this.amount = const Value.absent(),
    this.amountBasis = const Value.absent(),
    this.per100Kcal = const Value.absent(),
    this.per100ProteinG = const Value.absent(),
    this.per100CarbsG = const Value.absent(),
    this.per100FatG = const Value.absent(),
    this.per100FiberG = const Value.absent(),
    this.per100ExtrasJson = const Value.absent(),
    this.kcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.extrasJson = const Value.absent(),
    this.source = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.estimateRangeJson = const Value.absent(),
    this.assumptionsJson = const Value.absent(),
    this.savedMealId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedMealItemsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String foodKind,
    this.foodId = const Value.absent(),
    this.foodVersion = const Value.absent(),
    required String nameEn,
    this.nameAr = const Value.absent(),
    required double inputAmount,
    required String inputUnit,
    required double amount,
    required String amountBasis,
    required double per100Kcal,
    required double per100ProteinG,
    required double per100CarbsG,
    required double per100FatG,
    required double per100FiberG,
    this.per100ExtrasJson = const Value.absent(),
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required double fiberG,
    this.extrasJson = const Value.absent(),
    required String source,
    required bool isEstimate,
    this.estimateRangeJson = const Value.absent(),
    this.assumptionsJson = const Value.absent(),
    required String savedMealId,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       foodKind = Value(foodKind),
       nameEn = Value(nameEn),
       inputAmount = Value(inputAmount),
       inputUnit = Value(inputUnit),
       amount = Value(amount),
       amountBasis = Value(amountBasis),
       per100Kcal = Value(per100Kcal),
       per100ProteinG = Value(per100ProteinG),
       per100CarbsG = Value(per100CarbsG),
       per100FatG = Value(per100FatG),
       per100FiberG = Value(per100FiberG),
       kcal = Value(kcal),
       proteinG = Value(proteinG),
       carbsG = Value(carbsG),
       fatG = Value(fatG),
       fiberG = Value(fiberG),
       source = Value(source),
       isEstimate = Value(isEstimate),
       savedMealId = Value(savedMealId),
       sortOrder = Value(sortOrder);
  static Insertable<SavedMealItemRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? foodKind,
    Expression<String>? foodId,
    Expression<String>? foodVersion,
    Expression<String>? nameEn,
    Expression<String>? nameAr,
    Expression<double>? inputAmount,
    Expression<String>? inputUnit,
    Expression<double>? amount,
    Expression<String>? amountBasis,
    Expression<double>? per100Kcal,
    Expression<double>? per100ProteinG,
    Expression<double>? per100CarbsG,
    Expression<double>? per100FatG,
    Expression<double>? per100FiberG,
    Expression<String>? per100ExtrasJson,
    Expression<double>? kcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<double>? fiberG,
    Expression<String>? extrasJson,
    Expression<String>? source,
    Expression<bool>? isEstimate,
    Expression<String>? estimateRangeJson,
    Expression<String>? assumptionsJson,
    Expression<String>? savedMealId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (foodKind != null) 'food_kind': foodKind,
      if (foodId != null) 'food_id': foodId,
      if (foodVersion != null) 'food_version': foodVersion,
      if (nameEn != null) 'name_en': nameEn,
      if (nameAr != null) 'name_ar': nameAr,
      if (inputAmount != null) 'input_amount': inputAmount,
      if (inputUnit != null) 'input_unit': inputUnit,
      if (amount != null) 'amount': amount,
      if (amountBasis != null) 'amount_basis': amountBasis,
      if (per100Kcal != null) 'per100_kcal': per100Kcal,
      if (per100ProteinG != null) 'per100_protein_g': per100ProteinG,
      if (per100CarbsG != null) 'per100_carbs_g': per100CarbsG,
      if (per100FatG != null) 'per100_fat_g': per100FatG,
      if (per100FiberG != null) 'per100_fiber_g': per100FiberG,
      if (per100ExtrasJson != null) 'per100_extras_json': per100ExtrasJson,
      if (kcal != null) 'kcal': kcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (extrasJson != null) 'extras_json': extrasJson,
      if (source != null) 'source': source,
      if (isEstimate != null) 'is_estimate': isEstimate,
      if (estimateRangeJson != null) 'estimate_range_json': estimateRangeJson,
      if (assumptionsJson != null) 'assumptions_json': assumptionsJson,
      if (savedMealId != null) 'saved_meal_id': savedMealId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedMealItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? foodKind,
    Value<String?>? foodId,
    Value<String?>? foodVersion,
    Value<String>? nameEn,
    Value<String?>? nameAr,
    Value<double>? inputAmount,
    Value<String>? inputUnit,
    Value<double>? amount,
    Value<String>? amountBasis,
    Value<double>? per100Kcal,
    Value<double>? per100ProteinG,
    Value<double>? per100CarbsG,
    Value<double>? per100FatG,
    Value<double>? per100FiberG,
    Value<String?>? per100ExtrasJson,
    Value<double>? kcal,
    Value<double>? proteinG,
    Value<double>? carbsG,
    Value<double>? fatG,
    Value<double>? fiberG,
    Value<String?>? extrasJson,
    Value<String>? source,
    Value<bool>? isEstimate,
    Value<String?>? estimateRangeJson,
    Value<String?>? assumptionsJson,
    Value<String>? savedMealId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return SavedMealItemsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      foodKind: foodKind ?? this.foodKind,
      foodId: foodId ?? this.foodId,
      foodVersion: foodVersion ?? this.foodVersion,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      inputAmount: inputAmount ?? this.inputAmount,
      inputUnit: inputUnit ?? this.inputUnit,
      amount: amount ?? this.amount,
      amountBasis: amountBasis ?? this.amountBasis,
      per100Kcal: per100Kcal ?? this.per100Kcal,
      per100ProteinG: per100ProteinG ?? this.per100ProteinG,
      per100CarbsG: per100CarbsG ?? this.per100CarbsG,
      per100FatG: per100FatG ?? this.per100FatG,
      per100FiberG: per100FiberG ?? this.per100FiberG,
      per100ExtrasJson: per100ExtrasJson ?? this.per100ExtrasJson,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      extrasJson: extrasJson ?? this.extrasJson,
      source: source ?? this.source,
      isEstimate: isEstimate ?? this.isEstimate,
      estimateRangeJson: estimateRangeJson ?? this.estimateRangeJson,
      assumptionsJson: assumptionsJson ?? this.assumptionsJson,
      savedMealId: savedMealId ?? this.savedMealId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (foodKind.present) {
      map['food_kind'] = Variable<String>(foodKind.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (foodVersion.present) {
      map['food_version'] = Variable<String>(foodVersion.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (inputAmount.present) {
      map['input_amount'] = Variable<double>(inputAmount.value);
    }
    if (inputUnit.present) {
      map['input_unit'] = Variable<String>(inputUnit.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (amountBasis.present) {
      map['amount_basis'] = Variable<String>(amountBasis.value);
    }
    if (per100Kcal.present) {
      map['per100_kcal'] = Variable<double>(per100Kcal.value);
    }
    if (per100ProteinG.present) {
      map['per100_protein_g'] = Variable<double>(per100ProteinG.value);
    }
    if (per100CarbsG.present) {
      map['per100_carbs_g'] = Variable<double>(per100CarbsG.value);
    }
    if (per100FatG.present) {
      map['per100_fat_g'] = Variable<double>(per100FatG.value);
    }
    if (per100FiberG.present) {
      map['per100_fiber_g'] = Variable<double>(per100FiberG.value);
    }
    if (per100ExtrasJson.present) {
      map['per100_extras_json'] = Variable<String>(per100ExtrasJson.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (extrasJson.present) {
      map['extras_json'] = Variable<String>(extrasJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (isEstimate.present) {
      map['is_estimate'] = Variable<bool>(isEstimate.value);
    }
    if (estimateRangeJson.present) {
      map['estimate_range_json'] = Variable<String>(estimateRangeJson.value);
    }
    if (assumptionsJson.present) {
      map['assumptions_json'] = Variable<String>(assumptionsJson.value);
    }
    if (savedMealId.present) {
      map['saved_meal_id'] = Variable<String>(savedMealId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedMealItemsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('foodKind: $foodKind, ')
          ..write('foodId: $foodId, ')
          ..write('foodVersion: $foodVersion, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameAr: $nameAr, ')
          ..write('inputAmount: $inputAmount, ')
          ..write('inputUnit: $inputUnit, ')
          ..write('amount: $amount, ')
          ..write('amountBasis: $amountBasis, ')
          ..write('per100Kcal: $per100Kcal, ')
          ..write('per100ProteinG: $per100ProteinG, ')
          ..write('per100CarbsG: $per100CarbsG, ')
          ..write('per100FatG: $per100FatG, ')
          ..write('per100FiberG: $per100FiberG, ')
          ..write('per100ExtrasJson: $per100ExtrasJson, ')
          ..write('kcal: $kcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('extrasJson: $extrasJson, ')
          ..write('source: $source, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('estimateRangeJson: $estimateRangeJson, ')
          ..write('assumptionsJson: $assumptionsJson, ')
          ..write('savedMealId: $savedMealId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayMarksTable extends DayMarks
    with TableInfo<$DayMarksTable, DayMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incompleteMeta = const VerificationMeta(
    'incomplete',
  );
  @override
  late final GeneratedColumn<bool> incomplete = GeneratedColumn<bool>(
    'incomplete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("incomplete" IN (0, 1))',
    ),
  );
  static const VerificationMeta _notFastingMeta = const VerificationMeta(
    'notFasting',
  );
  @override
  late final GeneratedColumn<bool> notFasting = GeneratedColumn<bool>(
    'not_fasting',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("not_fasting" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    localDate,
    incomplete,
    notFasting,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_marks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayMarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('incomplete')) {
      context.handle(
        _incompleteMeta,
        incomplete.isAcceptableOrUnknown(data['incomplete']!, _incompleteMeta),
      );
    } else if (isInserting) {
      context.missing(_incompleteMeta);
    }
    if (data.containsKey('not_fasting')) {
      context.handle(
        _notFastingMeta,
        notFasting.isAcceptableOrUnknown(data['not_fasting']!, _notFastingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayMarkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      incomplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}incomplete'],
      )!,
      notFasting: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}not_fasting'],
      )!,
    );
  }

  @override
  $DayMarksTable createAlias(String alias) {
    return $DayMarksTable(attachedDatabase, alias);
  }
}

class DayMarkRow extends DataClass implements Insertable<DayMarkRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The day, `YYYY-MM-DD`.
  final String localDate;

  /// Whether the day is marked incomplete.
  final bool incomplete;

  /// Whether a Ramadan day is marked not fasting (A41).
  final bool notFasting;
  const DayMarkRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.localDate,
    required this.incomplete,
    required this.notFasting,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['local_date'] = Variable<String>(localDate);
    map['incomplete'] = Variable<bool>(incomplete);
    map['not_fasting'] = Variable<bool>(notFasting);
    return map;
  }

  DayMarksCompanion toCompanion(bool nullToAbsent) {
    return DayMarksCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      localDate: Value(localDate),
      incomplete: Value(incomplete),
      notFasting: Value(notFasting),
    );
  }

  factory DayMarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayMarkRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      localDate: serializer.fromJson<String>(json['localDate']),
      incomplete: serializer.fromJson<bool>(json['incomplete']),
      notFasting: serializer.fromJson<bool>(json['notFasting']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'localDate': serializer.toJson<String>(localDate),
      'incomplete': serializer.toJson<bool>(incomplete),
      'notFasting': serializer.toJson<bool>(notFasting),
    };
  }

  DayMarkRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? localDate,
    bool? incomplete,
    bool? notFasting,
  }) => DayMarkRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    localDate: localDate ?? this.localDate,
    incomplete: incomplete ?? this.incomplete,
    notFasting: notFasting ?? this.notFasting,
  );
  DayMarkRow copyWithCompanion(DayMarksCompanion data) {
    return DayMarkRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      incomplete: data.incomplete.present
          ? data.incomplete.value
          : this.incomplete,
      notFasting: data.notFasting.present
          ? data.notFasting.value
          : this.notFasting,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayMarkRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('localDate: $localDate, ')
          ..write('incomplete: $incomplete, ')
          ..write('notFasting: $notFasting')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    localDate,
    incomplete,
    notFasting,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayMarkRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.localDate == this.localDate &&
          other.incomplete == this.incomplete &&
          other.notFasting == this.notFasting);
}

class DayMarksCompanion extends UpdateCompanion<DayMarkRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> localDate;
  final Value<bool> incomplete;
  final Value<bool> notFasting;
  final Value<int> rowid;
  const DayMarksCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.localDate = const Value.absent(),
    this.incomplete = const Value.absent(),
    this.notFasting = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayMarksCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String localDate,
    required bool incomplete,
    this.notFasting = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       localDate = Value(localDate),
       incomplete = Value(incomplete);
  static Insertable<DayMarkRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? localDate,
    Expression<bool>? incomplete,
    Expression<bool>? notFasting,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (localDate != null) 'local_date': localDate,
      if (incomplete != null) 'incomplete': incomplete,
      if (notFasting != null) 'not_fasting': notFasting,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayMarksCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? localDate,
    Value<bool>? incomplete,
    Value<bool>? notFasting,
    Value<int>? rowid,
  }) {
    return DayMarksCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      localDate: localDate ?? this.localDate,
      incomplete: incomplete ?? this.incomplete,
      notFasting: notFasting ?? this.notFasting,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (incomplete.present) {
      map['incomplete'] = Variable<bool>(incomplete.value);
    }
    if (notFasting.present) {
      map['not_fasting'] = Variable<bool>(notFasting.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayMarksCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('localDate: $localDate, ')
          ..write('incomplete: $incomplete, ')
          ..write('notFasting: $notFasting, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealSlotsTable extends MealSlots
    with TableInfo<$MealSlotsTable, MealSlotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultKeyMeta = const VerificationMeta(
    'defaultKey',
  );
  @override
  late final GeneratedColumn<String> defaultKey = GeneratedColumn<String>(
    'default_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowStartMinMeta = const VerificationMeta(
    'windowStartMin',
  );
  @override
  late final GeneratedColumn<int> windowStartMin = GeneratedColumn<int>(
    'window_start_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windowEndMinMeta = const VerificationMeta(
    'windowEndMin',
  );
  @override
  late final GeneratedColumn<int> windowEndMin = GeneratedColumn<int>(
    'window_end_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    check: () => mode.isIn(const ['normal', 'ramadan']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    defaultKey,
    name,
    sortOrder,
    windowStartMin,
    windowEndMin,
    mode,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealSlotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('default_key')) {
      context.handle(
        _defaultKeyMeta,
        defaultKey.isAcceptableOrUnknown(data['default_key']!, _defaultKeyMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('window_start_min')) {
      context.handle(
        _windowStartMinMeta,
        windowStartMin.isAcceptableOrUnknown(
          data['window_start_min']!,
          _windowStartMinMeta,
        ),
      );
    }
    if (data.containsKey('window_end_min')) {
      context.handle(
        _windowEndMinMeta,
        windowEndMin.isAcceptableOrUnknown(
          data['window_end_min']!,
          _windowEndMinMeta,
        ),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealSlotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealSlotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      defaultKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_key'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      windowStartMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_start_min'],
      ),
      windowEndMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_end_min'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $MealSlotsTable createAlias(String alias) {
    return $MealSlotsTable(attachedDatabase, alias);
  }
}

class MealSlotRow extends DataClass implements Insertable<MealSlotRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// `breakfast` … for a default slot, `null` for a custom one.
  final String? defaultKey;

  /// The user's name, `null` for a default slot not renamed (the UI shows
  /// the label for [defaultKey]). User content.
  final String? name;

  /// The position in the day, lowest first.
  final int sortOrder;

  /// The window start, minutes after local midnight (0-1439), or `null`.
  final int? windowStartMin;

  /// The window end (exclusive), or `null`. Both bounds or neither.
  final int? windowEndMin;

  /// `normal` or `ramadan`.
  final String mode;

  /// Whether the slot is in use.
  final bool active;
  const MealSlotRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    this.defaultKey,
    this.name,
    required this.sortOrder,
    this.windowStartMin,
    this.windowEndMin,
    required this.mode,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    if (!nullToAbsent || defaultKey != null) {
      map['default_key'] = Variable<String>(defaultKey);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || windowStartMin != null) {
      map['window_start_min'] = Variable<int>(windowStartMin);
    }
    if (!nullToAbsent || windowEndMin != null) {
      map['window_end_min'] = Variable<int>(windowEndMin);
    }
    map['mode'] = Variable<String>(mode);
    map['active'] = Variable<bool>(active);
    return map;
  }

  MealSlotsCompanion toCompanion(bool nullToAbsent) {
    return MealSlotsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      defaultKey: defaultKey == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultKey),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      sortOrder: Value(sortOrder),
      windowStartMin: windowStartMin == null && nullToAbsent
          ? const Value.absent()
          : Value(windowStartMin),
      windowEndMin: windowEndMin == null && nullToAbsent
          ? const Value.absent()
          : Value(windowEndMin),
      mode: Value(mode),
      active: Value(active),
    );
  }

  factory MealSlotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealSlotRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      defaultKey: serializer.fromJson<String?>(json['defaultKey']),
      name: serializer.fromJson<String?>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      windowStartMin: serializer.fromJson<int?>(json['windowStartMin']),
      windowEndMin: serializer.fromJson<int?>(json['windowEndMin']),
      mode: serializer.fromJson<String>(json['mode']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'defaultKey': serializer.toJson<String?>(defaultKey),
      'name': serializer.toJson<String?>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'windowStartMin': serializer.toJson<int?>(windowStartMin),
      'windowEndMin': serializer.toJson<int?>(windowEndMin),
      'mode': serializer.toJson<String>(mode),
      'active': serializer.toJson<bool>(active),
    };
  }

  MealSlotRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    Value<String?> defaultKey = const Value.absent(),
    Value<String?> name = const Value.absent(),
    int? sortOrder,
    Value<int?> windowStartMin = const Value.absent(),
    Value<int?> windowEndMin = const Value.absent(),
    String? mode,
    bool? active,
  }) => MealSlotRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    defaultKey: defaultKey.present ? defaultKey.value : this.defaultKey,
    name: name.present ? name.value : this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    windowStartMin: windowStartMin.present
        ? windowStartMin.value
        : this.windowStartMin,
    windowEndMin: windowEndMin.present ? windowEndMin.value : this.windowEndMin,
    mode: mode ?? this.mode,
    active: active ?? this.active,
  );
  MealSlotRow copyWithCompanion(MealSlotsCompanion data) {
    return MealSlotRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      defaultKey: data.defaultKey.present
          ? data.defaultKey.value
          : this.defaultKey,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      windowStartMin: data.windowStartMin.present
          ? data.windowStartMin.value
          : this.windowStartMin,
      windowEndMin: data.windowEndMin.present
          ? data.windowEndMin.value
          : this.windowEndMin,
      mode: data.mode.present ? data.mode.value : this.mode,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealSlotRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('defaultKey: $defaultKey, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('windowStartMin: $windowStartMin, ')
          ..write('windowEndMin: $windowEndMin, ')
          ..write('mode: $mode, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    defaultKey,
    name,
    sortOrder,
    windowStartMin,
    windowEndMin,
    mode,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealSlotRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.defaultKey == this.defaultKey &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.windowStartMin == this.windowStartMin &&
          other.windowEndMin == this.windowEndMin &&
          other.mode == this.mode &&
          other.active == this.active);
}

class MealSlotsCompanion extends UpdateCompanion<MealSlotRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String?> defaultKey;
  final Value<String?> name;
  final Value<int> sortOrder;
  final Value<int?> windowStartMin;
  final Value<int?> windowEndMin;
  final Value<String> mode;
  final Value<bool> active;
  final Value<int> rowid;
  const MealSlotsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.defaultKey = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.windowStartMin = const Value.absent(),
    this.windowEndMin = const Value.absent(),
    this.mode = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealSlotsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    this.defaultKey = const Value.absent(),
    this.name = const Value.absent(),
    required int sortOrder,
    this.windowStartMin = const Value.absent(),
    this.windowEndMin = const Value.absent(),
    required String mode,
    required bool active,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       sortOrder = Value(sortOrder),
       mode = Value(mode),
       active = Value(active);
  static Insertable<MealSlotRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? defaultKey,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? windowStartMin,
    Expression<int>? windowEndMin,
    Expression<String>? mode,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (defaultKey != null) 'default_key': defaultKey,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (windowStartMin != null) 'window_start_min': windowStartMin,
      if (windowEndMin != null) 'window_end_min': windowEndMin,
      if (mode != null) 'mode': mode,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealSlotsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String?>? defaultKey,
    Value<String?>? name,
    Value<int>? sortOrder,
    Value<int?>? windowStartMin,
    Value<int?>? windowEndMin,
    Value<String>? mode,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return MealSlotsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      defaultKey: defaultKey ?? this.defaultKey,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      windowStartMin: windowStartMin ?? this.windowStartMin,
      windowEndMin: windowEndMin ?? this.windowEndMin,
      mode: mode ?? this.mode,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (defaultKey.present) {
      map['default_key'] = Variable<String>(defaultKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (windowStartMin.present) {
      map['window_start_min'] = Variable<int>(windowStartMin.value);
    }
    if (windowEndMin.present) {
      map['window_end_min'] = Variable<int>(windowEndMin.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealSlotsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('defaultKey: $defaultKey, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('windowStartMin: $windowStartMin, ')
          ..write('windowEndMin: $windowEndMin, ')
          ..write('mode: $mode, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedMealsTable extends SavedMeals
    with TableInfo<$SavedMealsTable, SavedMealRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedMealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedMealRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedMealRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedMealRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $SavedMealsTable createAlias(String alias) {
    return $SavedMealsTable(attachedDatabase, alias);
  }
}

class SavedMealRow extends DataClass implements Insertable<SavedMealRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The meal's name. User content.
  final String name;
  const SavedMealRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['name'] = Variable<String>(name);
    return map;
  }

  SavedMealsCompanion toCompanion(bool nullToAbsent) {
    return SavedMealsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      name: Value(name),
    );
  }

  factory SavedMealRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedMealRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'name': serializer.toJson<String>(name),
    };
  }

  SavedMealRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? name,
  }) => SavedMealRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    name: name ?? this.name,
  );
  SavedMealRow copyWithCompanion(SavedMealsCompanion data) {
    return SavedMealRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedMealRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    name,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedMealRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.name == this.name);
}

class SavedMealsCompanion extends UpdateCompanion<SavedMealRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> name;
  final Value<int> rowid;
  const SavedMealsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedMealsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       name = Value(name);
  static Insertable<SavedMealRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedMealsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return SavedMealsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedMealsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsKvTable extends SettingsKv
    with TableInfo<$SettingsKvTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    valueJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
    );
  }

  @override
  $SettingsKvTable createAlias(String alias) {
    return $SettingsKvTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// The value as JSON text.
  final String valueJson;
  const SettingRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.valueJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['value_json'] = Variable<String>(valueJson);
    return map;
  }

  SettingsKvCompanion toCompanion(bool nullToAbsent) {
    return SettingsKvCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      valueJson: Value(valueJson),
    );
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'valueJson': serializer.toJson<String>(valueJson),
    };
  }

  SettingRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? valueJson,
  }) => SettingRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    valueJson: valueJson ?? this.valueJson,
  );
  SettingRow copyWithCompanion(SettingsKvCompanion data) {
    return SettingRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('valueJson: $valueJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    valueJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.valueJson == this.valueJson);
}

class SettingsKvCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> valueJson;
  final Value<int> rowid;
  const SettingsKvCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsKvCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String valueJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       valueJson = Value(valueJson);
  static Insertable<SettingRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? valueJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (valueJson != null) 'value_json': valueJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsKvCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? valueJson,
    Value<int>? rowid,
  }) {
    return SettingsKvCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      valueJson: valueJson ?? this.valueJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('valueJson: $valueJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  /// A dot-separated key, like `outbox.capture`.
  final String key;

  /// The value as text.
  final String value;
  const SyncStateRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateRow copyWith({String? key, String? value}) =>
      SyncStateRow(key: key ?? this.key, value: value ?? this.value);
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [seq, entity, rowId, hlc, deleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  SyncOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class SyncOutboxRow extends DataClass implements Insertable<SyncOutboxRow> {
  /// The append order.
  final int seq;

  /// The entity wire name, like `setting`.
  final String entity;

  /// The written row's id.
  final String rowId;

  /// The written version's `updated_hlc`.
  final String hlc;

  /// Whether the written version is a tombstone.
  final bool deleted;
  const SyncOutboxRow({
    required this.seq,
    required this.entity,
    required this.rowId,
    required this.hlc,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['entity'] = Variable<String>(entity);
    map['row_id'] = Variable<String>(rowId);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      seq: Value(seq),
      entity: Value(entity),
      rowId: Value(rowId),
      hlc: Value(hlc),
      deleted: Value(deleted),
    );
  }

  factory SyncOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxRow(
      seq: serializer.fromJson<int>(json['seq']),
      entity: serializer.fromJson<String>(json['entity']),
      rowId: serializer.fromJson<String>(json['rowId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'entity': serializer.toJson<String>(entity),
      'rowId': serializer.toJson<String>(rowId),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  SyncOutboxRow copyWith({
    int? seq,
    String? entity,
    String? rowId,
    String? hlc,
    bool? deleted,
  }) => SyncOutboxRow(
    seq: seq ?? this.seq,
    entity: entity ?? this.entity,
    rowId: rowId ?? this.rowId,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
  );
  SyncOutboxRow copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      entity: data.entity.present ? data.entity.value : this.entity,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxRow(')
          ..write('seq: $seq, ')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(seq, entity, rowId, hlc, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxRow &&
          other.seq == this.seq &&
          other.entity == this.entity &&
          other.rowId == this.rowId &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxRow> {
  final Value<int> seq;
  final Value<String> entity;
  final Value<String> rowId;
  final Value<String> hlc;
  final Value<bool> deleted;
  const SyncOutboxCompanion({
    this.seq = const Value.absent(),
    this.entity = const Value.absent(),
    this.rowId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String entity,
    required String rowId,
    required String hlc,
    required bool deleted,
  }) : entity = Value(entity),
       rowId = Value(rowId),
       hlc = Value(hlc),
       deleted = Value(deleted);
  static Insertable<SyncOutboxRow> custom({
    Expression<int>? seq,
    Expression<String>? entity,
    Expression<String>? rowId,
    Expression<String>? hlc,
    Expression<bool>? deleted,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (entity != null) 'entity': entity,
      if (rowId != null) 'row_id': rowId,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? entity,
    Value<String>? rowId,
    Value<String>? hlc,
    Value<bool>? deleted,
  }) {
    return SyncOutboxCompanion(
      seq: seq ?? this.seq,
      entity: entity ?? this.entity,
      rowId: rowId ?? this.rowId,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }
}

class $PersonalFoodsTable extends PersonalFoods
    with TableInfo<$PersonalFoodsTable, PersonalFoodRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalFoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedHlcMeta = const VerificationMeta(
    'updatedHlc',
  );
  @override
  late final GeneratedColumn<String> updatedHlc = GeneratedColumn<String>(
    'updated_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedByUserMeta = const VerificationMeta(
    'editedByUser',
  );
  @override
  late final GeneratedColumn<bool> editedByUser = GeneratedColumn<bool>(
    'edited_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("edited_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aliasesJsonMeta = const VerificationMeta(
    'aliasesJson',
  );
  @override
  late final GeneratedColumn<String> aliasesJson = GeneratedColumn<String>(
    'aliases_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodesJsonMeta = const VerificationMeta(
    'barcodesJson',
  );
  @override
  late final GeneratedColumn<String> barcodesJson = GeneratedColumn<String>(
    'barcodes_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _per100ExtrasJsonMeta = const VerificationMeta(
    'per100ExtrasJson',
  );
  @override
  late final GeneratedColumn<String> per100ExtrasJson = GeneratedColumn<String>(
    'per100_extras_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingsJsonMeta = const VerificationMeta(
    'servingsJson',
  );
  @override
  late final GeneratedColumn<String> servingsJson = GeneratedColumn<String>(
    'servings_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entryServingUnitMeta = const VerificationMeta(
    'entryServingUnit',
  );
  @override
  late final GeneratedColumn<String> entryServingUnit = GeneratedColumn<String>(
    'entry_serving_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdFromMeta = const VerificationMeta(
    'createdFrom',
  );
  @override
  late final GeneratedColumn<String> createdFrom = GeneratedColumn<String>(
    'created_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _basisMeta = const VerificationMeta('basis');
  @override
  late final GeneratedColumn<String> basis = GeneratedColumn<String>(
    'basis',
    aliasedName,
    false,
    check: () => basis.isIn(const ['g', 'ml']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100KcalMeta = const VerificationMeta(
    'per100Kcal',
  );
  @override
  late final GeneratedColumn<double> per100Kcal = GeneratedColumn<double>(
    'per100_kcal',
    aliasedName,
    false,
    check: () => ComparableExpr(per100Kcal).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100ProteinGMeta = const VerificationMeta(
    'per100ProteinG',
  );
  @override
  late final GeneratedColumn<double> per100ProteinG = GeneratedColumn<double>(
    'per100_protein_g',
    aliasedName,
    false,
    check: () => ComparableExpr(per100ProteinG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100CarbsGMeta = const VerificationMeta(
    'per100CarbsG',
  );
  @override
  late final GeneratedColumn<double> per100CarbsG = GeneratedColumn<double>(
    'per100_carbs_g',
    aliasedName,
    false,
    check: () => ComparableExpr(per100CarbsG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100FatGMeta = const VerificationMeta(
    'per100FatG',
  );
  @override
  late final GeneratedColumn<double> per100FatG = GeneratedColumn<double>(
    'per100_fat_g',
    aliasedName,
    false,
    check: () => ComparableExpr(per100FatG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _per100FiberGMeta = const VerificationMeta(
    'per100FiberG',
  );
  @override
  late final GeneratedColumn<double> per100FiberG = GeneratedColumn<double>(
    'per100_fiber_g',
    aliasedName,
    false,
    check: () => ComparableExpr(per100FiberG).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryServingAmountMeta =
      const VerificationMeta('entryServingAmount');
  @override
  late final GeneratedColumn<double> entryServingAmount =
      GeneratedColumn<double>(
        'entry_serving_amount',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    nameEn,
    nameAr,
    aliasesJson,
    brand,
    barcodesJson,
    per100ExtrasJson,
    servingsJson,
    entryServingUnit,
    createdFrom,
    state,
    basis,
    per100Kcal,
    per100ProteinG,
    per100CarbsG,
    per100FatG,
    per100FiberG,
    entryServingAmount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalFoodRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_hlc')) {
      context.handle(
        _updatedHlcMeta,
        updatedHlc.isAcceptableOrUnknown(data['updated_hlc']!, _updatedHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedHlcMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('edited_by_user')) {
      context.handle(
        _editedByUserMeta,
        editedByUser.isAcceptableOrUnknown(
          data['edited_by_user']!,
          _editedByUserMeta,
        ),
      );
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    }
    if (data.containsKey('aliases_json')) {
      context.handle(
        _aliasesJsonMeta,
        aliasesJson.isAcceptableOrUnknown(
          data['aliases_json']!,
          _aliasesJsonMeta,
        ),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('barcodes_json')) {
      context.handle(
        _barcodesJsonMeta,
        barcodesJson.isAcceptableOrUnknown(
          data['barcodes_json']!,
          _barcodesJsonMeta,
        ),
      );
    }
    if (data.containsKey('per100_extras_json')) {
      context.handle(
        _per100ExtrasJsonMeta,
        per100ExtrasJson.isAcceptableOrUnknown(
          data['per100_extras_json']!,
          _per100ExtrasJsonMeta,
        ),
      );
    }
    if (data.containsKey('servings_json')) {
      context.handle(
        _servingsJsonMeta,
        servingsJson.isAcceptableOrUnknown(
          data['servings_json']!,
          _servingsJsonMeta,
        ),
      );
    }
    if (data.containsKey('entry_serving_unit')) {
      context.handle(
        _entryServingUnitMeta,
        entryServingUnit.isAcceptableOrUnknown(
          data['entry_serving_unit']!,
          _entryServingUnitMeta,
        ),
      );
    }
    if (data.containsKey('created_from')) {
      context.handle(
        _createdFromMeta,
        createdFrom.isAcceptableOrUnknown(
          data['created_from']!,
          _createdFromMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdFromMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('basis')) {
      context.handle(
        _basisMeta,
        basis.isAcceptableOrUnknown(data['basis']!, _basisMeta),
      );
    } else if (isInserting) {
      context.missing(_basisMeta);
    }
    if (data.containsKey('per100_kcal')) {
      context.handle(
        _per100KcalMeta,
        per100Kcal.isAcceptableOrUnknown(data['per100_kcal']!, _per100KcalMeta),
      );
    } else if (isInserting) {
      context.missing(_per100KcalMeta);
    }
    if (data.containsKey('per100_protein_g')) {
      context.handle(
        _per100ProteinGMeta,
        per100ProteinG.isAcceptableOrUnknown(
          data['per100_protein_g']!,
          _per100ProteinGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100ProteinGMeta);
    }
    if (data.containsKey('per100_carbs_g')) {
      context.handle(
        _per100CarbsGMeta,
        per100CarbsG.isAcceptableOrUnknown(
          data['per100_carbs_g']!,
          _per100CarbsGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100CarbsGMeta);
    }
    if (data.containsKey('per100_fat_g')) {
      context.handle(
        _per100FatGMeta,
        per100FatG.isAcceptableOrUnknown(
          data['per100_fat_g']!,
          _per100FatGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100FatGMeta);
    }
    if (data.containsKey('per100_fiber_g')) {
      context.handle(
        _per100FiberGMeta,
        per100FiberG.isAcceptableOrUnknown(
          data['per100_fiber_g']!,
          _per100FiberGMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_per100FiberGMeta);
    }
    if (data.containsKey('entry_serving_amount')) {
      context.handle(
        _entryServingAmountMeta,
        entryServingAmount.isAcceptableOrUnknown(
          data['entry_serving_amount']!,
          _entryServingAmountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalFoodRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalFoodRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_hlc'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      editedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}edited_by_user'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      ),
      aliasesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases_json'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      barcodesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcodes_json'],
      ),
      per100ExtrasJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}per100_extras_json'],
      ),
      servingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}servings_json'],
      ),
      entryServingUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_serving_unit'],
      ),
      createdFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_from'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      basis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}basis'],
      )!,
      per100Kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_kcal'],
      )!,
      per100ProteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_protein_g'],
      )!,
      per100CarbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_carbs_g'],
      )!,
      per100FatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_fat_g'],
      )!,
      per100FiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}per100_fiber_g'],
      )!,
      entryServingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}entry_serving_amount'],
      ),
    );
  }

  @override
  $PersonalFoodsTable createAlias(String alias) {
    return $PersonalFoodsTable(attachedDatabase, alias);
  }
}

class PersonalFoodRow extends DataClass implements Insertable<PersonalFoodRow> {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  final String id;

  /// When the row was first written, UTC ms (0 for seeds).
  final int createdAt;

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  final String updatedHlc;

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  final int version;

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  final int? deletedAt;

  /// The install that made the last write (the HLC's node id, TD-053).
  final String deviceId;

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  final String origin;

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  final bool editedByUser;

  /// English name.
  final String nameEn;

  /// Optional Arabic name.
  final String? nameAr;

  /// Optional JSON alias list.
  final String? aliasesJson;

  /// Optional brand.
  final String? brand;

  /// Optional JSON GTIN list.
  final String? barcodesJson;

  /// Optional JSON nutrient extras.
  final String? per100ExtrasJson;

  /// Optional JSON serving definitions.
  final String? servingsJson;

  /// Original entry serving code.
  final String? entryServingUnit;

  /// Creation method, open for later steps.
  final String createdFrom;

  /// Nutrient state code.
  final String state;

  /// Grams or ml.
  final String basis;

  /// Stored per-100 value.
  final double per100Kcal;

  /// Stored per-100 value.
  final double per100ProteinG;

  /// Stored per-100 value.
  final double per100CarbsG;

  /// Stored per-100 value.
  final double per100FatG;

  /// Stored per-100 value.
  final double per100FiberG;

  /// Original entry serving amount on this basis.
  final double? entryServingAmount;
  const PersonalFoodRow({
    required this.id,
    required this.createdAt,
    required this.updatedHlc,
    required this.version,
    this.deletedAt,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
    required this.nameEn,
    this.nameAr,
    this.aliasesJson,
    this.brand,
    this.barcodesJson,
    this.per100ExtrasJson,
    this.servingsJson,
    this.entryServingUnit,
    required this.createdFrom,
    required this.state,
    required this.basis,
    required this.per100Kcal,
    required this.per100ProteinG,
    required this.per100CarbsG,
    required this.per100FatG,
    required this.per100FiberG,
    this.entryServingAmount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_hlc'] = Variable<String>(updatedHlc);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['device_id'] = Variable<String>(deviceId);
    map['origin'] = Variable<String>(origin);
    map['edited_by_user'] = Variable<bool>(editedByUser);
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || nameAr != null) {
      map['name_ar'] = Variable<String>(nameAr);
    }
    if (!nullToAbsent || aliasesJson != null) {
      map['aliases_json'] = Variable<String>(aliasesJson);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || barcodesJson != null) {
      map['barcodes_json'] = Variable<String>(barcodesJson);
    }
    if (!nullToAbsent || per100ExtrasJson != null) {
      map['per100_extras_json'] = Variable<String>(per100ExtrasJson);
    }
    if (!nullToAbsent || servingsJson != null) {
      map['servings_json'] = Variable<String>(servingsJson);
    }
    if (!nullToAbsent || entryServingUnit != null) {
      map['entry_serving_unit'] = Variable<String>(entryServingUnit);
    }
    map['created_from'] = Variable<String>(createdFrom);
    map['state'] = Variable<String>(state);
    map['basis'] = Variable<String>(basis);
    map['per100_kcal'] = Variable<double>(per100Kcal);
    map['per100_protein_g'] = Variable<double>(per100ProteinG);
    map['per100_carbs_g'] = Variable<double>(per100CarbsG);
    map['per100_fat_g'] = Variable<double>(per100FatG);
    map['per100_fiber_g'] = Variable<double>(per100FiberG);
    if (!nullToAbsent || entryServingAmount != null) {
      map['entry_serving_amount'] = Variable<double>(entryServingAmount);
    }
    return map;
  }

  PersonalFoodsCompanion toCompanion(bool nullToAbsent) {
    return PersonalFoodsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedHlc: Value(updatedHlc),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: Value(deviceId),
      origin: Value(origin),
      editedByUser: Value(editedByUser),
      nameEn: Value(nameEn),
      nameAr: nameAr == null && nullToAbsent
          ? const Value.absent()
          : Value(nameAr),
      aliasesJson: aliasesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(aliasesJson),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      barcodesJson: barcodesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(barcodesJson),
      per100ExtrasJson: per100ExtrasJson == null && nullToAbsent
          ? const Value.absent()
          : Value(per100ExtrasJson),
      servingsJson: servingsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(servingsJson),
      entryServingUnit: entryServingUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(entryServingUnit),
      createdFrom: Value(createdFrom),
      state: Value(state),
      basis: Value(basis),
      per100Kcal: Value(per100Kcal),
      per100ProteinG: Value(per100ProteinG),
      per100CarbsG: Value(per100CarbsG),
      per100FatG: Value(per100FatG),
      per100FiberG: Value(per100FiberG),
      entryServingAmount: entryServingAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(entryServingAmount),
    );
  }

  factory PersonalFoodRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalFoodRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedHlc: serializer.fromJson<String>(json['updatedHlc']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      origin: serializer.fromJson<String>(json['origin']),
      editedByUser: serializer.fromJson<bool>(json['editedByUser']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameAr: serializer.fromJson<String?>(json['nameAr']),
      aliasesJson: serializer.fromJson<String?>(json['aliasesJson']),
      brand: serializer.fromJson<String?>(json['brand']),
      barcodesJson: serializer.fromJson<String?>(json['barcodesJson']),
      per100ExtrasJson: serializer.fromJson<String?>(json['per100ExtrasJson']),
      servingsJson: serializer.fromJson<String?>(json['servingsJson']),
      entryServingUnit: serializer.fromJson<String?>(json['entryServingUnit']),
      createdFrom: serializer.fromJson<String>(json['createdFrom']),
      state: serializer.fromJson<String>(json['state']),
      basis: serializer.fromJson<String>(json['basis']),
      per100Kcal: serializer.fromJson<double>(json['per100Kcal']),
      per100ProteinG: serializer.fromJson<double>(json['per100ProteinG']),
      per100CarbsG: serializer.fromJson<double>(json['per100CarbsG']),
      per100FatG: serializer.fromJson<double>(json['per100FatG']),
      per100FiberG: serializer.fromJson<double>(json['per100FiberG']),
      entryServingAmount: serializer.fromJson<double?>(
        json['entryServingAmount'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedHlc': serializer.toJson<String>(updatedHlc),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'origin': serializer.toJson<String>(origin),
      'editedByUser': serializer.toJson<bool>(editedByUser),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameAr': serializer.toJson<String?>(nameAr),
      'aliasesJson': serializer.toJson<String?>(aliasesJson),
      'brand': serializer.toJson<String?>(brand),
      'barcodesJson': serializer.toJson<String?>(barcodesJson),
      'per100ExtrasJson': serializer.toJson<String?>(per100ExtrasJson),
      'servingsJson': serializer.toJson<String?>(servingsJson),
      'entryServingUnit': serializer.toJson<String?>(entryServingUnit),
      'createdFrom': serializer.toJson<String>(createdFrom),
      'state': serializer.toJson<String>(state),
      'basis': serializer.toJson<String>(basis),
      'per100Kcal': serializer.toJson<double>(per100Kcal),
      'per100ProteinG': serializer.toJson<double>(per100ProteinG),
      'per100CarbsG': serializer.toJson<double>(per100CarbsG),
      'per100FatG': serializer.toJson<double>(per100FatG),
      'per100FiberG': serializer.toJson<double>(per100FiberG),
      'entryServingAmount': serializer.toJson<double?>(entryServingAmount),
    };
  }

  PersonalFoodRow copyWith({
    String? id,
    int? createdAt,
    String? updatedHlc,
    int? version,
    Value<int?> deletedAt = const Value.absent(),
    String? deviceId,
    String? origin,
    bool? editedByUser,
    String? nameEn,
    Value<String?> nameAr = const Value.absent(),
    Value<String?> aliasesJson = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<String?> barcodesJson = const Value.absent(),
    Value<String?> per100ExtrasJson = const Value.absent(),
    Value<String?> servingsJson = const Value.absent(),
    Value<String?> entryServingUnit = const Value.absent(),
    String? createdFrom,
    String? state,
    String? basis,
    double? per100Kcal,
    double? per100ProteinG,
    double? per100CarbsG,
    double? per100FatG,
    double? per100FiberG,
    Value<double?> entryServingAmount = const Value.absent(),
  }) => PersonalFoodRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deviceId: deviceId ?? this.deviceId,
    origin: origin ?? this.origin,
    editedByUser: editedByUser ?? this.editedByUser,
    nameEn: nameEn ?? this.nameEn,
    nameAr: nameAr.present ? nameAr.value : this.nameAr,
    aliasesJson: aliasesJson.present ? aliasesJson.value : this.aliasesJson,
    brand: brand.present ? brand.value : this.brand,
    barcodesJson: barcodesJson.present ? barcodesJson.value : this.barcodesJson,
    per100ExtrasJson: per100ExtrasJson.present
        ? per100ExtrasJson.value
        : this.per100ExtrasJson,
    servingsJson: servingsJson.present ? servingsJson.value : this.servingsJson,
    entryServingUnit: entryServingUnit.present
        ? entryServingUnit.value
        : this.entryServingUnit,
    createdFrom: createdFrom ?? this.createdFrom,
    state: state ?? this.state,
    basis: basis ?? this.basis,
    per100Kcal: per100Kcal ?? this.per100Kcal,
    per100ProteinG: per100ProteinG ?? this.per100ProteinG,
    per100CarbsG: per100CarbsG ?? this.per100CarbsG,
    per100FatG: per100FatG ?? this.per100FatG,
    per100FiberG: per100FiberG ?? this.per100FiberG,
    entryServingAmount: entryServingAmount.present
        ? entryServingAmount.value
        : this.entryServingAmount,
  );
  PersonalFoodRow copyWithCompanion(PersonalFoodsCompanion data) {
    return PersonalFoodRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedHlc: data.updatedHlc.present
          ? data.updatedHlc.value
          : this.updatedHlc,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      origin: data.origin.present ? data.origin.value : this.origin,
      editedByUser: data.editedByUser.present
          ? data.editedByUser.value
          : this.editedByUser,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      aliasesJson: data.aliasesJson.present
          ? data.aliasesJson.value
          : this.aliasesJson,
      brand: data.brand.present ? data.brand.value : this.brand,
      barcodesJson: data.barcodesJson.present
          ? data.barcodesJson.value
          : this.barcodesJson,
      per100ExtrasJson: data.per100ExtrasJson.present
          ? data.per100ExtrasJson.value
          : this.per100ExtrasJson,
      servingsJson: data.servingsJson.present
          ? data.servingsJson.value
          : this.servingsJson,
      entryServingUnit: data.entryServingUnit.present
          ? data.entryServingUnit.value
          : this.entryServingUnit,
      createdFrom: data.createdFrom.present
          ? data.createdFrom.value
          : this.createdFrom,
      state: data.state.present ? data.state.value : this.state,
      basis: data.basis.present ? data.basis.value : this.basis,
      per100Kcal: data.per100Kcal.present
          ? data.per100Kcal.value
          : this.per100Kcal,
      per100ProteinG: data.per100ProteinG.present
          ? data.per100ProteinG.value
          : this.per100ProteinG,
      per100CarbsG: data.per100CarbsG.present
          ? data.per100CarbsG.value
          : this.per100CarbsG,
      per100FatG: data.per100FatG.present
          ? data.per100FatG.value
          : this.per100FatG,
      per100FiberG: data.per100FiberG.present
          ? data.per100FiberG.value
          : this.per100FiberG,
      entryServingAmount: data.entryServingAmount.present
          ? data.entryServingAmount.value
          : this.entryServingAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalFoodRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameAr: $nameAr, ')
          ..write('aliasesJson: $aliasesJson, ')
          ..write('brand: $brand, ')
          ..write('barcodesJson: $barcodesJson, ')
          ..write('per100ExtrasJson: $per100ExtrasJson, ')
          ..write('servingsJson: $servingsJson, ')
          ..write('entryServingUnit: $entryServingUnit, ')
          ..write('createdFrom: $createdFrom, ')
          ..write('state: $state, ')
          ..write('basis: $basis, ')
          ..write('per100Kcal: $per100Kcal, ')
          ..write('per100ProteinG: $per100ProteinG, ')
          ..write('per100CarbsG: $per100CarbsG, ')
          ..write('per100FatG: $per100FatG, ')
          ..write('per100FiberG: $per100FiberG, ')
          ..write('entryServingAmount: $entryServingAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedHlc,
    version,
    deletedAt,
    deviceId,
    origin,
    editedByUser,
    nameEn,
    nameAr,
    aliasesJson,
    brand,
    barcodesJson,
    per100ExtrasJson,
    servingsJson,
    entryServingUnit,
    createdFrom,
    state,
    basis,
    per100Kcal,
    per100ProteinG,
    per100CarbsG,
    per100FatG,
    per100FiberG,
    entryServingAmount,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalFoodRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedHlc == this.updatedHlc &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId &&
          other.origin == this.origin &&
          other.editedByUser == this.editedByUser &&
          other.nameEn == this.nameEn &&
          other.nameAr == this.nameAr &&
          other.aliasesJson == this.aliasesJson &&
          other.brand == this.brand &&
          other.barcodesJson == this.barcodesJson &&
          other.per100ExtrasJson == this.per100ExtrasJson &&
          other.servingsJson == this.servingsJson &&
          other.entryServingUnit == this.entryServingUnit &&
          other.createdFrom == this.createdFrom &&
          other.state == this.state &&
          other.basis == this.basis &&
          other.per100Kcal == this.per100Kcal &&
          other.per100ProteinG == this.per100ProteinG &&
          other.per100CarbsG == this.per100CarbsG &&
          other.per100FatG == this.per100FatG &&
          other.per100FiberG == this.per100FiberG &&
          other.entryServingAmount == this.entryServingAmount);
}

class PersonalFoodsCompanion extends UpdateCompanion<PersonalFoodRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<String> updatedHlc;
  final Value<int> version;
  final Value<int?> deletedAt;
  final Value<String> deviceId;
  final Value<String> origin;
  final Value<bool> editedByUser;
  final Value<String> nameEn;
  final Value<String?> nameAr;
  final Value<String?> aliasesJson;
  final Value<String?> brand;
  final Value<String?> barcodesJson;
  final Value<String?> per100ExtrasJson;
  final Value<String?> servingsJson;
  final Value<String?> entryServingUnit;
  final Value<String> createdFrom;
  final Value<String> state;
  final Value<String> basis;
  final Value<double> per100Kcal;
  final Value<double> per100ProteinG;
  final Value<double> per100CarbsG;
  final Value<double> per100FatG;
  final Value<double> per100FiberG;
  final Value<double?> entryServingAmount;
  final Value<int> rowid;
  const PersonalFoodsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedHlc = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.origin = const Value.absent(),
    this.editedByUser = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.aliasesJson = const Value.absent(),
    this.brand = const Value.absent(),
    this.barcodesJson = const Value.absent(),
    this.per100ExtrasJson = const Value.absent(),
    this.servingsJson = const Value.absent(),
    this.entryServingUnit = const Value.absent(),
    this.createdFrom = const Value.absent(),
    this.state = const Value.absent(),
    this.basis = const Value.absent(),
    this.per100Kcal = const Value.absent(),
    this.per100ProteinG = const Value.absent(),
    this.per100CarbsG = const Value.absent(),
    this.per100FatG = const Value.absent(),
    this.per100FiberG = const Value.absent(),
    this.entryServingAmount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalFoodsCompanion.insert({
    required String id,
    required int createdAt,
    required String updatedHlc,
    required int version,
    this.deletedAt = const Value.absent(),
    required String deviceId,
    required String origin,
    this.editedByUser = const Value.absent(),
    required String nameEn,
    this.nameAr = const Value.absent(),
    this.aliasesJson = const Value.absent(),
    this.brand = const Value.absent(),
    this.barcodesJson = const Value.absent(),
    this.per100ExtrasJson = const Value.absent(),
    this.servingsJson = const Value.absent(),
    this.entryServingUnit = const Value.absent(),
    required String createdFrom,
    required String state,
    required String basis,
    required double per100Kcal,
    required double per100ProteinG,
    required double per100CarbsG,
    required double per100FatG,
    required double per100FiberG,
    this.entryServingAmount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedHlc = Value(updatedHlc),
       version = Value(version),
       deviceId = Value(deviceId),
       origin = Value(origin),
       nameEn = Value(nameEn),
       createdFrom = Value(createdFrom),
       state = Value(state),
       basis = Value(basis),
       per100Kcal = Value(per100Kcal),
       per100ProteinG = Value(per100ProteinG),
       per100CarbsG = Value(per100CarbsG),
       per100FatG = Value(per100FatG),
       per100FiberG = Value(per100FiberG);
  static Insertable<PersonalFoodRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? updatedHlc,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<String>? origin,
    Expression<bool>? editedByUser,
    Expression<String>? nameEn,
    Expression<String>? nameAr,
    Expression<String>? aliasesJson,
    Expression<String>? brand,
    Expression<String>? barcodesJson,
    Expression<String>? per100ExtrasJson,
    Expression<String>? servingsJson,
    Expression<String>? entryServingUnit,
    Expression<String>? createdFrom,
    Expression<String>? state,
    Expression<String>? basis,
    Expression<double>? per100Kcal,
    Expression<double>? per100ProteinG,
    Expression<double>? per100CarbsG,
    Expression<double>? per100FatG,
    Expression<double>? per100FiberG,
    Expression<double>? entryServingAmount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedHlc != null) 'updated_hlc': updatedHlc,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (origin != null) 'origin': origin,
      if (editedByUser != null) 'edited_by_user': editedByUser,
      if (nameEn != null) 'name_en': nameEn,
      if (nameAr != null) 'name_ar': nameAr,
      if (aliasesJson != null) 'aliases_json': aliasesJson,
      if (brand != null) 'brand': brand,
      if (barcodesJson != null) 'barcodes_json': barcodesJson,
      if (per100ExtrasJson != null) 'per100_extras_json': per100ExtrasJson,
      if (servingsJson != null) 'servings_json': servingsJson,
      if (entryServingUnit != null) 'entry_serving_unit': entryServingUnit,
      if (createdFrom != null) 'created_from': createdFrom,
      if (state != null) 'state': state,
      if (basis != null) 'basis': basis,
      if (per100Kcal != null) 'per100_kcal': per100Kcal,
      if (per100ProteinG != null) 'per100_protein_g': per100ProteinG,
      if (per100CarbsG != null) 'per100_carbs_g': per100CarbsG,
      if (per100FatG != null) 'per100_fat_g': per100FatG,
      if (per100FiberG != null) 'per100_fiber_g': per100FiberG,
      if (entryServingAmount != null)
        'entry_serving_amount': entryServingAmount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalFoodsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<String>? updatedHlc,
    Value<int>? version,
    Value<int?>? deletedAt,
    Value<String>? deviceId,
    Value<String>? origin,
    Value<bool>? editedByUser,
    Value<String>? nameEn,
    Value<String?>? nameAr,
    Value<String?>? aliasesJson,
    Value<String?>? brand,
    Value<String?>? barcodesJson,
    Value<String?>? per100ExtrasJson,
    Value<String?>? servingsJson,
    Value<String?>? entryServingUnit,
    Value<String>? createdFrom,
    Value<String>? state,
    Value<String>? basis,
    Value<double>? per100Kcal,
    Value<double>? per100ProteinG,
    Value<double>? per100CarbsG,
    Value<double>? per100FatG,
    Value<double>? per100FiberG,
    Value<double?>? entryServingAmount,
    Value<int>? rowid,
  }) {
    return PersonalFoodsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedHlc: updatedHlc ?? this.updatedHlc,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      origin: origin ?? this.origin,
      editedByUser: editedByUser ?? this.editedByUser,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      aliasesJson: aliasesJson ?? this.aliasesJson,
      brand: brand ?? this.brand,
      barcodesJson: barcodesJson ?? this.barcodesJson,
      per100ExtrasJson: per100ExtrasJson ?? this.per100ExtrasJson,
      servingsJson: servingsJson ?? this.servingsJson,
      entryServingUnit: entryServingUnit ?? this.entryServingUnit,
      createdFrom: createdFrom ?? this.createdFrom,
      state: state ?? this.state,
      basis: basis ?? this.basis,
      per100Kcal: per100Kcal ?? this.per100Kcal,
      per100ProteinG: per100ProteinG ?? this.per100ProteinG,
      per100CarbsG: per100CarbsG ?? this.per100CarbsG,
      per100FatG: per100FatG ?? this.per100FatG,
      per100FiberG: per100FiberG ?? this.per100FiberG,
      entryServingAmount: entryServingAmount ?? this.entryServingAmount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedHlc.present) {
      map['updated_hlc'] = Variable<String>(updatedHlc.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (editedByUser.present) {
      map['edited_by_user'] = Variable<bool>(editedByUser.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (aliasesJson.present) {
      map['aliases_json'] = Variable<String>(aliasesJson.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (barcodesJson.present) {
      map['barcodes_json'] = Variable<String>(barcodesJson.value);
    }
    if (per100ExtrasJson.present) {
      map['per100_extras_json'] = Variable<String>(per100ExtrasJson.value);
    }
    if (servingsJson.present) {
      map['servings_json'] = Variable<String>(servingsJson.value);
    }
    if (entryServingUnit.present) {
      map['entry_serving_unit'] = Variable<String>(entryServingUnit.value);
    }
    if (createdFrom.present) {
      map['created_from'] = Variable<String>(createdFrom.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (basis.present) {
      map['basis'] = Variable<String>(basis.value);
    }
    if (per100Kcal.present) {
      map['per100_kcal'] = Variable<double>(per100Kcal.value);
    }
    if (per100ProteinG.present) {
      map['per100_protein_g'] = Variable<double>(per100ProteinG.value);
    }
    if (per100CarbsG.present) {
      map['per100_carbs_g'] = Variable<double>(per100CarbsG.value);
    }
    if (per100FatG.present) {
      map['per100_fat_g'] = Variable<double>(per100FatG.value);
    }
    if (per100FiberG.present) {
      map['per100_fiber_g'] = Variable<double>(per100FiberG.value);
    }
    if (entryServingAmount.present) {
      map['entry_serving_amount'] = Variable<double>(entryServingAmount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalFoodsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedHlc: $updatedHlc, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('origin: $origin, ')
          ..write('editedByUser: $editedByUser, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameAr: $nameAr, ')
          ..write('aliasesJson: $aliasesJson, ')
          ..write('brand: $brand, ')
          ..write('barcodesJson: $barcodesJson, ')
          ..write('per100ExtrasJson: $per100ExtrasJson, ')
          ..write('servingsJson: $servingsJson, ')
          ..write('entryServingUnit: $entryServingUnit, ')
          ..write('createdFrom: $createdFrom, ')
          ..write('state: $state, ')
          ..write('basis: $basis, ')
          ..write('per100Kcal: $per100Kcal, ')
          ..write('per100ProteinG: $per100ProteinG, ')
          ..write('per100CarbsG: $per100CarbsG, ')
          ..write('per100FatG: $per100FatG, ')
          ..write('per100FiberG: $per100FiberG, ')
          ..write('entryServingAmount: $entryServingAmount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncParkedTable extends SyncParked
    with TableInfo<$SyncParkedTable, SyncParkedRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncParkedTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parkedAtMeta = const VerificationMeta(
    'parkedAt',
  );
  @override
  late final GeneratedColumn<int> parkedAt = GeneratedColumn<int>(
    'parked_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entity, rowId, hlc, reason, parkedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_parked';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncParkedRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('parked_at')) {
      context.handle(
        _parkedAtMeta,
        parkedAt.isAcceptableOrUnknown(data['parked_at']!, _parkedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_parkedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, rowId, hlc};
  @override
  SyncParkedRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncParkedRow(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      parkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parked_at'],
      )!,
    );
  }

  @override
  $SyncParkedTable createAlias(String alias) {
    return $SyncParkedTable(attachedDatabase, alias);
  }
}

class SyncParkedRow extends DataClass implements Insertable<SyncParkedRow> {
  /// The entity wire name.
  final String entity;

  /// The row id.
  final String rowId;

  /// The parked version's HLC.
  final String hlc;

  /// A fixed reason code (`unsupported`, `invalidPayload`, `tooLarge`, a
  /// codec code, `unknown`), never a message.
  final String reason;

  /// When it was parked, UTC ms.
  final int parkedAt;
  const SyncParkedRow({
    required this.entity,
    required this.rowId,
    required this.hlc,
    required this.reason,
    required this.parkedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['row_id'] = Variable<String>(rowId);
    map['hlc'] = Variable<String>(hlc);
    map['reason'] = Variable<String>(reason);
    map['parked_at'] = Variable<int>(parkedAt);
    return map;
  }

  SyncParkedCompanion toCompanion(bool nullToAbsent) {
    return SyncParkedCompanion(
      entity: Value(entity),
      rowId: Value(rowId),
      hlc: Value(hlc),
      reason: Value(reason),
      parkedAt: Value(parkedAt),
    );
  }

  factory SyncParkedRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncParkedRow(
      entity: serializer.fromJson<String>(json['entity']),
      rowId: serializer.fromJson<String>(json['rowId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      reason: serializer.fromJson<String>(json['reason']),
      parkedAt: serializer.fromJson<int>(json['parkedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'rowId': serializer.toJson<String>(rowId),
      'hlc': serializer.toJson<String>(hlc),
      'reason': serializer.toJson<String>(reason),
      'parkedAt': serializer.toJson<int>(parkedAt),
    };
  }

  SyncParkedRow copyWith({
    String? entity,
    String? rowId,
    String? hlc,
    String? reason,
    int? parkedAt,
  }) => SyncParkedRow(
    entity: entity ?? this.entity,
    rowId: rowId ?? this.rowId,
    hlc: hlc ?? this.hlc,
    reason: reason ?? this.reason,
    parkedAt: parkedAt ?? this.parkedAt,
  );
  SyncParkedRow copyWithCompanion(SyncParkedCompanion data) {
    return SyncParkedRow(
      entity: data.entity.present ? data.entity.value : this.entity,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      reason: data.reason.present ? data.reason.value : this.reason,
      parkedAt: data.parkedAt.present ? data.parkedAt.value : this.parkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncParkedRow(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('hlc: $hlc, ')
          ..write('reason: $reason, ')
          ..write('parkedAt: $parkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, rowId, hlc, reason, parkedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncParkedRow &&
          other.entity == this.entity &&
          other.rowId == this.rowId &&
          other.hlc == this.hlc &&
          other.reason == this.reason &&
          other.parkedAt == this.parkedAt);
}

class SyncParkedCompanion extends UpdateCompanion<SyncParkedRow> {
  final Value<String> entity;
  final Value<String> rowId;
  final Value<String> hlc;
  final Value<String> reason;
  final Value<int> parkedAt;
  final Value<int> rowid;
  const SyncParkedCompanion({
    this.entity = const Value.absent(),
    this.rowId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.reason = const Value.absent(),
    this.parkedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncParkedCompanion.insert({
    required String entity,
    required String rowId,
    required String hlc,
    required String reason,
    required int parkedAt,
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       rowId = Value(rowId),
       hlc = Value(hlc),
       reason = Value(reason),
       parkedAt = Value(parkedAt);
  static Insertable<SyncParkedRow> custom({
    Expression<String>? entity,
    Expression<String>? rowId,
    Expression<String>? hlc,
    Expression<String>? reason,
    Expression<int>? parkedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (rowId != null) 'row_id': rowId,
      if (hlc != null) 'hlc': hlc,
      if (reason != null) 'reason': reason,
      if (parkedAt != null) 'parked_at': parkedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncParkedCompanion copyWith({
    Value<String>? entity,
    Value<String>? rowId,
    Value<String>? hlc,
    Value<String>? reason,
    Value<int>? parkedAt,
    Value<int>? rowid,
  }) {
    return SyncParkedCompanion(
      entity: entity ?? this.entity,
      rowId: rowId ?? this.rowId,
      hlc: hlc ?? this.hlc,
      reason: reason ?? this.reason,
      parkedAt: parkedAt ?? this.parkedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (parkedAt.present) {
      map['parked_at'] = Variable<int>(parkedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncParkedCompanion(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('hlc: $hlc, ')
          ..write('reason: $reason, ')
          ..write('parkedAt: $parkedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncDeferredTable extends SyncDeferred
    with TableInfo<$SyncDeferredTable, SyncDeferredRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncDeferredTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentJsonMeta = const VerificationMeta(
    'documentJson',
  );
  @override
  late final GeneratedColumn<String> documentJson = GeneratedColumn<String>(
    'document_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entity,
    rowId,
    hlc,
    documentJson,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_deferred';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncDeferredRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('document_json')) {
      context.handle(
        _documentJsonMeta,
        documentJson.isAcceptableOrUnknown(
          data['document_json']!,
          _documentJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentJsonMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, rowId, hlc};
  @override
  SyncDeferredRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncDeferredRow(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      documentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_json'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $SyncDeferredTable createAlias(String alias) {
    return $SyncDeferredTable(attachedDatabase, alias);
  }
}

class SyncDeferredRow extends DataClass implements Insertable<SyncDeferredRow> {
  /// The entity wire name.
  final String entity;

  /// The row id.
  final String rowId;

  /// The document's HLC.
  final String hlc;

  /// The document as pulled (JSON).
  final String documentJson;

  /// `unknownEntity`, `newerSchema` or `unreadable`.
  final String reason;
  const SyncDeferredRow({
    required this.entity,
    required this.rowId,
    required this.hlc,
    required this.documentJson,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['row_id'] = Variable<String>(rowId);
    map['hlc'] = Variable<String>(hlc);
    map['document_json'] = Variable<String>(documentJson);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  SyncDeferredCompanion toCompanion(bool nullToAbsent) {
    return SyncDeferredCompanion(
      entity: Value(entity),
      rowId: Value(rowId),
      hlc: Value(hlc),
      documentJson: Value(documentJson),
      reason: Value(reason),
    );
  }

  factory SyncDeferredRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncDeferredRow(
      entity: serializer.fromJson<String>(json['entity']),
      rowId: serializer.fromJson<String>(json['rowId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      documentJson: serializer.fromJson<String>(json['documentJson']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'rowId': serializer.toJson<String>(rowId),
      'hlc': serializer.toJson<String>(hlc),
      'documentJson': serializer.toJson<String>(documentJson),
      'reason': serializer.toJson<String>(reason),
    };
  }

  SyncDeferredRow copyWith({
    String? entity,
    String? rowId,
    String? hlc,
    String? documentJson,
    String? reason,
  }) => SyncDeferredRow(
    entity: entity ?? this.entity,
    rowId: rowId ?? this.rowId,
    hlc: hlc ?? this.hlc,
    documentJson: documentJson ?? this.documentJson,
    reason: reason ?? this.reason,
  );
  SyncDeferredRow copyWithCompanion(SyncDeferredCompanion data) {
    return SyncDeferredRow(
      entity: data.entity.present ? data.entity.value : this.entity,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      documentJson: data.documentJson.present
          ? data.documentJson.value
          : this.documentJson,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncDeferredRow(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('hlc: $hlc, ')
          ..write('documentJson: $documentJson, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, rowId, hlc, documentJson, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncDeferredRow &&
          other.entity == this.entity &&
          other.rowId == this.rowId &&
          other.hlc == this.hlc &&
          other.documentJson == this.documentJson &&
          other.reason == this.reason);
}

class SyncDeferredCompanion extends UpdateCompanion<SyncDeferredRow> {
  final Value<String> entity;
  final Value<String> rowId;
  final Value<String> hlc;
  final Value<String> documentJson;
  final Value<String> reason;
  final Value<int> rowid;
  const SyncDeferredCompanion({
    this.entity = const Value.absent(),
    this.rowId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.documentJson = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncDeferredCompanion.insert({
    required String entity,
    required String rowId,
    required String hlc,
    required String documentJson,
    required String reason,
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       rowId = Value(rowId),
       hlc = Value(hlc),
       documentJson = Value(documentJson),
       reason = Value(reason);
  static Insertable<SyncDeferredRow> custom({
    Expression<String>? entity,
    Expression<String>? rowId,
    Expression<String>? hlc,
    Expression<String>? documentJson,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (rowId != null) 'row_id': rowId,
      if (hlc != null) 'hlc': hlc,
      if (documentJson != null) 'document_json': documentJson,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncDeferredCompanion copyWith({
    Value<String>? entity,
    Value<String>? rowId,
    Value<String>? hlc,
    Value<String>? documentJson,
    Value<String>? reason,
    Value<int>? rowid,
  }) {
    return SyncDeferredCompanion(
      entity: entity ?? this.entity,
      rowId: rowId ?? this.rowId,
      hlc: hlc ?? this.hlc,
      documentJson: documentJson ?? this.documentJson,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (documentJson.present) {
      map['document_json'] = Variable<String>(documentJson.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncDeferredCompanion(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('hlc: $hlc, ')
          ..write('documentJson: $documentJson, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncDisplacedTable extends SyncDisplaced
    with TableInfo<$SyncDisplacedTable, SyncDisplacedRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncDisplacedTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowJsonMeta = const VerificationMeta(
    'rowJson',
  );
  @override
  late final GeneratedColumn<String> rowJson = GeneratedColumn<String>(
    'row_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parkedReasonMeta = const VerificationMeta(
    'parkedReason',
  );
  @override
  late final GeneratedColumn<String> parkedReason = GeneratedColumn<String>(
    'parked_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entity,
    rowId,
    hlc,
    rowJson,
    parkedReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_displaced';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncDisplacedRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('row_json')) {
      context.handle(
        _rowJsonMeta,
        rowJson.isAcceptableOrUnknown(data['row_json']!, _rowJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rowJsonMeta);
    }
    if (data.containsKey('parked_reason')) {
      context.handle(
        _parkedReasonMeta,
        parkedReason.isAcceptableOrUnknown(
          data['parked_reason']!,
          _parkedReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, rowId, hlc};
  @override
  SyncDisplacedRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncDisplacedRow(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      rowJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_json'],
      )!,
      parkedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parked_reason'],
      ),
    );
  }

  @override
  $SyncDisplacedTable createAlias(String alias) {
    return $SyncDisplacedTable(attachedDatabase, alias);
  }
}

class SyncDisplacedRow extends DataClass
    implements Insertable<SyncDisplacedRow> {
  /// The entity wire name.
  final String entity;

  /// The row id.
  final String rowId;

  /// The displaced version's HLC.
  final String hlc;

  /// The row as it was (SQL column → raw value, JSON).
  final String rowJson;

  /// The parked reason when the server or the encoder refused it; `null`
  /// while it waits to be pushed.
  final String? parkedReason;
  const SyncDisplacedRow({
    required this.entity,
    required this.rowId,
    required this.hlc,
    required this.rowJson,
    this.parkedReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['row_id'] = Variable<String>(rowId);
    map['hlc'] = Variable<String>(hlc);
    map['row_json'] = Variable<String>(rowJson);
    if (!nullToAbsent || parkedReason != null) {
      map['parked_reason'] = Variable<String>(parkedReason);
    }
    return map;
  }

  SyncDisplacedCompanion toCompanion(bool nullToAbsent) {
    return SyncDisplacedCompanion(
      entity: Value(entity),
      rowId: Value(rowId),
      hlc: Value(hlc),
      rowJson: Value(rowJson),
      parkedReason: parkedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(parkedReason),
    );
  }

  factory SyncDisplacedRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncDisplacedRow(
      entity: serializer.fromJson<String>(json['entity']),
      rowId: serializer.fromJson<String>(json['rowId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      rowJson: serializer.fromJson<String>(json['rowJson']),
      parkedReason: serializer.fromJson<String?>(json['parkedReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'rowId': serializer.toJson<String>(rowId),
      'hlc': serializer.toJson<String>(hlc),
      'rowJson': serializer.toJson<String>(rowJson),
      'parkedReason': serializer.toJson<String?>(parkedReason),
    };
  }

  SyncDisplacedRow copyWith({
    String? entity,
    String? rowId,
    String? hlc,
    String? rowJson,
    Value<String?> parkedReason = const Value.absent(),
  }) => SyncDisplacedRow(
    entity: entity ?? this.entity,
    rowId: rowId ?? this.rowId,
    hlc: hlc ?? this.hlc,
    rowJson: rowJson ?? this.rowJson,
    parkedReason: parkedReason.present ? parkedReason.value : this.parkedReason,
  );
  SyncDisplacedRow copyWithCompanion(SyncDisplacedCompanion data) {
    return SyncDisplacedRow(
      entity: data.entity.present ? data.entity.value : this.entity,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      rowJson: data.rowJson.present ? data.rowJson.value : this.rowJson,
      parkedReason: data.parkedReason.present
          ? data.parkedReason.value
          : this.parkedReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncDisplacedRow(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('hlc: $hlc, ')
          ..write('rowJson: $rowJson, ')
          ..write('parkedReason: $parkedReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, rowId, hlc, rowJson, parkedReason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncDisplacedRow &&
          other.entity == this.entity &&
          other.rowId == this.rowId &&
          other.hlc == this.hlc &&
          other.rowJson == this.rowJson &&
          other.parkedReason == this.parkedReason);
}

class SyncDisplacedCompanion extends UpdateCompanion<SyncDisplacedRow> {
  final Value<String> entity;
  final Value<String> rowId;
  final Value<String> hlc;
  final Value<String> rowJson;
  final Value<String?> parkedReason;
  final Value<int> rowid;
  const SyncDisplacedCompanion({
    this.entity = const Value.absent(),
    this.rowId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.rowJson = const Value.absent(),
    this.parkedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncDisplacedCompanion.insert({
    required String entity,
    required String rowId,
    required String hlc,
    required String rowJson,
    this.parkedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       rowId = Value(rowId),
       hlc = Value(hlc),
       rowJson = Value(rowJson);
  static Insertable<SyncDisplacedRow> custom({
    Expression<String>? entity,
    Expression<String>? rowId,
    Expression<String>? hlc,
    Expression<String>? rowJson,
    Expression<String>? parkedReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (rowId != null) 'row_id': rowId,
      if (hlc != null) 'hlc': hlc,
      if (rowJson != null) 'row_json': rowJson,
      if (parkedReason != null) 'parked_reason': parkedReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncDisplacedCompanion copyWith({
    Value<String>? entity,
    Value<String>? rowId,
    Value<String>? hlc,
    Value<String>? rowJson,
    Value<String?>? parkedReason,
    Value<int>? rowid,
  }) {
    return SyncDisplacedCompanion(
      entity: entity ?? this.entity,
      rowId: rowId ?? this.rowId,
      hlc: hlc ?? this.hlc,
      rowJson: rowJson ?? this.rowJson,
      parkedReason: parkedReason ?? this.parkedReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (rowJson.present) {
      map['row_json'] = Variable<String>(rowJson.value);
    }
    if (parkedReason.present) {
      map['parked_reason'] = Variable<String>(parkedReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncDisplacedCompanion(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('hlc: $hlc, ')
          ..write('rowJson: $rowJson, ')
          ..write('parkedReason: $parkedReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(
    this,
  );
  late final Index ixWorkoutSessionsDate = Index(
    'ix_workout_sessions_date',
    'CREATE INDEX ix_workout_sessions_date ON workout_sessions (local_date, id) WHERE deleted_at IS NULL',
  );
  late final $SessionExercisesTable sessionExercises = $SessionExercisesTable(
    this,
  );
  late final Index ixSessionExercisesSession = Index(
    'ix_session_exercises_session',
    'CREATE INDEX ix_session_exercises_session ON session_exercises (session_id, position) WHERE deleted_at IS NULL',
  );
  late final Index ixSessionExercisesExercise = Index(
    'ix_session_exercises_exercise',
    'CREATE INDEX ix_session_exercises_exercise ON session_exercises (exercise_id) WHERE deleted_at IS NULL',
  );
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final Index ixWorkoutSetsExercise = Index(
    'ix_workout_sets_exercise',
    'CREATE INDEX ix_workout_sets_exercise ON workout_sets (session_exercise_id, position) WHERE deleted_at IS NULL',
  );
  late final $WorkoutTemplateItemsTable workoutTemplateItems =
      $WorkoutTemplateItemsTable(this);
  late final Index ixWorkoutTemplateItemsTemplate = Index(
    'ix_workout_template_items_template',
    'CREATE INDEX ix_workout_template_items_template ON workout_template_items (template_id, position) WHERE deleted_at IS NULL',
  );
  late final $WeeklyPlanDaysTable weeklyPlanDays = $WeeklyPlanDaysTable(this);
  late final Index uxWeeklyPlanDaysWeekday = Index(
    'ux_weekly_plan_days_weekday',
    'CREATE UNIQUE INDEX ux_weekly_plan_days_weekday ON weekly_plan_days (weekday) WHERE deleted_at IS NULL',
  );
  late final $CustomExercisesTable customExercises = $CustomExercisesTable(
    this,
  );
  late final $WorkoutTemplatesTable workoutTemplates = $WorkoutTemplatesTable(
    this,
  );
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final Index ixChatMessagesOrder = Index(
    'ix_chat_messages_order',
    'CREATE INDEX ix_chat_messages_order ON chat_messages (created_at, id) WHERE deleted_at IS NULL',
  );
  late final Index ixChatMessagesReply = Index(
    'ix_chat_messages_reply',
    'CREATE INDEX ix_chat_messages_reply ON chat_messages (reply_to_message_id) WHERE reply_to_message_id IS NOT NULL AND deleted_at IS NULL',
  );
  late final $ProposalsTable proposals = $ProposalsTable(this);
  late final Index ixProposalsBudget = Index(
    'ix_proposals_budget',
    'CREATE INDEX ix_proposals_budget ON proposals (budget_message_id) WHERE deleted_at IS NULL',
  );
  late final Index ixProposalsPending = Index(
    'ix_proposals_pending',
    'CREATE INDEX ix_proposals_pending ON proposals (created_at) WHERE status = \'pending\' AND deleted_at IS NULL',
  );
  late final Index ixProposalsKind = Index(
    'ix_proposals_kind',
    'CREATE INDEX ix_proposals_kind ON proposals (kind) WHERE deleted_at IS NULL',
  );
  late final $WeighInsTable weighIns = $WeighInsTable(this);
  late final Index ixWeighInsLive = Index(
    'ix_weigh_ins_live',
    'CREATE INDEX ix_weigh_ins_live ON weigh_ins (local_date, measured_at_utc) WHERE deleted_at IS NULL',
  );
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final Index ixMeasurementsLive = Index(
    'ix_measurements_live',
    'CREATE INDEX ix_measurements_live ON measurements (kind, custom_type_id, local_date, measured_at_utc) WHERE deleted_at IS NULL',
  );
  late final $MeasurementTypesTable measurementTypes = $MeasurementTypesTable(
    this,
  );
  late final $GoalPhasesTable goalPhases = $GoalPhasesTable(this);
  late final Index ixGoalPhasesStart = Index(
    'ix_goal_phases_start',
    'CREATE INDEX ix_goal_phases_start ON goal_phases (start_date) WHERE deleted_at IS NULL',
  );
  late final $TargetSettingsRowsTable targetSettingsRows =
      $TargetSettingsRowsTable(this);
  late final Index ixTargetSettingsEffective = Index(
    'ix_target_settings_effective',
    'CREATE INDEX ix_target_settings_effective ON target_settings (effective_from) WHERE deleted_at IS NULL',
  );
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $DiaryEntriesTable diaryEntries = $DiaryEntriesTable(this);
  late final Index ixDiaryEntriesLive = Index(
    'ix_diary_entries_live',
    'CREATE INDEX ix_diary_entries_live ON diary_entries (local_date, slot_id) WHERE deleted_at IS NULL',
  );
  late final Index ixDiaryEntriesGroup = Index(
    'ix_diary_entries_group',
    'CREATE INDEX ix_diary_entries_group ON diary_entries (dish_group_id) WHERE dish_group_id IS NOT NULL AND deleted_at IS NULL',
  );
  late final $DishGroupsTable dishGroups = $DishGroupsTable(this);
  late final Index ixDishGroupsLive = Index(
    'ix_dish_groups_live',
    'CREATE INDEX ix_dish_groups_live ON dish_groups (local_date) WHERE deleted_at IS NULL',
  );
  late final $SavedMealItemsTable savedMealItems = $SavedMealItemsTable(this);
  late final Index ixSavedMealItemsMeal = Index(
    'ix_saved_meal_items_meal',
    'CREATE INDEX ix_saved_meal_items_meal ON saved_meal_items (saved_meal_id) WHERE deleted_at IS NULL',
  );
  late final $DayMarksTable dayMarks = $DayMarksTable(this);
  late final Index ixDayMarksDate = Index(
    'ix_day_marks_date',
    'CREATE INDEX ix_day_marks_date ON day_marks (local_date) WHERE deleted_at IS NULL',
  );
  late final Index ixDiaryEntriesFood = Index(
    'ix_diary_entries_food',
    'CREATE INDEX ix_diary_entries_food ON diary_entries (food_kind, food_id) WHERE deleted_at IS NULL',
  );
  late final Index ixSavedMealItemsFood = Index(
    'ix_saved_meal_items_food',
    'CREATE INDEX ix_saved_meal_items_food ON saved_meal_items (food_kind, food_id) WHERE deleted_at IS NULL',
  );
  late final $MealSlotsTable mealSlots = $MealSlotsTable(this);
  late final $SavedMealsTable savedMeals = $SavedMealsTable(this);
  late final $SettingsKvTable settingsKv = $SettingsKvTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final Trigger settingsKvOutboxAi = Trigger(
    'CREATE TRIGGER settings_kv_outbox_ai AFTER INSERT ON settings_kv WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'setting\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'settings_kv_outbox_ai',
  );
  late final Trigger settingsKvOutboxAu = Trigger(
    'CREATE TRIGGER settings_kv_outbox_au AFTER UPDATE ON settings_kv WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'setting\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'settings_kv_outbox_au',
  );
  late final Trigger settingsKvNoDelete = Trigger(
    'CREATE TRIGGER settings_kv_no_delete BEFORE DELETE ON settings_kv BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'settings_kv_no_delete',
  );
  late final Trigger mealSlotsOutboxAi = Trigger(
    'CREATE TRIGGER meal_slots_outbox_ai AFTER INSERT ON meal_slots WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'mealSlot\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'meal_slots_outbox_ai',
  );
  late final Trigger mealSlotsOutboxAu = Trigger(
    'CREATE TRIGGER meal_slots_outbox_au AFTER UPDATE ON meal_slots WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'mealSlot\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'meal_slots_outbox_au',
  );
  late final Trigger mealSlotsNoDelete = Trigger(
    'CREATE TRIGGER meal_slots_no_delete BEFORE DELETE ON meal_slots BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'meal_slots_no_delete',
  );
  late final Trigger dishGroupsOutboxAi = Trigger(
    'CREATE TRIGGER dish_groups_outbox_ai AFTER INSERT ON dish_groups WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'dishGroup\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'dish_groups_outbox_ai',
  );
  late final Trigger dishGroupsOutboxAu = Trigger(
    'CREATE TRIGGER dish_groups_outbox_au AFTER UPDATE ON dish_groups WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'dishGroup\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'dish_groups_outbox_au',
  );
  late final Trigger dishGroupsNoDelete = Trigger(
    'CREATE TRIGGER dish_groups_no_delete BEFORE DELETE ON dish_groups BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'dish_groups_no_delete',
  );
  late final Trigger diaryEntriesOutboxAi = Trigger(
    'CREATE TRIGGER diary_entries_outbox_ai AFTER INSERT ON diary_entries WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'diaryEntry\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'diary_entries_outbox_ai',
  );
  late final Trigger diaryEntriesOutboxAu = Trigger(
    'CREATE TRIGGER diary_entries_outbox_au AFTER UPDATE ON diary_entries WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'diaryEntry\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'diary_entries_outbox_au',
  );
  late final Trigger diaryEntriesNoDelete = Trigger(
    'CREATE TRIGGER diary_entries_no_delete BEFORE DELETE ON diary_entries BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'diary_entries_no_delete',
  );
  late final Trigger dayMarksOutboxAi = Trigger(
    'CREATE TRIGGER day_marks_outbox_ai AFTER INSERT ON day_marks WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'dayMark\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'day_marks_outbox_ai',
  );
  late final Trigger dayMarksOutboxAu = Trigger(
    'CREATE TRIGGER day_marks_outbox_au AFTER UPDATE ON day_marks WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'dayMark\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'day_marks_outbox_au',
  );
  late final Trigger dayMarksNoDelete = Trigger(
    'CREATE TRIGGER day_marks_no_delete BEFORE DELETE ON day_marks BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'day_marks_no_delete',
  );
  late final Trigger savedMealsOutboxAi = Trigger(
    'CREATE TRIGGER saved_meals_outbox_ai AFTER INSERT ON saved_meals WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'savedMeal\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'saved_meals_outbox_ai',
  );
  late final Trigger savedMealsOutboxAu = Trigger(
    'CREATE TRIGGER saved_meals_outbox_au AFTER UPDATE ON saved_meals WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'savedMeal\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'saved_meals_outbox_au',
  );
  late final Trigger savedMealsNoDelete = Trigger(
    'CREATE TRIGGER saved_meals_no_delete BEFORE DELETE ON saved_meals BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'saved_meals_no_delete',
  );
  late final Trigger savedMealItemsOutboxAi = Trigger(
    'CREATE TRIGGER saved_meal_items_outbox_ai AFTER INSERT ON saved_meal_items WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'savedMealItem\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'saved_meal_items_outbox_ai',
  );
  late final Trigger savedMealItemsOutboxAu = Trigger(
    'CREATE TRIGGER saved_meal_items_outbox_au AFTER UPDATE ON saved_meal_items WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'savedMealItem\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'saved_meal_items_outbox_au',
  );
  late final Trigger savedMealItemsNoDelete = Trigger(
    'CREATE TRIGGER saved_meal_items_no_delete BEFORE DELETE ON saved_meal_items BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'saved_meal_items_no_delete',
  );
  late final $PersonalFoodsTable personalFoods = $PersonalFoodsTable(this);
  late final Trigger personalFoodsOutboxAi = Trigger(
    'CREATE TRIGGER personal_foods_outbox_ai AFTER INSERT ON personal_foods WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'personalFood\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'personal_foods_outbox_ai',
  );
  late final Trigger personalFoodsOutboxAu = Trigger(
    'CREATE TRIGGER personal_foods_outbox_au AFTER UPDATE ON personal_foods WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'personalFood\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'personal_foods_outbox_au',
  );
  late final Trigger personalFoodsNoDelete = Trigger(
    'CREATE TRIGGER personal_foods_no_delete BEFORE DELETE ON personal_foods BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'personal_foods_no_delete',
  );
  late final Trigger profileOutboxAi = Trigger(
    'CREATE TRIGGER profile_outbox_ai AFTER INSERT ON profile WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'profile\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'profile_outbox_ai',
  );
  late final Trigger profileOutboxAu = Trigger(
    'CREATE TRIGGER profile_outbox_au AFTER UPDATE ON profile WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'profile\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'profile_outbox_au',
  );
  late final Trigger profileNoDelete = Trigger(
    'CREATE TRIGGER profile_no_delete BEFORE DELETE ON profile BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'profile_no_delete',
  );
  late final Trigger goalPhasesOutboxAi = Trigger(
    'CREATE TRIGGER goal_phases_outbox_ai AFTER INSERT ON goal_phases WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'goalPhase\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'goal_phases_outbox_ai',
  );
  late final Trigger goalPhasesOutboxAu = Trigger(
    'CREATE TRIGGER goal_phases_outbox_au AFTER UPDATE ON goal_phases WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'goalPhase\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'goal_phases_outbox_au',
  );
  late final Trigger goalPhasesNoDelete = Trigger(
    'CREATE TRIGGER goal_phases_no_delete BEFORE DELETE ON goal_phases BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'goal_phases_no_delete',
  );
  late final Trigger targetSettingsOutboxAi = Trigger(
    'CREATE TRIGGER target_settings_outbox_ai AFTER INSERT ON target_settings WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'targetSettings\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'target_settings_outbox_ai',
  );
  late final Trigger targetSettingsOutboxAu = Trigger(
    'CREATE TRIGGER target_settings_outbox_au AFTER UPDATE ON target_settings WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'targetSettings\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'target_settings_outbox_au',
  );
  late final Trigger targetSettingsNoDelete = Trigger(
    'CREATE TRIGGER target_settings_no_delete BEFORE DELETE ON target_settings BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'target_settings_no_delete',
  );
  late final Trigger weighInsOutboxAi = Trigger(
    'CREATE TRIGGER weigh_ins_outbox_ai AFTER INSERT ON weigh_ins WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'weighIn\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'weigh_ins_outbox_ai',
  );
  late final Trigger weighInsOutboxAu = Trigger(
    'CREATE TRIGGER weigh_ins_outbox_au AFTER UPDATE ON weigh_ins WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'weighIn\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'weigh_ins_outbox_au',
  );
  late final Trigger weighInsNoDelete = Trigger(
    'CREATE TRIGGER weigh_ins_no_delete BEFORE DELETE ON weigh_ins BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'weigh_ins_no_delete',
  );
  late final Trigger measurementTypesOutboxAi = Trigger(
    'CREATE TRIGGER measurement_types_outbox_ai AFTER INSERT ON measurement_types WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'measurementType\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'measurement_types_outbox_ai',
  );
  late final Trigger measurementTypesOutboxAu = Trigger(
    'CREATE TRIGGER measurement_types_outbox_au AFTER UPDATE ON measurement_types WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'measurementType\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'measurement_types_outbox_au',
  );
  late final Trigger measurementTypesNoDelete = Trigger(
    'CREATE TRIGGER measurement_types_no_delete BEFORE DELETE ON measurement_types BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'measurement_types_no_delete',
  );
  late final Trigger measurementsOutboxAi = Trigger(
    'CREATE TRIGGER measurements_outbox_ai AFTER INSERT ON measurements WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'measurement\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'measurements_outbox_ai',
  );
  late final Trigger measurementsOutboxAu = Trigger(
    'CREATE TRIGGER measurements_outbox_au AFTER UPDATE ON measurements WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'measurement\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'measurements_outbox_au',
  );
  late final Trigger measurementsNoDelete = Trigger(
    'CREATE TRIGGER measurements_no_delete BEFORE DELETE ON measurements BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'measurements_no_delete',
  );
  late final Trigger chatMessagesOutboxAi = Trigger(
    'CREATE TRIGGER chat_messages_outbox_ai AFTER INSERT ON chat_messages WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'chatMessage\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'chat_messages_outbox_ai',
  );
  late final Trigger chatMessagesOutboxAu = Trigger(
    'CREATE TRIGGER chat_messages_outbox_au AFTER UPDATE ON chat_messages WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'chatMessage\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'chat_messages_outbox_au',
  );
  late final Trigger chatMessagesNoDelete = Trigger(
    'CREATE TRIGGER chat_messages_no_delete BEFORE DELETE ON chat_messages BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'chat_messages_no_delete',
  );
  late final Trigger customExercisesOutboxAi = Trigger(
    'CREATE TRIGGER custom_exercises_outbox_ai AFTER INSERT ON custom_exercises WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'customExercise\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'custom_exercises_outbox_ai',
  );
  late final Trigger customExercisesOutboxAu = Trigger(
    'CREATE TRIGGER custom_exercises_outbox_au AFTER UPDATE ON custom_exercises WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'customExercise\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'custom_exercises_outbox_au',
  );
  late final Trigger customExercisesNoDelete = Trigger(
    'CREATE TRIGGER custom_exercises_no_delete BEFORE DELETE ON custom_exercises BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'custom_exercises_no_delete',
  );
  late final Trigger workoutSessionsOutboxAi = Trigger(
    'CREATE TRIGGER workout_sessions_outbox_ai AFTER INSERT ON workout_sessions WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'workoutSession\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'workout_sessions_outbox_ai',
  );
  late final Trigger workoutSessionsOutboxAu = Trigger(
    'CREATE TRIGGER workout_sessions_outbox_au AFTER UPDATE ON workout_sessions WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'workoutSession\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'workout_sessions_outbox_au',
  );
  late final Trigger workoutSessionsNoDelete = Trigger(
    'CREATE TRIGGER workout_sessions_no_delete BEFORE DELETE ON workout_sessions BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'workout_sessions_no_delete',
  );
  late final Trigger sessionExercisesOutboxAi = Trigger(
    'CREATE TRIGGER session_exercises_outbox_ai AFTER INSERT ON session_exercises WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'sessionExercise\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'session_exercises_outbox_ai',
  );
  late final Trigger sessionExercisesOutboxAu = Trigger(
    'CREATE TRIGGER session_exercises_outbox_au AFTER UPDATE ON session_exercises WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'sessionExercise\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'session_exercises_outbox_au',
  );
  late final Trigger sessionExercisesNoDelete = Trigger(
    'CREATE TRIGGER session_exercises_no_delete BEFORE DELETE ON session_exercises BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'session_exercises_no_delete',
  );
  late final Trigger workoutSetsOutboxAi = Trigger(
    'CREATE TRIGGER workout_sets_outbox_ai AFTER INSERT ON workout_sets WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'workoutSet\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'workout_sets_outbox_ai',
  );
  late final Trigger workoutSetsOutboxAu = Trigger(
    'CREATE TRIGGER workout_sets_outbox_au AFTER UPDATE ON workout_sets WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'workoutSet\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'workout_sets_outbox_au',
  );
  late final Trigger workoutSetsNoDelete = Trigger(
    'CREATE TRIGGER workout_sets_no_delete BEFORE DELETE ON workout_sets BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'workout_sets_no_delete',
  );
  late final Trigger workoutTemplatesOutboxAi = Trigger(
    'CREATE TRIGGER workout_templates_outbox_ai AFTER INSERT ON workout_templates WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'workoutTemplate\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'workout_templates_outbox_ai',
  );
  late final Trigger workoutTemplatesOutboxAu = Trigger(
    'CREATE TRIGGER workout_templates_outbox_au AFTER UPDATE ON workout_templates WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'workoutTemplate\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'workout_templates_outbox_au',
  );
  late final Trigger workoutTemplatesNoDelete = Trigger(
    'CREATE TRIGGER workout_templates_no_delete BEFORE DELETE ON workout_templates BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'workout_templates_no_delete',
  );
  late final Trigger workoutTemplateItemsOutboxAi = Trigger(
    'CREATE TRIGGER workout_template_items_outbox_ai AFTER INSERT ON workout_template_items WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'workoutTemplateItem\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'workout_template_items_outbox_ai',
  );
  late final Trigger workoutTemplateItemsOutboxAu = Trigger(
    'CREATE TRIGGER workout_template_items_outbox_au AFTER UPDATE ON workout_template_items WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'workoutTemplateItem\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'workout_template_items_outbox_au',
  );
  late final Trigger workoutTemplateItemsNoDelete = Trigger(
    'CREATE TRIGGER workout_template_items_no_delete BEFORE DELETE ON workout_template_items BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'workout_template_items_no_delete',
  );
  late final Trigger weeklyPlanDaysOutboxAi = Trigger(
    'CREATE TRIGGER weekly_plan_days_outbox_ai AFTER INSERT ON weekly_plan_days WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'weeklyPlanDay\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'weekly_plan_days_outbox_ai',
  );
  late final Trigger weeklyPlanDaysOutboxAu = Trigger(
    'CREATE TRIGGER weekly_plan_days_outbox_au AFTER UPDATE ON weekly_plan_days WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'weeklyPlanDay\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'weekly_plan_days_outbox_au',
  );
  late final Trigger weeklyPlanDaysNoDelete = Trigger(
    'CREATE TRIGGER weekly_plan_days_no_delete BEFORE DELETE ON weekly_plan_days BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'weekly_plan_days_no_delete',
  );
  late final Trigger proposalsOutboxAi = Trigger(
    'CREATE TRIGGER proposals_outbox_ai AFTER INSERT ON proposals WHEN (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'proposal\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'proposals_outbox_ai',
  );
  late final Trigger proposalsOutboxAu = Trigger(
    'CREATE TRIGGER proposals_outbox_au AFTER UPDATE ON proposals WHEN NEW.updated_hlc IS NOT OLD.updated_hlc AND (SELECT value FROM sync_state WHERE "key" = \'outbox.capture\') IS NOT \'0\' BEGIN INSERT INTO sync_outbox (entity, row_id, hlc, deleted) VALUES (\'proposal\', NEW.id, NEW.updated_hlc, NEW.deleted_at IS NOT NULL);END',
    'proposals_outbox_au',
  );
  late final Trigger proposalsNoDelete = Trigger(
    'CREATE TRIGGER proposals_no_delete BEFORE DELETE ON proposals BEGIN SELECT RAISE (ABORT, \'tombstone, never delete\');END',
    'proposals_no_delete',
  );
  late final $SyncParkedTable syncParked = $SyncParkedTable(this);
  late final $SyncDeferredTable syncDeferred = $SyncDeferredTable(this);
  late final $SyncDisplacedTable syncDisplaced = $SyncDisplacedTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workoutSessions,
    ixWorkoutSessionsDate,
    sessionExercises,
    ixSessionExercisesSession,
    ixSessionExercisesExercise,
    workoutSets,
    ixWorkoutSetsExercise,
    workoutTemplateItems,
    ixWorkoutTemplateItemsTemplate,
    weeklyPlanDays,
    uxWeeklyPlanDaysWeekday,
    customExercises,
    workoutTemplates,
    chatMessages,
    ixChatMessagesOrder,
    ixChatMessagesReply,
    proposals,
    ixProposalsBudget,
    ixProposalsPending,
    ixProposalsKind,
    weighIns,
    ixWeighInsLive,
    measurements,
    ixMeasurementsLive,
    measurementTypes,
    goalPhases,
    ixGoalPhasesStart,
    targetSettingsRows,
    ixTargetSettingsEffective,
    profiles,
    diaryEntries,
    ixDiaryEntriesLive,
    ixDiaryEntriesGroup,
    dishGroups,
    ixDishGroupsLive,
    savedMealItems,
    ixSavedMealItemsMeal,
    dayMarks,
    ixDayMarksDate,
    ixDiaryEntriesFood,
    ixSavedMealItemsFood,
    mealSlots,
    savedMeals,
    settingsKv,
    syncState,
    syncOutbox,
    settingsKvOutboxAi,
    settingsKvOutboxAu,
    settingsKvNoDelete,
    mealSlotsOutboxAi,
    mealSlotsOutboxAu,
    mealSlotsNoDelete,
    dishGroupsOutboxAi,
    dishGroupsOutboxAu,
    dishGroupsNoDelete,
    diaryEntriesOutboxAi,
    diaryEntriesOutboxAu,
    diaryEntriesNoDelete,
    dayMarksOutboxAi,
    dayMarksOutboxAu,
    dayMarksNoDelete,
    savedMealsOutboxAi,
    savedMealsOutboxAu,
    savedMealsNoDelete,
    savedMealItemsOutboxAi,
    savedMealItemsOutboxAu,
    savedMealItemsNoDelete,
    personalFoods,
    personalFoodsOutboxAi,
    personalFoodsOutboxAu,
    personalFoodsNoDelete,
    profileOutboxAi,
    profileOutboxAu,
    profileNoDelete,
    goalPhasesOutboxAi,
    goalPhasesOutboxAu,
    goalPhasesNoDelete,
    targetSettingsOutboxAi,
    targetSettingsOutboxAu,
    targetSettingsNoDelete,
    weighInsOutboxAi,
    weighInsOutboxAu,
    weighInsNoDelete,
    measurementTypesOutboxAi,
    measurementTypesOutboxAu,
    measurementTypesNoDelete,
    measurementsOutboxAi,
    measurementsOutboxAu,
    measurementsNoDelete,
    chatMessagesOutboxAi,
    chatMessagesOutboxAu,
    chatMessagesNoDelete,
    customExercisesOutboxAi,
    customExercisesOutboxAu,
    customExercisesNoDelete,
    workoutSessionsOutboxAi,
    workoutSessionsOutboxAu,
    workoutSessionsNoDelete,
    sessionExercisesOutboxAi,
    sessionExercisesOutboxAu,
    sessionExercisesNoDelete,
    workoutSetsOutboxAi,
    workoutSetsOutboxAu,
    workoutSetsNoDelete,
    workoutTemplatesOutboxAi,
    workoutTemplatesOutboxAu,
    workoutTemplatesNoDelete,
    workoutTemplateItemsOutboxAi,
    workoutTemplateItemsOutboxAu,
    workoutTemplateItemsNoDelete,
    weeklyPlanDaysOutboxAi,
    weeklyPlanDaysOutboxAu,
    weeklyPlanDaysNoDelete,
    proposalsOutboxAi,
    proposalsOutboxAu,
    proposalsNoDelete,
    syncParked,
    syncDeferred,
    syncDisplaced,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'settings_kv',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'settings_kv',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'settings_kv',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'meal_slots',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'meal_slots',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'meal_slots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dish_groups',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dish_groups',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dish_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'diary_entries',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'diary_entries',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'diary_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'day_marks',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'day_marks',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'day_marks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_meals',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_meals',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_meals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_meal_items',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_meal_items',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_meal_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'personal_foods',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'personal_foods',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'personal_foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profile',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profile',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'profile',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'goal_phases',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'goal_phases',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'goal_phases',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'target_settings',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'target_settings',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'target_settings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'weigh_ins',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'weigh_ins',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'weigh_ins',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'measurement_types',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'measurement_types',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'measurement_types',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'measurements',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'measurements',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'measurements',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chat_messages',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chat_messages',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chat_messages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_exercises',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_exercises',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sessions',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sessions',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_exercises',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_exercises',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sets',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sets',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_templates',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_templates',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_templates',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_template_items',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_template_items',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_template_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'weekly_plan_days',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'weekly_plan_days',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'weekly_plan_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'proposals',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'proposals',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_outbox', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'proposals',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
  ]);
}
