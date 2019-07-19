import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:blocs_copyclient/blocs.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../blocs/camera_bloc.dart';
import '../blocs/theme_bloc.dart';
import '../db_store.dart';
import '../models/backend_shiva.dart';
import '../routes.dart';
import 'login/login.dart';

class RootPage extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  RootPage({Key key}) : super(key: key);

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  static final http.Client client = http.Client();
  static final Backend backend = BackendShiva(client);

  DBStore store = DBStore();

  AuthBloc authBloc = AuthBloc(backend: backend);
  JoblistBloc joblistBloc;
  UserBloc userBloc;
  UploadBloc uploadBloc;
  JournalBloc journalBloc;
  PreviewBloc previewBloc;
  PdfBloc pdfBloc;
  PrintQueueBloc printQueueBloc;
  TokensBloc tokensBloc;

  CameraBloc cameraBloc = CameraBloc();

  String _token;

  StreamSubscription<List<String>> _intentDataStreamSubscription;

  _RootPageState();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      builder: (BuildContext context) => authBloc,
      child: BlocBuilder<AuthEvent, AuthState>(
        bloc: authBloc,
        builder: (BuildContext context, AuthState state) {
          if (state.isAuthorized) {
            if (state.persistent) store.insertToken(state.token);
            // AUTHORIZED AND READY TO HUSTLE
            joblistBloc.onStart(state.token);
            userBloc.onStart(state.token);
            uploadBloc.onStart(state.token);
            journalBloc.onStart(state.token);
            previewBloc.onStart(state.token);
            pdfBloc.onStart(state.token);
            printQueueBloc.onStart(state.token);
            tokensBloc.onStart(state.token);

            // For sharing images coming from outside the app while the app is in the memory
            _intentDataStreamSubscription =
                ReceiveSharingIntent.getPdfStream().listen((List<String> value) {
              // Call reset method if you don't want to see this callback again.
              ReceiveSharingIntent.reset();
              _handleIntentValue(value);
            }, onError: (err) {
              print("getIntentDataStream error: $err");
            });

            // For sharing images coming from outside the app while the app is closed
            ReceiveSharingIntent.getInitialPdf().then((List<String> value) {
              // Call reset method if you don't want to see this callback again.
              ReceiveSharingIntent.reset();
              _handleIntentValue(value);
            });

            return MultiBlocProvider(
              providers: [
                BlocProvider<JoblistBloc>(builder: (BuildContext context) => joblistBloc),
                BlocProvider<UserBloc>(builder: (BuildContext context) => userBloc),
                BlocProvider<UploadBloc>(builder: (BuildContext context) => uploadBloc),
                BlocProvider<JournalBloc>(builder: (BuildContext context) => journalBloc),
                BlocProvider<PreviewBloc>(builder: (BuildContext context) => previewBloc),
                BlocProvider<PdfBloc>(builder: (BuildContext context) => pdfBloc),
                BlocProvider<PrintQueueBloc>(builder: (BuildContext context) => printQueueBloc),
                BlocProvider<CameraBloc>(builder: (BuildContext context) => cameraBloc),
                BlocProvider<TokensBloc>(builder: (BuildContext context) => tokensBloc),
              ],
              child: WillPopScope(
                onWillPop: () async => !await _onWillPop(),
                child: Navigator(
                  key: widget.navigatorKey,
                  initialRoute: '/',
                  onGenerateRoute: (RouteSettings settings) {
                    return MaterialPageRoute(
                      settings: settings,
                      maintainState: true,
                      builder: (context) => routes[settings.name](context),
                    );
                  },
                ),
              ),
            );
          } else if (state.isException) {
            String snackText = 'Fehler: ${state.error}';
            int code = (state.error as ApiException).statusCode;
            if (code == 401) {
              snackText = 'Fehler: Name oder Passwort ist falsch/Nutzer nicht vorhanden';
            } else if (code == 400 || (code > 401 && code < 500)) {
              snackText =
                  'Fehler: Anfrage war fehlerhaft. Falls mehr Fehler auftreten bitte App neu starten';
            } else if (code >= 500 && code < 600) {
              snackText = 'Fehler: Fehler auf dem Server - Bitte unter app@asta.upb.de melden';
            } else if (code == 0) {
              snackText = 'Der Login dauert zu lange, bitte überprüfe deine Internetverbindung';
            }
            return LoginPage(
              authBloc: authBloc,
              startSnack: SnackBar(
                content: Text(snackText),
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state.isBusy || state.isInit) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    (state.isBusy) ? Text('Einloggen...') : Text('Lade Datenbanken...'),
                  ],
                ),
              ),
            );
          } else if (state.isRegistered) {
            return LoginPage(
              authBloc: authBloc,
              startSnack: SnackBar(
                content: Text('Registrierung erfolgreich, bitte logge dich nun ein'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          _initBlocs();
          final List blocs = [
            joblistBloc,
            userBloc,
            uploadBloc,
            journalBloc,
            previewBloc,
            pdfBloc,
            printQueueBloc,
            tokensBloc
          ];

          for (var bloc in blocs) {
            bloc.state.listen(_for401);
          }
          return LoginPage(authBloc: authBloc);
        },
      ),
    );
  }

  @override
  void dispose() {
    final List blocs = [
      joblistBloc,
      userBloc,
      uploadBloc,
      journalBloc,
      previewBloc,
      pdfBloc,
      printQueueBloc,
      tokensBloc
    ];

    for (var bloc in blocs) {
      if (bloc != null) bloc.cancel();
    }

    _intentDataStreamSubscription.cancel();

    super.dispose();
  }

  void _handleIntentValue(var value) async {
    if (value != null) {
      print(value);
      for (String url in value) {
        await PermissionHandler().shouldShowRequestPermissionRationale(PermissionGroup.storage);
        await PermissionHandler().requestPermissions([PermissionGroup.storage]);
        final File file = File(url);
        final String filename = file.path.split('/').last;
        final int numericFilename = int.tryParse(filename);
        uploadBloc.onUpload(file.readAsBytesSync(), filename: (numericFilename == null) ? filename : null);
      }
    }
  }

  void _initBlocs() {
    joblistBloc = JoblistBloc(backend);
    userBloc = UserBloc(backend);
    uploadBloc = UploadBloc(backend);
    journalBloc = JournalBloc(backend);
    previewBloc = PreviewBloc(backend);
    pdfBloc = PdfBloc(backend);
    printQueueBloc = PrintQueueBloc(backend);
    tokensBloc = TokensBloc(backend);
  }

  @override
  void initState() {
    _checkExistingToken();

    super.initState();
  }

  void _for401(state) async {
    if (state.isException && state.error.statusCode == 401) {
      authBloc.logout();
      await DBStore().clearTokens();
      //Navigator.pop(context);
    }
  }

  void _checkExistingToken() async {
    await store.openDb();
    _token = store.currentToken;
    if (_token != null) authBloc.tokenLogin(_token);
    cameraBloc.onStart();
    BlocProvider.of<ThemeBloc>(context).onStart();
  }

  Future<bool> _onWillPop() async {
    final NavigatorState navigator = widget.navigatorKey.currentState;
    assert(navigator != null);
    return await navigator.maybePop();
  }
}
