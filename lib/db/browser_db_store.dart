import 'dart:convert' show base64;
import 'package:universal_html/html.dart' show window;

import 'package:logging/logging.dart' show Logger;

import 'db_store.dart';

class BrowserDBStore implements DBStore {
  final Logger _log = Logger('BrowserDBStore');

  Map<String, String> _settings;
  String _token;

  @override
  String get currentToken => _token;

  @override
  Map<String, String> get settings => _settings;

  BrowserDBStore() {
    _settings = <String, String>{};
  }

  @override
  void clearTokens() {
    _log.info('clearing tokens...');
    _token = null;
    window.localStorage['app_token'] = '';
  }

  @override
  String getCurrentToken() {
    _token = window.localStorage['app_token'];
    return _token;
  }

  @override
  String getSetting(String key) {
    _log.info('getting setting $key from localStorage');
    if (window.localStorage.containsKey('setting_$key')) {
      return window.localStorage['setting_$key'];
    } else {
      return null;
    }
  }

  @override
  void insertSetting(MapEntry<String, String> entry) {
    _log.info('inserting settings $entry in localStorage');
    _settings.addAll({entry.key: entry.value});
    window.localStorage['setting_${entry.key}'] = entry.value.toString();
  }

  @override
  void insertToken(String token) {
    var userId = base64.decode(token)[0];
    _log.info('inserting token for $userId in database');
    _token = token;
    window.localStorage['app_token'] = _token;
  }

  @override
  void openDb() {
    if (window.localStorage['setting_theme'] == null ||
        window.localStorage['setting_theme'].isEmpty) {
      _settings.addAll({'theme': 'copyshop'});
      window.localStorage['setting_theme'] = 'copyshop';
    }
  }
}
