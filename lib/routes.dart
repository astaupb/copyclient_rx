import 'package:flutter/widgets.dart';

import 'pages/joblist/joblist_page.dart';
import 'pages/login/login_page.dart';
import 'pages/register_page.dart';
import 'pages/root_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/settings/user_settings.dart';
import 'pages/settings/appearance_settings.dart';

final routes = {
  '/': (BuildContext context) => RootPage(),
  '/login': (BuildContext context) => LoginPage(),
  '/joblist': (BuildContext context) => JoblistPage(),
  '/settings': (BuildContext context) => SettingsPage(),
  '/settings/user': (BuildContext context) => UserSettingsPage(),
  '/settings/appearance': (BuildContext context) => AppearanceSettingsPage(),
  '/register': (BuildContext context) => RegisterPage(),
};
