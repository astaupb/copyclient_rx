import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'routes.dart';
import 'blocs/theme_bloc.dart';

void main() => runApp(Copyclient());

class Copyclient extends StatefulWidget {
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
  CopyclientState createState() {
    return new CopyclientState();
  }
}

class CopyclientState extends State<Copyclient> {
  ThemeBloc themeBloc = ThemeBloc();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      bloc: themeBloc,
      child: BlocBuilder(
        bloc: themeBloc,
        builder: (BuildContext context, ThemeState state) => MaterialApp(
              title: 'Copyclient',
              routes: routes,
              initialRoute: '/',
              theme: state.theme,
            ),
      ),
    );
  }
}
