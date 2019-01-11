import 'package:flutter/widgets.dart';

import 'pages/joblist/joblist_page.dart';
import 'pages/login/login_page.dart';
import 'pages/register_page.dart';
import 'pages/root_page.dart';

final routes = {
  '/': (BuildContext context) => RootPage(),
  '/login': (BuildContext context) => LoginPage(),
  '/joblist': (BuildContext context) => JoblistPage(),
  '/register': (BuildContext context) => RegisterPage(),
};
