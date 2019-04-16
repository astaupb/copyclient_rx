import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

class DBStore {
  static DBStore _instance = DBStore.internal();

  // Make it a singleton
  Logger _log = Logger('DBStore');
  Database _db;
  String _currentToken;

  Map<String, String> _settings = {};

  factory DBStore() => _instance;
  DBStore.internal();

  String get currentToken => _currentToken;
  Map<String, String> get settings => _settings;

  Future<void> clearTokens() async {
    _log.info('clearing tokens...');
    await _db.transaction((txn) async {
      var batch = txn.batch();
      batch.delete('Users', where: 'id > 0');
      await batch.commit();
    });
  }

  Future<String> getCurrentToken(Database db) async {
    List<Map> results = await db.query('Users',
        columns: ['token'], orderBy: 'id DESC', limit: 1);
    if (results.length > 0) {
      return results[0]['token'];
    } else {
      return null;
    }
  }

  Future<String> getSetting(Database db, String key) async {
    _log.info('getting setting $key from database');
    return await db.transaction((txn) async {
      var batch = txn.batch();
      batch.rawQuery('SELECT mapValue FROM Settings WHERE mapKey = "$key"');
      List<dynamic> results = await batch.commit();
      if (results.isNotEmpty) {
        return results[0][0]['mapValue'];
      }
    });
  }

  Future<void> insertSetting(MapEntry entry) async {
    _log.info('inserting settings $entry in database');
    await _db.transaction((txn) async {
      var batch = txn.batch();
      batch.delete('Settings', where: 'mapKey = "${entry.key}"');
      // Insert settings key-value-pair into database
      batch.insert('Settings', {'mapKey': entry.key, 'mapValue': entry.value});
      await batch.commit();
    });
  }

  Future<void> insertToken(String token, {int credit = 0}) async {
    int userId = base64.decode(token)[0];
    _log.info('inserting token for $userId in database');
    await _db.transaction((txn) async {
      var batch = txn.batch();
      batch.delete('Users', where: 'id > 0');
      // Insert username and token and commit to DB
      batch.insert(
          'Users', {'user_id': userId, 'token': token, 'credit': credit});
      await batch.commit();
    });
  }

  Future<void> openDb() async {
    // Get db location
    var basePath = await getDatabasesPath();
    String dbPath = basePath + '/copyclient.db';

    _log.fine('opening database file in $dbPath');

    try {
      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE Users(id INTEGER PRIMARY KEY, user_id INTEGER, token TEXT, credit INTEGER)');
          await db.execute(
              'CREATE TABLE Settings(id INTEGER PRIMARY KEY, mapKey TEXT, mapValue TEXT)');

          await db.execute(
              'INSERT INTO Settings(mapKey,mapValue) VALUES("camera_disabled","false")');
          await db.execute(
              'INSERT INTO Settings(mapKey,mapValue) VALUES("theme","copyshop")');

          _log.info(
              'created new Users and Settings table because it didnt exist yet');
        },
        onOpen: (Database db) async {
          _db = db;
          _currentToken = await getCurrentToken(db);
          _settings.addAll(
            {
              'theme': await getSetting(db, 'theme'),
              'camera_disabled': await getSetting(db, 'camera_disabled'),
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
