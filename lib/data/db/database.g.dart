// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LinkedAccountsTable extends LinkedAccounts
    with TableInfo<$LinkedAccountsTable, LinkedAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LinkedAccountsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerAccountIdMeta = const VerificationMeta(
    'providerAccountId',
  );
  @override
  late final GeneratedColumn<String> providerAccountId =
      GeneratedColumn<String>(
        'provider_account_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _quotaTotalMeta = const VerificationMeta(
    'quotaTotal',
  );
  @override
  late final GeneratedColumn<int> quotaTotal = GeneratedColumn<int>(
    'quota_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotaUsedMeta = const VerificationMeta(
    'quotaUsed',
  );
  @override
  late final GeneratedColumn<int> quotaUsed = GeneratedColumn<int>(
    'quota_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quotaSyncedAtMeta = const VerificationMeta(
    'quotaSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> quotaSyncedAt =
      GeneratedColumn<DateTime>(
        'quota_synced_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncCursorMeta = const VerificationMeta(
    'syncCursor',
  );
  @override
  late final GeneratedColumn<String> syncCursor = GeneratedColumn<String>(
    'sync_cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    provider,
    providerAccountId,
    displayName,
    status,
    quotaTotal,
    quotaUsed,
    quotaSyncedAt,
    syncCursor,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'linked_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LinkedAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('provider_account_id')) {
      context.handle(
        _providerAccountIdMeta,
        providerAccountId.isAcceptableOrUnknown(
          data['provider_account_id']!,
          _providerAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerAccountIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('quota_total')) {
      context.handle(
        _quotaTotalMeta,
        quotaTotal.isAcceptableOrUnknown(data['quota_total']!, _quotaTotalMeta),
      );
    }
    if (data.containsKey('quota_used')) {
      context.handle(
        _quotaUsedMeta,
        quotaUsed.isAcceptableOrUnknown(data['quota_used']!, _quotaUsedMeta),
      );
    }
    if (data.containsKey('quota_synced_at')) {
      context.handle(
        _quotaSyncedAtMeta,
        quotaSyncedAt.isAcceptableOrUnknown(
          data['quota_synced_at']!,
          _quotaSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_cursor')) {
      context.handle(
        _syncCursorMeta,
        syncCursor.isAcceptableOrUnknown(data['sync_cursor']!, _syncCursorMeta),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {provider, providerAccountId},
  ];
  @override
  LinkedAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LinkedAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_account_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      quotaTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quota_total'],
      ),
      quotaUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quota_used'],
      )!,
      quotaSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}quota_synced_at'],
      ),
      syncCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_cursor'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $LinkedAccountsTable createAlias(String alias) {
    return $LinkedAccountsTable(attachedDatabase, alias);
  }
}

