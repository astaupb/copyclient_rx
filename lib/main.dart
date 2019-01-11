import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'routes.dart';

void main() => runApp(Copyclient());

class Copyclient extends StatelessWidget {
  Copyclient() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print(
        '[${record.loggerName}] (${record.level.name}) ${record.time.toString().split('.')[0]}: ${record.message}',
      );
    });
    Logger('Copyclient').info('Copyclient started');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Copyclient',
      routes: routes,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.pink,
        primaryColor: Colors.pink[600],
        primaryColorLight: Colors.pink[200],
        primaryColorDark: Colors.pink[900],
        accentColorBrightness: Brightness.light,
        accentColor: Colors.teal[800],
        canvasColor: Colors.grey[50],
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.teal[800],
          disabledColor: Colors.teal[200],
          colorScheme: ColorScheme.dark(),
          shape: StadiumBorder(),
          minWidth: 16.0,
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android:
                CupertinoPageTransitionsBuilder(), //FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
    );
  }
}
