// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
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
          ..write('budgetJson: $budgetJson')
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
          other.budgetJson == this.budgetJson);
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final Index ixChatMessagesOrder = Index(
    'ix_chat_messages_order',
    'CREATE INDEX ix_chat_messages_order ON chat_messages (created_at, id) WHERE deleted_at IS NULL',
  );
  late final Index ixChatMessagesReply = Index(
    'ix_chat_messages_reply',
    'CREATE INDEX ix_chat_messages_reply ON chat_messages (reply_to_message_id) WHERE reply_to_message_id IS NOT NULL AND deleted_at IS NULL',
  );
  late final $WeighInsTable weighIns = $WeighInsTable(this);
  late final Index ixWeighInsLive = Index(
    'ix_weigh_ins_live',
    'CREATE INDEX ix_weigh_ins_live ON weigh_ins (local_date, measured_at_utc) WHERE deleted_at IS NULL',
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    chatMessages,
    ixChatMessagesOrder,
    ixChatMessagesReply,
    weighIns,
    ixWeighInsLive,
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
    chatMessagesOutboxAi,
    chatMessagesOutboxAu,
    chatMessagesNoDelete,
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
  ]);
}