class LinkedAccount extends DataClass implements Insertable<LinkedAccount> {
  final int id;
  final String provider;
  final String providerAccountId;
  final String displayName;
  final String status;
  final int? quotaTotal;
  final int quotaUsed;
  final DateTime? quotaSyncedAt;
  final String? syncCursor;
  final DateTime? lastSyncedAt;
  const LinkedAccount({
    required this.id,
    required this.provider,
    required this.providerAccountId,
    required this.displayName,
    required this.status,
    this.quotaTotal,
    required this.quotaUsed,
    this.quotaSyncedAt,
    this.syncCursor,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider'] = Variable<String>(provider);
    map['provider_account_id'] = Variable<String>(providerAccountId);
    map['display_name'] = Variable<String>(displayName);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || quotaTotal != null) {
      map['quota_total'] = Variable<int>(quotaTotal);
    }
    map['quota_used'] = Variable<int>(quotaUsed);
    if (!nullToAbsent || quotaSyncedAt != null) {
      map['quota_synced_at'] = Variable<DateTime>(quotaSyncedAt);
    }
    if (!nullToAbsent || syncCursor != null) {
      map['sync_cursor'] = Variable<String>(syncCursor);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  LinkedAccountsCompanion toCompanion(bool nullToAbsent) {
    return LinkedAccountsCompanion(
      id: Value(id),
      provider: Value(provider),
      providerAccountId: Value(providerAccountId),
      displayName: Value(displayName),
      status: Value(status),
      quotaTotal: quotaTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaTotal),
      quotaUsed: Value(quotaUsed),
      quotaSyncedAt: quotaSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaSyncedAt),
      syncCursor: syncCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(syncCursor),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory LinkedAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LinkedAccount(
      id: serializer.fromJson<int>(json['id']),
      provider: serializer.fromJson<String>(json['provider']),
      providerAccountId: serializer.fromJson<String>(json['providerAccountId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      status: serializer.fromJson<String>(json['status']),
      quotaTotal: serializer.fromJson<int?>(json['quotaTotal']),
      quotaUsed: serializer.fromJson<int>(json['quotaUsed']),
      quotaSyncedAt: serializer.fromJson<DateTime?>(json['quotaSyncedAt']),
      syncCursor: serializer.fromJson<String?>(json['syncCursor']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'provider': serializer.toJson<String>(provider),
      'providerAccountId': serializer.toJson<String>(providerAccountId),
      'displayName': serializer.toJson<String>(displayName),
      'status': serializer.toJson<String>(status),
      'quotaTotal': serializer.toJson<int?>(quotaTotal),
      'quotaUsed': serializer.toJson<int>(quotaUsed),
      'quotaSyncedAt': serializer.toJson<DateTime?>(quotaSyncedAt),
      'syncCursor': serializer.toJson<String?>(syncCursor),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  LinkedAccount copyWith({
    int? id,
    String? provider,
    String? providerAccountId,
    String? displayName,
    String? status,
    Value<int?> quotaTotal = const Value.absent(),
    int? quotaUsed,
    Value<DateTime?> quotaSyncedAt = const Value.absent(),
    Value<String?> syncCursor = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => LinkedAccount(
    id: id ?? this.id,
    provider: provider ?? this.provider,
    providerAccountId: providerAccountId ?? this.providerAccountId,
    displayName: displayName ?? this.displayName,
    status: status ?? this.status,
    quotaTotal: quotaTotal.present ? quotaTotal.value : this.quotaTotal,
    quotaUsed: quotaUsed ?? this.quotaUsed,
    quotaSyncedAt: quotaSyncedAt.present
        ? quotaSyncedAt.value
        : this.quotaSyncedAt,
    syncCursor: syncCursor.present ? syncCursor.value : this.syncCursor,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  LinkedAccount copyWithCompanion(LinkedAccountsCompanion data) {
    return LinkedAccount(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      providerAccountId: data.providerAccountId.present
          ? data.providerAccountId.value
          : this.providerAccountId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      status: data.status.present ? data.status.value : this.status,
      quotaTotal: data.quotaTotal.present
          ? data.quotaTotal.value
          : this.quotaTotal,
      quotaUsed: data.quotaUsed.present ? data.quotaUsed.value : this.quotaUsed,
      quotaSyncedAt: data.quotaSyncedAt.present
          ? data.quotaSyncedAt.value
          : this.quotaSyncedAt,
      syncCursor: data.syncCursor.present
          ? data.syncCursor.value
          : this.syncCursor,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LinkedAccount(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('providerAccountId: $providerAccountId, ')
          ..write('displayName: $displayName, ')
          ..write('status: $status, ')
          ..write('quotaTotal: $quotaTotal, ')
          ..write('quotaUsed: $quotaUsed, ')
          ..write('quotaSyncedAt: $quotaSyncedAt, ')
          ..write('syncCursor: $syncCursor, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    provider,
    providerAccountId,
    displayName,
    status,
    quotaTotal,
    quotaUsed,
    quotaSyncedAt,
    syncCursor,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LinkedAccount &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.providerAccountId == this.providerAccountId &&
          other.displayName == this.displayName &&
          other.status == this.status &&
          other.quotaTotal == this.quotaTotal &&
          other.quotaUsed == this.quotaUsed &&
          other.quotaSyncedAt == this.quotaSyncedAt &&
          other.syncCursor == this.syncCursor &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class LinkedAccountsCompanion extends UpdateCompanion<LinkedAccount> {
  final Value<int> id;
  final Value<String> provider;
  final Value<String> providerAccountId;
  final Value<String> displayName;
  final Value<String> status;
  final Value<int?> quotaTotal;
  final Value<int> quotaUsed;
  final Value<DateTime?> quotaSyncedAt;
  final Value<String?> syncCursor;
  final Value<DateTime?> lastSyncedAt;
  const LinkedAccountsCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.providerAccountId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.status = const Value.absent(),
    this.quotaTotal = const Value.absent(),
    this.quotaUsed = const Value.absent(),
    this.quotaSyncedAt = const Value.absent(),
    this.syncCursor = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
  });
  LinkedAccountsCompanion.insert({
    this.id = const Value.absent(),
    required String provider,
    required String providerAccountId,
    required String displayName,
    this.status = const Value.absent(),
    this.quotaTotal = const Value.absent(),
    this.quotaUsed = const Value.absent(),
    this.quotaSyncedAt = const Value.absent(),
    this.syncCursor = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
  }) : provider = Value(provider),
       providerAccountId = Value(providerAccountId),
       displayName = Value(displayName);
  static Insertable<LinkedAccount> custom({
    Expression<int>? id,
    Expression<String>? provider,
    Expression<String>? providerAccountId,
    Expression<String>? displayName,
    Expression<String>? status,
    Expression<int>? quotaTotal,
    Expression<int>? quotaUsed,
    Expression<DateTime>? quotaSyncedAt,
    Expression<String>? syncCursor,
    Expression<DateTime>? lastSyncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (providerAccountId != null) 'provider_account_id': providerAccountId,
      if (displayName != null) 'display_name': displayName,
      if (status != null) 'status': status,
      if (quotaTotal != null) 'quota_total': quotaTotal,
      if (quotaUsed != null) 'quota_used': quotaUsed,
      if (quotaSyncedAt != null) 'quota_synced_at': quotaSyncedAt,
      if (syncCursor != null) 'sync_cursor': syncCursor,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
    });
  }

  LinkedAccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? provider,
    Value<String>? providerAccountId,
    Value<String>? displayName,
    Value<String>? status,
    Value<int?>? quotaTotal,
    Value<int>? quotaUsed,
    Value<DateTime?>? quotaSyncedAt,
    Value<String?>? syncCursor,
    Value<DateTime?>? lastSyncedAt,
  }) {
    return LinkedAccountsCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      providerAccountId: providerAccountId ?? this.providerAccountId,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      quotaTotal: quotaTotal ?? this.quotaTotal,
      quotaUsed: quotaUsed ?? this.quotaUsed,
      quotaSyncedAt: quotaSyncedAt ?? this.quotaSyncedAt,
      syncCursor: syncCursor ?? this.syncCursor,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerAccountId.present) {
      map['provider_account_id'] = Variable<String>(providerAccountId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (quotaTotal.present) {
      map['quota_total'] = Variable<int>(quotaTotal.value);
    }
    if (quotaUsed.present) {
      map['quota_used'] = Variable<int>(quotaUsed.value);
    }
    if (quotaSyncedAt.present) {
      map['quota_synced_at'] = Variable<DateTime>(quotaSyncedAt.value);
    }
    if (syncCursor.present) {
      map['sync_cursor'] = Variable<String>(syncCursor.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LinkedAccountsCompanion(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('providerAccountId: $providerAccountId, ')
          ..write('displayName: $displayName, ')
          ..write('status: $status, ')
          ..write('quotaTotal: $quotaTotal, ')
          ..write('quotaUsed: $quotaUsed, ')
          ..write('quotaSyncedAt: $quotaSyncedAt, ')
          ..write('syncCursor: $syncCursor, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES folders (id) ON DELETE CASCADE',
    ),
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
  List<GeneratedColumn> get $columns => [id, parentId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
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
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final int id;
  final int? parentId;
  final String name;
  const Folder({required this.id, this.parentId, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['name'] = Variable<String>(name);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<int>(json['id']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'parentId': serializer.toJson<int?>(parentId),
      'name': serializer.toJson<String>(name),
    };
  }

  Folder copyWith({
    int? id,
    Value<int?> parentId = const Value.absent(),
    String? name,
  }) => Folder(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, parentId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<int> id;
  final Value<int?> parentId;
  final Value<String> name;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
  });
  FoldersCompanion.insert({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Folder> custom({
    Expression<int>? id,
    Expression<int>? parentId,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
    });
  }

  FoldersCompanion copyWith({
    Value<int>? id,
    Value<int?>? parentId,
    Value<String>? name,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $FilesTable extends Files with TableInfo<$FilesTable, FileEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES linked_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES folders (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trashedAtMeta = const VerificationMeta(
    'trashedAt',
  );
  @override
  late final GeneratedColumn<DateTime> trashedAt = GeneratedColumn<DateTime>(
    'trashed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    folderId,
    remoteId,
    name,
    path,
    size,
    mime,
    hash,
    modifiedAt,
    indexedAt,
    trashedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'files';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_indexedAtMeta);
    }
    if (data.containsKey('trashed_at')) {
      context.handle(
        _trashedAtMeta,
        trashedAt.isAcceptableOrUnknown(data['trashed_at']!, _trashedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {accountId, remoteId},
  ];
  @override
  FileEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}folder_id'],
      ),
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      ),
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
      trashedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}trashed_at'],
      ),
    );
  }

  @override
  $FilesTable createAlias(String alias) {
    return $FilesTable(attachedDatabase, alias);
  }
}

class FileEntry extends DataClass implements Insertable<FileEntry> {
  final int id;
  final int accountId;
  final int? folderId;
  final String remoteId;
  final String name;
  final String path;
  final int size;
  final String mime;
  final String? hash;
  final DateTime? modifiedAt;
  final DateTime indexedAt;
  final DateTime? trashedAt;
  const FileEntry({
    required this.id,
    required this.accountId,
    this.folderId,
    required this.remoteId,
    required this.name,
    required this.path,
    required this.size,
    required this.mime,
    this.hash,
    this.modifiedAt,
    required this.indexedAt,
    this.trashedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<int>(accountId);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<int>(folderId);
    }
    map['remote_id'] = Variable<String>(remoteId);
    map['name'] = Variable<String>(name);
    map['path'] = Variable<String>(path);
    map['size'] = Variable<int>(size);
    map['mime'] = Variable<String>(mime);
    if (!nullToAbsent || hash != null) {
      map['hash'] = Variable<String>(hash);
    }
    if (!nullToAbsent || modifiedAt != null) {
      map['modified_at'] = Variable<DateTime>(modifiedAt);
    }
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    if (!nullToAbsent || trashedAt != null) {
      map['trashed_at'] = Variable<DateTime>(trashedAt);
    }
    return map;
  }

  FilesCompanion toCompanion(bool nullToAbsent) {
    return FilesCompanion(
      id: Value(id),
      accountId: Value(accountId),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      remoteId: Value(remoteId),
      name: Value(name),
      path: Value(path),
      size: Value(size),
      mime: Value(mime),
      hash: hash == null && nullToAbsent ? const Value.absent() : Value(hash),
      modifiedAt: modifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAt),
      indexedAt: Value(indexedAt),
      trashedAt: trashedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(trashedAt),
    );
  }

  factory FileEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileEntry(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<int>(json['accountId']),
      folderId: serializer.fromJson<int?>(json['folderId']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      path: serializer.fromJson<String>(json['path']),
      size: serializer.fromJson<int>(json['size']),
      mime: serializer.fromJson<String>(json['mime']),
      hash: serializer.fromJson<String?>(json['hash']),
      modifiedAt: serializer.fromJson<DateTime?>(json['modifiedAt']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
      trashedAt: serializer.fromJson<DateTime?>(json['trashedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<int>(accountId),
      'folderId': serializer.toJson<int?>(folderId),
      'remoteId': serializer.toJson<String>(remoteId),
      'name': serializer.toJson<String>(name),
      'path': serializer.toJson<String>(path),
      'size': serializer.toJson<int>(size),
      'mime': serializer.toJson<String>(mime),
      'hash': serializer.toJson<String?>(hash),
      'modifiedAt': serializer.toJson<DateTime?>(modifiedAt),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
      'trashedAt': serializer.toJson<DateTime?>(trashedAt),
    };
  }

  FileEntry copyWith({
    int? id,
    int? accountId,
    Value<int?> folderId = const Value.absent(),
    String? remoteId,
    String? name,
    String? path,
    int? size,
    String? mime,
    Value<String?> hash = const Value.absent(),
    Value<DateTime?> modifiedAt = const Value.absent(),
    DateTime? indexedAt,
    Value<DateTime?> trashedAt = const Value.absent(),
  }) => FileEntry(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    folderId: folderId.present ? folderId.value : this.folderId,
    remoteId: remoteId ?? this.remoteId,
    name: name ?? this.name,
    path: path ?? this.path,
    size: size ?? this.size,
    mime: mime ?? this.mime,
    hash: hash.present ? hash.value : this.hash,
    modifiedAt: modifiedAt.present ? modifiedAt.value : this.modifiedAt,
    indexedAt: indexedAt ?? this.indexedAt,
    trashedAt: trashedAt.present ? trashedAt.value : this.trashedAt,
  );
  FileEntry copyWithCompanion(FilesCompanion data) {
    return FileEntry(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      path: data.path.present ? data.path.value : this.path,
      size: data.size.present ? data.size.value : this.size,
      mime: data.mime.present ? data.mime.value : this.mime,
      hash: data.hash.present ? data.hash.value : this.hash,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
      trashedAt: data.trashedAt.present ? data.trashedAt.value : this.trashedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileEntry(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('folderId: $folderId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('mime: $mime, ')
          ..write('hash: $hash, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('trashedAt: $trashedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    folderId,
    remoteId,
    name,
    path,
    size,
    mime,
    hash,
    modifiedAt,
    indexedAt,
    trashedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileEntry &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.folderId == this.folderId &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.path == this.path &&
          other.size == this.size &&
          other.mime == this.mime &&
          other.hash == this.hash &&
          other.modifiedAt == this.modifiedAt &&
          other.indexedAt == this.indexedAt &&
          other.trashedAt == this.trashedAt);
}

class FilesCompanion extends UpdateCompanion<FileEntry> {
  final Value<int> id;
  final Value<int> accountId;
  final Value<int?> folderId;
  final Value<String> remoteId;
  final Value<String> name;
  final Value<String> path;
  final Value<int> size;
  final Value<String> mime;
  final Value<String?> hash;
  final Value<DateTime?> modifiedAt;
  final Value<DateTime> indexedAt;
  final Value<DateTime?> trashedAt;
  const FilesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.path = const Value.absent(),
    this.size = const Value.absent(),
    this.mime = const Value.absent(),
    this.hash = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.trashedAt = const Value.absent(),
  });
  FilesCompanion.insert({
    this.id = const Value.absent(),
    required int accountId,
    this.folderId = const Value.absent(),
    required String remoteId,
    required String name,
    this.path = const Value.absent(),
    this.size = const Value.absent(),
    this.mime = const Value.absent(),
    this.hash = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    required DateTime indexedAt,
    this.trashedAt = const Value.absent(),
  }) : accountId = Value(accountId),
       remoteId = Value(remoteId),
       name = Value(name),
       indexedAt = Value(indexedAt);
  static Insertable<FileEntry> custom({
    Expression<int>? id,
    Expression<int>? accountId,
    Expression<int>? folderId,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<String>? path,
    Expression<int>? size,
    Expression<String>? mime,
    Expression<String>? hash,
    Expression<DateTime>? modifiedAt,
    Expression<DateTime>? indexedAt,
    Expression<DateTime>? trashedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (folderId != null) 'folder_id': folderId,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (path != null) 'path': path,
      if (size != null) 'size': size,
      if (mime != null) 'mime': mime,
      if (hash != null) 'hash': hash,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (indexedAt != null) 'indexed_at': indexedAt,
      if (trashedAt != null) 'trashed_at': trashedAt,
    });
  }

  FilesCompanion copyWith({
    Value<int>? id,
    Value<int>? accountId,
    Value<int?>? folderId,
    Value<String>? remoteId,
    Value<String>? name,
    Value<String>? path,
    Value<int>? size,
    Value<String>? mime,
    Value<String?>? hash,
    Value<DateTime?>? modifiedAt,
    Value<DateTime>? indexedAt,
    Value<DateTime?>? trashedAt,
  }) {
    return FilesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      folderId: folderId ?? this.folderId,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      mime: mime ?? this.mime,
      hash: hash ?? this.hash,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      indexedAt: indexedAt ?? this.indexedAt,
      trashedAt: trashedAt ?? this.trashedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    if (trashedAt.present) {
      map['trashed_at'] = Variable<DateTime>(trashedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('folderId: $folderId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('size: $size, ')
          ..write('mime: $mime, ')
          ..write('hash: $hash, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('trashedAt: $trashedAt')
          ..write(')'))
        .toString();
  }
}

class $QuotaSnapshotsTable extends QuotaSnapshots
    with TableInfo<$QuotaSnapshotsTable, QuotaSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuotaSnapshotsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES linked_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedMeta = const VerificationMeta('used');
  @override
  late final GeneratedColumn<int> used = GeneratedColumn<int>(
    'used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, accountId, takenAt, used, total];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quota_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuotaSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('used')) {
      context.handle(
        _usedMeta,
        used.isAcceptableOrUnknown(data['used']!, _usedMeta),
      );
    } else if (isInserting) {
      context.missing(_usedMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuotaSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuotaSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      used: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      ),
    );
  }

  @override
  $QuotaSnapshotsTable createAlias(String alias) {
    return $QuotaSnapshotsTable(attachedDatabase, alias);
  }
}

class QuotaSnapshot extends DataClass implements Insertable<QuotaSnapshot> {
  final int id;
  final int accountId;
  final DateTime takenAt;
  final int used;
  final int? total;
  const QuotaSnapshot({
    required this.id,
    required this.accountId,
    required this.takenAt,
    required this.used,
    this.total,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<int>(accountId);
    map['taken_at'] = Variable<DateTime>(takenAt);
    map['used'] = Variable<int>(used);
    if (!nullToAbsent || total != null) {
      map['total'] = Variable<int>(total);
    }
    return map;
  }

  QuotaSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return QuotaSnapshotsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      takenAt: Value(takenAt),
      used: Value(used),
      total: total == null && nullToAbsent
          ? const Value.absent()
          : Value(total),
    );
  }

  factory QuotaSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuotaSnapshot(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<int>(json['accountId']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      used: serializer.fromJson<int>(json['used']),
      total: serializer.fromJson<int?>(json['total']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<int>(accountId),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'used': serializer.toJson<int>(used),
      'total': serializer.toJson<int?>(total),
    };
  }

  QuotaSnapshot copyWith({
    int? id,
    int? accountId,
    DateTime? takenAt,
    int? used,
    Value<int?> total = const Value.absent(),
  }) => QuotaSnapshot(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    takenAt: takenAt ?? this.takenAt,
    used: used ?? this.used,
    total: total.present ? total.value : this.total,
  );
  QuotaSnapshot copyWithCompanion(QuotaSnapshotsCompanion data) {
    return QuotaSnapshot(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      used: data.used.present ? data.used.value : this.used,
      total: data.total.present ? data.total.value : this.total,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuotaSnapshot(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('takenAt: $takenAt, ')
          ..write('used: $used, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountId, takenAt, used, total);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuotaSnapshot &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.takenAt == this.takenAt &&
          other.used == this.used &&
          other.total == this.total);
}

class QuotaSnapshotsCompanion extends UpdateCompanion<QuotaSnapshot> {
  final Value<int> id;
  final Value<int> accountId;
  final Value<DateTime> takenAt;
  final Value<int> used;
  final Value<int?> total;
  const QuotaSnapshotsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.used = const Value.absent(),
    this.total = const Value.absent(),
  });
  QuotaSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required int accountId,
    required DateTime takenAt,
    required int used,
    this.total = const Value.absent(),
  }) : accountId = Value(accountId),
       takenAt = Value(takenAt),
       used = Value(used);
  static Insertable<QuotaSnapshot> custom({
    Expression<int>? id,
    Expression<int>? accountId,
    Expression<DateTime>? takenAt,
    Expression<int>? used,
    Expression<int>? total,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (takenAt != null) 'taken_at': takenAt,
      if (used != null) 'used': used,
      if (total != null) 'total': total,
    });
  }

  QuotaSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<int>? accountId,
    Value<DateTime>? takenAt,
    Value<int>? used,
    Value<int?>? total,
  }) {
    return QuotaSnapshotsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      takenAt: takenAt ?? this.takenAt,
      used: used ?? this.used,
      total: total ?? this.total,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (used.present) {
      map['used'] = Variable<int>(used.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuotaSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('takenAt: $takenAt, ')
          ..write('used: $used, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
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
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
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
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
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

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
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
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
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

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BackupRunsTable extends BackupRuns
    with TableInfo<$BackupRunsTable, BackupRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupRunsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES linked_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotIdMeta = const VerificationMeta(
    'snapshotId',
  );
  @override
  late final GeneratedColumn<String> snapshotId = GeneratedColumn<String>(
    'snapshot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _okMeta = const VerificationMeta('ok');
  @override
  late final GeneratedColumn<bool> ok = GeneratedColumn<bool>(
    'ok',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ok" IN (0, 1))',
    ),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    at,
    snapshotId,
    ok,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('snapshot_id')) {
      context.handle(
        _snapshotIdMeta,
        snapshotId.isAcceptableOrUnknown(data['snapshot_id']!, _snapshotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotIdMeta);
    }
    if (data.containsKey('ok')) {
      context.handle(_okMeta, ok.isAcceptableOrUnknown(data['ok']!, _okMeta));
    } else if (isInserting) {
      context.missing(_okMeta);
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupRun(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      snapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_id'],
      )!,
      ok: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ok'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $BackupRunsTable createAlias(String alias) {
    return $BackupRunsTable(attachedDatabase, alias);
  }
}

class BackupRun extends DataClass implements Insertable<BackupRun> {
  final int id;
  final int accountId;
  final DateTime at;
  final String snapshotId;
  final bool ok;
  final String? error;
  const BackupRun({
    required this.id,
    required this.accountId,
    required this.at,
    required this.snapshotId,
    required this.ok,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<int>(accountId);
    map['at'] = Variable<DateTime>(at);
    map['snapshot_id'] = Variable<String>(snapshotId);
    map['ok'] = Variable<bool>(ok);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  BackupRunsCompanion toCompanion(bool nullToAbsent) {
    return BackupRunsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      at: Value(at),
      snapshotId: Value(snapshotId),
      ok: Value(ok),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory BackupRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupRun(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<int>(json['accountId']),
      at: serializer.fromJson<DateTime>(json['at']),
      snapshotId: serializer.fromJson<String>(json['snapshotId']),
      ok: serializer.fromJson<bool>(json['ok']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<int>(accountId),
      'at': serializer.toJson<DateTime>(at),
      'snapshotId': serializer.toJson<String>(snapshotId),
      'ok': serializer.toJson<bool>(ok),
      'error': serializer.toJson<String?>(error),
    };
  }

  BackupRun copyWith({
    int? id,
    int? accountId,
    DateTime? at,
    String? snapshotId,
    bool? ok,
    Value<String?> error = const Value.absent(),
  }) => BackupRun(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    at: at ?? this.at,
    snapshotId: snapshotId ?? this.snapshotId,
    ok: ok ?? this.ok,
    error: error.present ? error.value : this.error,
  );
  BackupRun copyWithCompanion(BackupRunsCompanion data) {
    return BackupRun(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      at: data.at.present ? data.at.value : this.at,
      snapshotId: data.snapshotId.present
          ? data.snapshotId.value
          : this.snapshotId,
      ok: data.ok.present ? data.ok.value : this.ok,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupRun(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('at: $at, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('ok: $ok, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountId, at, snapshotId, ok, error);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupRun &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.at == this.at &&
          other.snapshotId == this.snapshotId &&
          other.ok == this.ok &&
          other.error == this.error);
}

class BackupRunsCompanion extends UpdateCompanion<BackupRun> {
  final Value<int> id;
  final Value<int> accountId;
  final Value<DateTime> at;
  final Value<String> snapshotId;
  final Value<bool> ok;
  final Value<String?> error;
  const BackupRunsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.at = const Value.absent(),
    this.snapshotId = const Value.absent(),
    this.ok = const Value.absent(),
    this.error = const Value.absent(),
  });
  BackupRunsCompanion.insert({
    this.id = const Value.absent(),
    required int accountId,
    required DateTime at,
    required String snapshotId,
    required bool ok,
    this.error = const Value.absent(),
  }) : accountId = Value(accountId),
       at = Value(at),
       snapshotId = Value(snapshotId),
       ok = Value(ok);
  static Insertable<BackupRun> custom({
    Expression<int>? id,
    Expression<int>? accountId,
    Expression<DateTime>? at,
    Expression<String>? snapshotId,
    Expression<bool>? ok,
    Expression<String>? error,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (at != null) 'at': at,
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (ok != null) 'ok': ok,
      if (error != null) 'error': error,
    });
  }

  BackupRunsCompanion copyWith({
    Value<int>? id,
    Value<int>? accountId,
    Value<DateTime>? at,
    Value<String>? snapshotId,
    Value<bool>? ok,
    Value<String?>? error,
  }) {
    return BackupRunsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      at: at ?? this.at,
      snapshotId: snapshotId ?? this.snapshotId,
      ok: ok ?? this.ok,
      error: error ?? this.error,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<String>(snapshotId.value);
    }
    if (ok.present) {
      map['ok'] = Variable<bool>(ok.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupRunsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('at: $at, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('ok: $ok, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LinkedAccountsTable linkedAccounts = $LinkedAccountsTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $FilesTable files = $FilesTable(this);
  late final $QuotaSnapshotsTable quotaSnapshots = $QuotaSnapshotsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $BackupRunsTable backupRuns = $BackupRunsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    linkedAccounts,
    folders,
    files,
    quotaSnapshots,
    appSettings,
    backupRuns,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'folders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('folders', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'linked_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('files', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'folders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('files', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'linked_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('quota_snapshots', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'linked_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('backup_runs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LinkedAccountsTableCreateCompanionBuilder =
    LinkedAccountsCompanion Function({
      Value<int> id,
      required String provider,
      required String providerAccountId,
      required String displayName,
      Value<String> status,
      Value<int?> quotaTotal,
      Value<int> quotaUsed,
      Value<DateTime?> quotaSyncedAt,
      Value<String?> syncCursor,
      Value<DateTime?> lastSyncedAt,
    });
typedef $$LinkedAccountsTableUpdateCompanionBuilder =
    LinkedAccountsCompanion Function({
      Value<int> id,
      Value<String> provider,
      Value<String> providerAccountId,
      Value<String> displayName,
      Value<String> status,
      Value<int?> quotaTotal,
      Value<int> quotaUsed,
      Value<DateTime?> quotaSyncedAt,
      Value<String?> syncCursor,
      Value<DateTime?> lastSyncedAt,
    });

final class $$LinkedAccountsTableReferences
    extends BaseReferences<_$AppDatabase, $LinkedAccountsTable, LinkedAccount> {
  $$LinkedAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$FilesTable, List<FileEntry>> _filesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.files,
    aliasName: 'linked_accounts__id__files__account_id',
  );

  $$FilesTableProcessedTableManager get filesRefs {
    final manager = $$FilesTableTableManager(
      $_db,
      $_db.files,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_filesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QuotaSnapshotsTable, List<QuotaSnapshot>>
  _quotaSnapshotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.quotaSnapshots,
    aliasName: 'linked_accounts__id__quota_snapshots__account_id',
  );

  $$QuotaSnapshotsTableProcessedTableManager get quotaSnapshotsRefs {
    final manager = $$QuotaSnapshotsTableTableManager(
      $_db,
      $_db.quotaSnapshots,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_quotaSnapshotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BackupRunsTable, List<BackupRun>>
  _backupRunsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.backupRuns,
    aliasName: 'linked_accounts__id__backup_runs__account_id',
  );

  $$BackupRunsTableProcessedTableManager get backupRunsRefs {
    final manager = $$BackupRunsTableTableManager(
      $_db,
      $_db.backupRuns,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_backupRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LinkedAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $LinkedAccountsTable> {
  $$LinkedAccountsTableFilterComposer({
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

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerAccountId => $composableBuilder(
    column: $table.providerAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quotaTotal => $composableBuilder(
    column: $table.quotaTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quotaUsed => $composableBuilder(
    column: $table.quotaUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get quotaSyncedAt => $composableBuilder(
    column: $table.quotaSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncCursor => $composableBuilder(
    column: $table.syncCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> filesRefs(
    Expression<bool> Function($$FilesTableFilterComposer f) f,
  ) {
    final $$FilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.files,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilesTableFilterComposer(
            $db: $db,
            $table: $db.files,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> quotaSnapshotsRefs(
    Expression<bool> Function($$QuotaSnapshotsTableFilterComposer f) f,
  ) {
    final $$QuotaSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quotaSnapshots,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuotaSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.quotaSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> backupRunsRefs(
    Expression<bool> Function($$BackupRunsTableFilterComposer f) f,
  ) {
    final $$BackupRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.backupRuns,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupRunsTableFilterComposer(
            $db: $db,
            $table: $db.backupRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LinkedAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $LinkedAccountsTable> {
  $$LinkedAccountsTableOrderingComposer({
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

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerAccountId => $composableBuilder(
    column: $table.providerAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quotaTotal => $composableBuilder(
    column: $table.quotaTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quotaUsed => $composableBuilder(
    column: $table.quotaUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get quotaSyncedAt => $composableBuilder(
    column: $table.quotaSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncCursor => $composableBuilder(
    column: $table.syncCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LinkedAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LinkedAccountsTable> {
  $$LinkedAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get providerAccountId => $composableBuilder(
    column: $table.providerAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get quotaTotal => $composableBuilder(
    column: $table.quotaTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quotaUsed =>
      $composableBuilder(column: $table.quotaUsed, builder: (column) => column);

  GeneratedColumn<DateTime> get quotaSyncedAt => $composableBuilder(
    column: $table.quotaSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncCursor => $composableBuilder(
    column: $table.syncCursor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  Expression<T> filesRefs<T extends Object>(
    Expression<T> Function($$FilesTableAnnotationComposer a) f,
  ) {
    final $$FilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.files,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilesTableAnnotationComposer(
            $db: $db,
            $table: $db.files,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> quotaSnapshotsRefs<T extends Object>(
    Expression<T> Function($$QuotaSnapshotsTableAnnotationComposer a) f,
  ) {
    final $$QuotaSnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quotaSnapshots,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuotaSnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.quotaSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> backupRunsRefs<T extends Object>(
    Expression<T> Function($$BackupRunsTableAnnotationComposer a) f,
  ) {
    final $$BackupRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.backupRuns,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BackupRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.backupRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LinkedAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LinkedAccountsTable,
          LinkedAccount,
          $$LinkedAccountsTableFilterComposer,
          $$LinkedAccountsTableOrderingComposer,
          $$LinkedAccountsTableAnnotationComposer,
          $$LinkedAccountsTableCreateCompanionBuilder,
          $$LinkedAccountsTableUpdateCompanionBuilder,
          (LinkedAccount, $$LinkedAccountsTableReferences),
          LinkedAccount,
          PrefetchHooks Function({
            bool filesRefs,
            bool quotaSnapshotsRefs,
            bool backupRunsRefs,
          })
        > {
  $$LinkedAccountsTableTableManager(
    _$AppDatabase db,
    $LinkedAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LinkedAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LinkedAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LinkedAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> providerAccountId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> quotaTotal = const Value.absent(),
                Value<int> quotaUsed = const Value.absent(),
                Value<DateTime?> quotaSyncedAt = const Value.absent(),
                Value<String?> syncCursor = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
              }) => LinkedAccountsCompanion(
                id: id,
                provider: provider,
                providerAccountId: providerAccountId,
                displayName: displayName,
                status: status,
                quotaTotal: quotaTotal,
                quotaUsed: quotaUsed,
                quotaSyncedAt: quotaSyncedAt,
                syncCursor: syncCursor,
                lastSyncedAt: lastSyncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String provider,
                required String providerAccountId,
                required String displayName,
                Value<String> status = const Value.absent(),
                Value<int?> quotaTotal = const Value.absent(),
                Value<int> quotaUsed = const Value.absent(),
                Value<DateTime?> quotaSyncedAt = const Value.absent(),
                Value<String?> syncCursor = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
              }) => LinkedAccountsCompanion.insert(
                id: id,
                provider: provider,
                providerAccountId: providerAccountId,
                displayName: displayName,
                status: status,
                quotaTotal: quotaTotal,
                quotaUsed: quotaUsed,
                quotaSyncedAt: quotaSyncedAt,
                syncCursor: syncCursor,
                lastSyncedAt: lastSyncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LinkedAccountsTable, LinkedAccount>(table),
                  $$LinkedAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                filesRefs = false,
                quotaSnapshotsRefs = false,
                backupRunsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (filesRefs) db.files,
                    if (quotaSnapshotsRefs) db.quotaSnapshots,
                    if (backupRunsRefs) db.backupRuns,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (filesRefs)
                        await $_getPrefetchedData<
                          LinkedAccount,
                          $LinkedAccountsTable,
                          FileEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LinkedAccountsTableReferences
                              ._filesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LinkedAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).filesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (quotaSnapshotsRefs)
                        await $_getPrefetchedData<
                          LinkedAccount,
                          $LinkedAccountsTable,
                          QuotaSnapshot
                        >(
                          currentTable: table,
                          referencedTable: $$LinkedAccountsTableReferences
                              ._quotaSnapshotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LinkedAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).quotaSnapshotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (backupRunsRefs)
                        await $_getPrefetchedData<
                          LinkedAccount,
                          $LinkedAccountsTable,
                          BackupRun
                        >(
                          currentTable: table,
                          referencedTable: $$LinkedAccountsTableReferences
                              ._backupRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LinkedAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).backupRunsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LinkedAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LinkedAccountsTable,
      LinkedAccount,
      $$LinkedAccountsTableFilterComposer,
      $$LinkedAccountsTableOrderingComposer,
      $$LinkedAccountsTableAnnotationComposer,
      $$LinkedAccountsTableCreateCompanionBuilder,
      $$LinkedAccountsTableUpdateCompanionBuilder,
      (LinkedAccount, $$LinkedAccountsTableReferences),
      LinkedAccount,
      PrefetchHooks Function({
        bool filesRefs,
        bool quotaSnapshotsRefs,
        bool backupRunsRefs,
      })
    >;
typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  Value<int> id,
  Value<int?> parentId,
  required String name,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<int> id,
  Value<int?> parentId,
  Value<String> name,
});

final class $$FoldersTableReferences
    extends BaseReferences<_$AppDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _parentIdTable(_$AppDatabase db) =>
      db.folders.createAlias('folders__parent_id__folders__id');

  $$FoldersTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FilesTable, List<FileEntry>> _filesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.files,
    aliasName: 'folders__id__files__folder_id',
  );

  $$FilesTableProcessedTableManager get filesRefs {
    final manager = $$FilesTableTableManager(
      $_db,
      $_db.files,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_filesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$FoldersTableFilterComposer get parentId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> filesRefs(
    Expression<bool> Function($$FilesTableFilterComposer f) f,
  ) {
    final $$FilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.files,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilesTableFilterComposer(
            $db: $db,
            $table: $db.files,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoldersTableOrderingComposer get parentId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$FoldersTableAnnotationComposer get parentId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> filesRefs<T extends Object>(
    Expression<T> Function($$FilesTableAnnotationComposer a) f,
  ) {
    final $$FilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.files,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilesTableAnnotationComposer(
            $db: $db,
            $table: $db.files,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, $$FoldersTableReferences),
          Folder,
          PrefetchHooks Function({bool parentId, bool filesRefs})
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) => FoldersCompanion(id: id, parentId: parentId, name: name),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            required String name,
          }) => FoldersCompanion.insert(id: id, parentId: parentId, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoldersTable, Folder>(table),
                  $$FoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false, filesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (filesRefs) db.files],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (parentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.parentId,
                        referencedTable: $$FoldersTableReferences
                            ._parentIdTable(db),
                        referencedColumn: $$FoldersTableReferences
                            ._parentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (filesRefs)
                    await $_getPrefetchedData<Folder, $FoldersTable, FileEntry>(
                      currentTable: table,
                      referencedTable: $$FoldersTableReferences._filesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$FoldersTableReferences(db, table, p0).filesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, $$FoldersTableReferences),
      Folder,
      PrefetchHooks Function({bool parentId, bool filesRefs})
    >;
typedef $$FilesTableCreateCompanionBuilder = FilesCompanion Function({
  Value<int> id,
  required int accountId,
  Value<int?> folderId,
  required String remoteId,
  required String name,
  Value<String> path,
  Value<int> size,
  Value<String> mime,
  Value<String?> hash,
  Value<DateTime?> modifiedAt,
  required DateTime indexedAt,
  Value<DateTime?> trashedAt,
});
typedef $$FilesTableUpdateCompanionBuilder = FilesCompanion Function({
  Value<int> id,
  Value<int> accountId,
  Value<int?> folderId,
  Value<String> remoteId,
  Value<String> name,
  Value<String> path,
  Value<int> size,
  Value<String> mime,
  Value<String?> hash,
  Value<DateTime?> modifiedAt,
  Value<DateTime> indexedAt,
  Value<DateTime?> trashedAt,
});

final class $$FilesTableReferences
    extends BaseReferences<_$AppDatabase, $FilesTable, FileEntry> {
  $$FilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LinkedAccountsTable _accountIdTable(_$AppDatabase db) =>
      db.linkedAccounts.createAlias('files__account_id__linked_accounts__id');

  $$LinkedAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$LinkedAccountsTableTableManager(
      $_db,
      $_db.linkedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FoldersTable _folderIdTable(_$AppDatabase db) =>
      db.folders.createAlias('files__folder_id__folders__id');

  $$FoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<int>('folder_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FilesTableFilterComposer extends Composer<_$AppDatabase, $FilesTable> {
  $$FilesTableFilterComposer({
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

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get trashedAt => $composableBuilder(
    column: $table.trashedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LinkedAccountsTableFilterComposer get accountId {
    final $$LinkedAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.linkedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkedAccountsTableFilterComposer(
            $db: $db,
            $table: $db.linkedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FilesTableOrderingComposer
    extends Composer<_$AppDatabase, $FilesTable> {
  $$FilesTableOrderingComposer({
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

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get trashedAt => $composableBuilder(
    column: $table.trashedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LinkedAccountsTableOrderingComposer get accountId {
    final $$LinkedAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.linkedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkedAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.linkedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilesTable> {
  $$FilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get trashedAt =>
      $composableBuilder(column: $table.trashedAt, builder: (column) => column);

  $$LinkedAccountsTableAnnotationComposer get accountId {
    final $$LinkedAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.linkedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkedAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.linkedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilesTable,
          FileEntry,
          $$FilesTableFilterComposer,
          $$FilesTableOrderingComposer,
          $$FilesTableAnnotationComposer,
          $$FilesTableCreateCompanionBuilder,
          $$FilesTableUpdateCompanionBuilder,
          (FileEntry, $$FilesTableReferences),
          FileEntry,
          PrefetchHooks Function({bool accountId, bool folderId})
        > {
  $$FilesTableTableManager(_$AppDatabase db, $FilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<int?> folderId = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String> mime = const Value.absent(),
                Value<String?> hash = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
                Value<DateTime?> trashedAt = const Value.absent(),
              }) => FilesCompanion(
                id: id,
                accountId: accountId,
                folderId: folderId,
                remoteId: remoteId,
                name: name,
                path: path,
                size: size,
                mime: mime,
                hash: hash,
                modifiedAt: modifiedAt,
                indexedAt: indexedAt,
                trashedAt: trashedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int accountId,
                Value<int?> folderId = const Value.absent(),
                required String remoteId,
                required String name,
                Value<String> path = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String> mime = const Value.absent(),
                Value<String?> hash = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                required DateTime indexedAt,
                Value<DateTime?> trashedAt = const Value.absent(),
              }) => FilesCompanion.insert(
                id: id,
                accountId: accountId,
                folderId: folderId,
                remoteId: remoteId,
                name: name,
                path: path,
                size: size,
                mime: mime,
                hash: hash,
                modifiedAt: modifiedAt,
                indexedAt: indexedAt,
                trashedAt: trashedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FilesTable, FileEntry>(table),
                  $$FilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false, folderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$FilesTableReferences._accountIdTable(
                          db,
                        ),
                        referencedColumn: $$FilesTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (folderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.folderId,
                        referencedTable: $$FilesTableReferences._folderIdTable(
                          db,
                        ),
                        referencedColumn: $$FilesTableReferences
                            ._folderIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilesTable,
      FileEntry,
      $$FilesTableFilterComposer,
      $$FilesTableOrderingComposer,
      $$FilesTableAnnotationComposer,
      $$FilesTableCreateCompanionBuilder,
      $$FilesTableUpdateCompanionBuilder,
      (FileEntry, $$FilesTableReferences),
      FileEntry,
      PrefetchHooks Function({bool accountId, bool folderId})
    >;
typedef $$QuotaSnapshotsTableCreateCompanionBuilder =
    QuotaSnapshotsCompanion Function({
      Value<int> id,
      required int accountId,
      required DateTime takenAt,
      required int used,
      Value<int?> total,
    });
typedef $$QuotaSnapshotsTableUpdateCompanionBuilder =
    QuotaSnapshotsCompanion Function({
      Value<int> id,
      Value<int> accountId,
      Value<DateTime> takenAt,
      Value<int> used,
      Value<int?> total,
    });

final class $$QuotaSnapshotsTableReferences
    extends BaseReferences<_$AppDatabase, $QuotaSnapshotsTable, QuotaSnapshot> {
  $$QuotaSnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LinkedAccountsTable _accountIdTable(_$AppDatabase db) => db
      .linkedAccounts
      .createAlias('quota_snapshots__account_id__linked_accounts__id');

  $$LinkedAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$LinkedAccountsTableTableManager(
      $_db,
      $_db.linkedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuotaSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $QuotaSnapshotsTable> {
  $$QuotaSnapshotsTableFilterComposer({
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

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  $$LinkedAccountsTableFilterComposer get accountId {
    final $$LinkedAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.linkedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkedAccountsTableFilterComposer(
            $db: $db,
            $table: $db.linkedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuotaSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuotaSnapshotsTable> {
  $$QuotaSnapshotsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  $$LinkedAccountsTableOrderingComposer get accountId {
    final $$LinkedAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.linkedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkedAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.linkedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuotaSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuotaSnapshotsTable> {
  $$QuotaSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<int> get used =>
      $composableBuilder(column: $table.used, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  $$LinkedAccountsTableAnnotationComposer get accountId {
    final $$LinkedAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.linkedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkedAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.linkedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuotaSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuotaSnapshotsTable,
          QuotaSnapshot,
          $$QuotaSnapshotsTableFilterComposer,
          $$QuotaSnapshotsTableOrderingComposer,
          $$QuotaSnapshotsTableAnnotationComposer,
          $$QuotaSnapshotsTableCreateCompanionBuilder,
          $$QuotaSnapshotsTableUpdateCompanionBuilder,
          (QuotaSnapshot, $$QuotaSnapshotsTableReferences),
          QuotaSnapshot,
          PrefetchHooks Function({bool accountId})
        > {
  $$QuotaSnapshotsTableTableManager(
    _$AppDatabase db,
    $QuotaSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuotaSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuotaSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuotaSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<int> used = const Value.absent(),
                Value<int?> total = const Value.absent(),
              }) => QuotaSnapshotsCompanion(
                id: id,
                accountId: accountId,
                takenAt: takenAt,
                used: used,
                total: total,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int accountId,
                required DateTime takenAt,
                required int used,
                Value<int?> total = const Value.absent(),
              }) => QuotaSnapshotsCompanion.insert(
                id: id,
                accountId: accountId,
                takenAt: takenAt,
                used: used,
                total: total,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuotaSnapshotsTable, QuotaSnapshot>(table),
                  $$QuotaSnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$QuotaSnapshotsTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$QuotaSnapshotsTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QuotaSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuotaSnapshotsTable,
      QuotaSnapshot,
      $$QuotaSnapshotsTableFilterComposer,
      $$QuotaSnapshotsTableOrderingComposer,
      $$QuotaSnapshotsTableAnnotationComposer,
      $$QuotaSnapshotsTableCreateCompanionBuilder,
      $$QuotaSnapshotsTableUpdateCompanionBuilder,
      (QuotaSnapshot, $$QuotaSnapshotsTableReferences),
      QuotaSnapshot,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$BackupRunsTableCreateCompanionBuilder = BackupRunsCompanion Function({
  Value<int> id,
  required int accountId,
  required DateTime at,
  required String snapshotId,
  required bool ok,
  Value<String?> error,
});
typedef $$BackupRunsTableUpdateCompanionBuilder = BackupRunsCompanion Function({
  Value<int> id,
  Value<int> accountId,
  Value<DateTime> at,
  Value<String> snapshotId,
  Value<bool> ok,
  Value<String?> error,
});

final class $$BackupRunsTableReferences
    extends BaseReferences<_$AppDatabase, $BackupRunsTable, BackupRun> {
  $$BackupRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LinkedAccountsTable _accountIdTable(_$AppDatabase db) => db
      .linkedAccounts
      .createAlias('backup_runs__account_id__linked_accounts__id');

  $$LinkedAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$LinkedAccountsTableTableManager(
      $_db,
      $_db.linkedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BackupRunsTableFilterComposer
    extends Composer<_$AppDatabase, $BackupRunsTable> {
  $$BackupRunsTableFilterComposer({
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

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ok => $composableBuilder(
    column: $table.ok,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  $$LinkedAccountsTableFilterComposer get accountId {
    final $$LinkedAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.linkedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkedAccountsTableFilterComposer(
            $db: $db,
            $table: $db.linkedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupRunsTable> {
  $$BackupRunsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ok => $composableBuilder(
    column: $table.ok,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  $$LinkedAccountsTableOrderingComposer get accountId {
    final $$LinkedAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.linkedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkedAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.linkedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupRunsTable> {
  $$BackupRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get ok =>
      $composableBuilder(column: $table.ok, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  $$LinkedAccountsTableAnnotationComposer get accountId {
    final $$LinkedAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.linkedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkedAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.linkedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BackupRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupRunsTable,
          BackupRun,
          $$BackupRunsTableFilterComposer,
          $$BackupRunsTableOrderingComposer,
          $$BackupRunsTableAnnotationComposer,
          $$BackupRunsTableCreateCompanionBuilder,
          $$BackupRunsTableUpdateCompanionBuilder,
          (BackupRun, $$BackupRunsTableReferences),
          BackupRun,
          PrefetchHooks Function({bool accountId})
        > {
  $$BackupRunsTableTableManager(_$AppDatabase db, $BackupRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> snapshotId = const Value.absent(),
                Value<bool> ok = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => BackupRunsCompanion(
                id: id,
                accountId: accountId,
                at: at,
                snapshotId: snapshotId,
                ok: ok,
                error: error,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int accountId,
                required DateTime at,
                required String snapshotId,
                required bool ok,
                Value<String?> error = const Value.absent(),
              }) => BackupRunsCompanion.insert(
                id: id,
                accountId: accountId,
                at: at,
                snapshotId: snapshotId,
                ok: ok,
                error: error,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BackupRunsTable, BackupRun>(table),
                  $$BackupRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$BackupRunsTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$BackupRunsTableReferences
                            ._accountIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BackupRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupRunsTable,
      BackupRun,
      $$BackupRunsTableFilterComposer,
      $$BackupRunsTableOrderingComposer,
      $$BackupRunsTableAnnotationComposer,
      $$BackupRunsTableCreateCompanionBuilder,
      $$BackupRunsTableUpdateCompanionBuilder,
      (BackupRun, $$BackupRunsTableReferences),
      BackupRun,
      PrefetchHooks Function({bool accountId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LinkedAccountsTableTableManager get linkedAccounts =>
      $$LinkedAccountsTableTableManager(_db, _db.linkedAccounts);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$FilesTableTableManager get files =>
      $$FilesTableTableManager(_db, _db.files);
  $$QuotaSnapshotsTableTableManager get quotaSnapshots =>
      $$QuotaSnapshotsTableTableManager(_db, _db.quotaSnapshots);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$BackupRunsTableTableManager get backupRuns =>
      $$BackupRunsTableTableManager(_db, _db.backupRuns);
}
