import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'blocs/theme_bloc.dart';
import 'pages/root_page.dart';

void main() {
  runApp(Copyclient());
}

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
    return CopyclientState();
  }
}

class CopyclientState extends State<Copyclient> {
  ThemeBloc themeBloc = ThemeBloc();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      builder: (BuildContext context) => themeBloc,
      child: BlocBuilder(
        bloc: themeBloc,
        builder: (BuildContext context, ThemeState state) => MaterialApp(
              title: 'Copyclient',
              home: RootPage(),
              theme: state.theme,
            ),
      ),
    );
  }
}
