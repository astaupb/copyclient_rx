import 'dart:async';

import 'package:flutter/widgets.dart';

abstract class DBStore {
  String get currentToken;
  Map<String, String> get settings;
  FutureOr<void> clearTokens();
  FutureOr<String> getCurrentToken();
  FutureOr<String> getSetting(String key);
  FutureOr<void> insertSetting(MapEntry<String, String> entry);
  FutureOr<void> insertToken(String token);
  FutureOr<void> openDb();
}

class DBStoreProvider extends InheritedWidget {
  final DBStore db;

  DBStoreProvider({
    Key key,
    @required this.db,
    @required Widget child,
  }) : super(key: key, child: child);

  static DBStoreProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DBStoreProvider>();
  }

  @override
  bool updateShouldNotify(DBStoreProvider oldWidget) {
    return oldWidget.db != db;
  }
}
