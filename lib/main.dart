import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'blocs/camera_bloc.dart';
import 'blocs/theme_bloc.dart';
import 'db/browser_db_store.dart';
import 'db/db_store.dart';
import 'db/mobile_db_store.dart';
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
  DBStore _dbStore;
  ThemeBloc themeBloc;
  CameraBloc cameraBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (BuildContext context) => themeBloc),
        BlocProvider<CameraBloc>(create: (BuildContext context) => cameraBloc),
      ],
      child: DBStoreProvider(
        db: _dbStore,
        child: BlocBuilder(
          bloc: themeBloc,
          builder: (BuildContext context, ThemeState state) => MaterialApp(
            title: 'Copyclient',
            home: RootPage(),
            theme: state.theme,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    themeBloc.close();
    cameraBloc.close();
    super.dispose();
  }

  @override
  void initState() {
    if (!kIsWeb) {
      _dbStore = MobileDBStore();
    } else {
      _dbStore = BrowserDBStore();
    }

    themeBloc = ThemeBloc(_dbStore);
    cameraBloc = CameraBloc(_dbStore);

    super.initState();
  }
}
