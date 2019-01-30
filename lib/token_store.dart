import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

const String scope = "TokenStore:";

class TokenStore {
  // Make it a singleton
  static TokenStore _instance = TokenStore.internal();
  TokenStore.internal();
  factory TokenStore() => _instance;

  Database _db;

  String _currentToken;

  String get currentToken => _currentToken;

  Future<void> openDb() async {
    // Get db location
    var basePath = await getDatabasesPath();
    String dbPath = basePath + '/users.db';

    print('$scope $dbPath');

    try {
      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE Users(id INTEGER PRIMARY KEY, user_id INTEGER, token TEXT, credit INTEGER)');
          print('$scope created new table because it didnt exist yet');
        },
        onOpen: (Database db) async {
          _currentToken = await getCurrentToken(db);
          print('currentToken: $currentToken');
        },
      );
    } catch (e) {
      print("$scope $e");
    }
  }

  Future<void> insertToken(String token, {int credit = 0}) async {
    int userId = base64.decode(token)[0];
    print('$scope inserting token for $userId in database');
    await _db.transaction((txn) async {
      var batch = txn.batch();
      batch.delete('Users', where: 'id > 0');
      // Insert username and token and commit to DB
      batch.insert(
          'Users', {'user_id': userId, 'token': token, 'credit': credit});
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

  Future<void> clearTokens() async {
    print('$scope clearing tokens...');
    await _db.transaction((txn) async {
      var batch = txn.batch();
      batch.delete('Users', where: 'id > 0');
      await batch.commit();
    });
  }
}
