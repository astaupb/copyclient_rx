import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

import 'db_store.dart';

class MobileDBStore implements DBStore {
  Map<String, String> _settings;
  final Logger _log = Logger('MobileDBStore');
  Database _db;

  String _currentToken;

  MobileDBStore() {
    _settings = <String, String>{};
  }

  @override
  String get currentToken => _currentToken;

  @override
  Map<String, String> get settings => _settings;

  @override
  Future<void> clearTokens() async {
    _log.info('clearing tokens...');
    await _db.transaction((txn) async {
      var batch = txn.batch();
      batch.delete('Users', where: 'id > 0');
      await batch.commit();
    });
  }

  @override
  Future<String> getCurrentToken() async {
    List<Map> results = await _db.query('Users', columns: ['token'], orderBy: 'id DESC', limit: 1);
    if (results.isNotEmpty) {
      return results[0]['token'] as String;
    } else {
      return null;
    }
  }

  @override
  Future<String> getSetting(String key) async {
    _log.info('getting setting $key from database');
    List<Map> results = await _db.rawQuery('SELECT mapValue FROM Settings WHERE mapKey = "$key"');
    if (results.isNotEmpty) {
      return results[0]['mapValue'] as String;
    } else {
      return null;
    }
  }

  @override
  Future<void> insertSetting(MapEntry entry) async {
    _log.info('inserting settings $entry in database');
    await _db.transaction((txn) async {
      var batch = txn.batch();
      batch.delete('Settings', where: 'mapKey = "${entry.key}"');
      // Insert settings key-value-pair into database
      batch.insert('Settings', <String, dynamic>{'mapKey': entry.key, 'mapValue': entry.value});
      await batch.commit();
    });
  }

  @override
  Future<void> insertToken(String token, {int credit = 0}) async {
    var userId = base64.decode(token)[0];
    _log.info('inserting token for $userId in database');
    await _db.transaction((txn) async {
      var batch = txn.batch();
      batch.delete('Users', where: 'id > 0');
      // Insert username and token and commit to DB
      batch.insert('Users', <String, dynamic>{'user_id': userId, 'token': token, 'credit': credit});
      await batch.commit();
    });
  }

  @override
  Future<void> openDb() async {
    // Get db location
    var basePath = await getDatabasesPath();

    var baseDir = Directory(basePath);

    if (baseDir.listSync().any((FileSystemEntity file) => file.path.contains('users'))) {
      _log.fine('found old database structure in $basePath, deleting all files');
      baseDir.listSync().map((FileSystemEntity entity) {
        _log.fine('deleting ${entity.path.split('/').last}');
        entity.delete();
      });
    }

    var dbPath = basePath + '/copyclient.db';

    _log.fine('opening database file in $dbPath');

    try {
      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE Users(id INTEGER PRIMARY KEY, user_id INTEGER, token TEXT, credit INTEGER)');
          await db
              .execute('CREATE TABLE Settings(id INTEGER PRIMARY KEY, mapKey TEXT, mapValue TEXT)');

          await db
              .execute('INSERT INTO Settings(mapKey,mapValue) VALUES("camera_disabled","false")');
          await db.execute('INSERT INTO Settings(mapKey,mapValue) VALUES("theme","copyshop")');

          _log.info('created new Users and Settings table because it didnt exist yet');
        },
        onOpen: (Database db) async {
          _db = db;
          _currentToken = await getCurrentToken();
          _settings.addAll(
            {
              'theme': await getSetting('theme'),
              'camera_disabled': await getSetting('camera_disabled'),
            },
          );
          _log.fine('currentToken: $currentToken');
        },
      );
    } catch (e) {
      _log.severe('$e');
    }
  }
}
