@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/domain/fragment_tag.dart';
import 'package:museflow/core/infrastructure/hive_adapters.dart';
import 'package:museflow/core/infrastructure/temporary_hive_workspace.dart';
import 'package:web/web.dart' as web;

/// SE-9 guard: the `?workspace=temporary` in-memory workspace must never
/// read or write the persistent IndexedDB boxes. This regression test was
/// added after a one-off observation of persistent data loss after visiting
/// temporary mode; it pins the isolation contract the fix relies on.
///
/// Run with: flutter test --platform chrome test/web/temporary_workspace_isolation_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Hive.init('');
    if (!Hive.isAdapterRegistered(HiveTypeIds.fragment)) {
      Hive.registerAdapter(FragmentAdapter());
    }
    await _deleteHiveDatabase('manuscripts');
    await _deleteHiveDatabase('chapters');
    await _deleteHiveDatabase('fragments');
  });

  tearDown(() async {
    await Hive.close();
    await _deleteHiveDatabase('manuscripts');
    await _deleteHiveDatabase('chapters');
    await _deleteHiveDatabase('fragments');
  });

  test(
    'temporary workspace writes stay in memory; persistent data is untouched',
    () async {
      // 1. Seed persistent data the way the normal app boot does.
      final persistent = await Hive.openBox<dynamic>('manuscripts');
      await persistent.put('persistent-id', {'title': '持久文稿'});
      await persistent.close();
      expect(
        await _rawCount('manuscripts'),
        1,
        reason: 'persistent seed must be on disk before temporary mode',
      );
      expect(await _rawHasKey('manuscripts', 'persistent-id'), isTrue);

      // 2. Enter temporary mode exactly like main() does on the web build.
      await openTemporaryHiveWorkspace();
      final tempManuscripts = Hive.box<dynamic>('manuscripts');
      await tempManuscripts.put('temp-id', {'title': '临时文稿'});

      final tempChapters = Hive.box<dynamic>('chapters');
      await tempChapters.put('temp-chapter', {'title': '临时章节'});

      // 3. Temporary reads see only in-memory data.
      expect(tempManuscripts.keys.toSet(), {'temp-id'});

      // 4. The persistent IndexedDB databases are untouched.
      expect(
        await _rawCount('manuscripts'),
        1,
        reason: 'temporary mode must not add keys to the persistent DB',
      );
      expect(
        await _rawHasKey('manuscripts', 'temp-id'),
        isFalse,
        reason: 'temporary writes must never leak to the persistent DB',
      );
      expect(
        await _databaseExists('chapters'),
        isFalse,
        reason: 'temporary mode must not create a persistent chapters DB',
      );

      // 5. Typed boxes (fragments) are equally isolated.
      final tempFragments = await Hive.openBox<Fragment>('fragments');
      await tempFragments.put(
        'f1',
        Fragment(
          id: 'f1',
          text: '临时碎片',
          tags: [FragmentTags.story],
          createdAt: DateTime(2026, 8, 18),
        ),
      );
      expect(
        await _databaseExists('fragments'),
        isFalse,
        reason: 'typed boxes must stay memory-backed in temporary mode',
      );
    },
  );
}

/// Hive CE web stores each box in its own IndexedDB database with a single
/// 'box' object store. These helpers bypass Hive entirely so open in-memory
/// boxes cannot mask what is actually on disk.

Future<bool> _databaseExists(String name) async {
  final databases = await web.window.indexedDB.databases().toDart;
  return databases.toDart.any((db) => db.name == name);
}

Future<void> _deleteHiveDatabase(String name) async {
  if (await _databaseExists(name)) {
    await _idbRequest(web.window.indexedDB.deleteDatabase(name));
  }
}

/// IDBRequest is event-based, not promise-based; bridge it to a Future.
Future<Object?> _idbRequest(web.IDBRequest request) {
  final completer = Completer<Object?>();
  request.onsuccess = ((web.Event _) {
    completer.complete(request.result);
  }).toJS;
  request.onerror = ((web.Event _) {
    completer.completeError(StateError('IDBRequest failed'));
  }).toJS;
  return completer.future;
}

Future<int> _rawCount(String database) async {
  if (!await _databaseExists(database)) return 0;
  final db = await _openDb(database);
  if (db == null) return 0;
  if (db.objectStoreNames.length == 0) {
    db.close();
    return 0;
  }
  final tx = db.transaction('box'.toJS, 'readonly');
  final result = await _idbRequest(tx.objectStore('box').count());
  db.close();
  return (result as JSNumber).toDartInt;
}

Future<bool> _rawHasKey(String database, String key) async {
  if (!await _databaseExists(database)) return false;
  final db = await _openDb(database);
  if (db == null) return false;
  if (db.objectStoreNames.length == 0) {
    db.close();
    return false;
  }
  final tx = db.transaction('box'.toJS, 'readonly');
  final result = await _idbRequest(tx.objectStore('box').get(key.toJS));
  db.close();
  return result != null;
}

Future<web.IDBDatabase?> _openDb(String database) async {
  final db = await _idbRequest(web.window.indexedDB.open(database));
  return db as web.IDBDatabase;
}
