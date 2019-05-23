import 'package:flutter/widgets.dart';

import 'pages/credit/credit_page.dart';
import 'pages/joblist/joblist_page.dart';
import 'pages/register_page.dart';
import 'pages/settings/advanced_settings.dart';
import 'pages/settings/appearance_settings.dart';
import 'pages/settings/security_settings.dart';
import 'pages/settings/settings_page.dart';
import 'pages/settings/user_settings.dart';
import 'pages/transactions/transactions_page.dart';

final routes = {
  '/': (BuildContext context) => JoblistPage(),
  '/settings': (BuildContext context) => SettingsPage(),
  '/settings/user': (BuildContext context) => UserSettingsPage(),
  '/settings/advanced': (BuildContext context) => AdvancedSettingsPage(),
  '/settings/appearance': (BuildContext context) => AppearanceSettingsPage(),
  '/settings/security': (BuildContext context) => SecuritySettingsPage(),
  '/register': (BuildContext context) => RegisterPage(),
  '/credit/transactions': (BuildContext context) => TransactionsPage(),
  '/credit': (BuildContext context) => CreditPage(),
};
