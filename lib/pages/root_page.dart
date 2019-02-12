import 'dart:async';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/journal.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:blocs_copyclient/preview.dart';
import 'package:blocs_copyclient/src/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../models/backend_shiva.dart';
import '../routes.dart';
import 'login/login.dart';
import '../token_store.dart';

class RootPage extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  RootPage({Key key}) : super(key: key);

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  static final http.Client client = http.Client();
  static final Backend backend = BackendShiva(client);

  TokenStore store = TokenStore();

  AuthBloc authBloc = AuthBloc(backend: backend);
  JoblistBloc joblistBloc;
  UserBloc userBloc;
  UploadBloc uploadBloc;
  JournalBloc journalBloc;
  PreviewBloc previewBloc;

  String _token;

  _RootPageState() {
    _token = store.currentToken;
    if (_token != null) authBloc.tokenLogin(_token);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      bloc: authBloc,
      child: BlocBuilder<AuthEvent, AuthState>(
        bloc: authBloc,
        builder: (BuildContext context, AuthState state) {
          if (state.isAuthorized) {
            if (state.persistent) store.insertToken(state.token);
            // AUTHORIZED AND READY TO HUSTLE
            joblistBloc = JoblistBloc(backend);
            joblistBloc.onStart(state.token);

            userBloc = UserBloc(backend);
            userBloc.onStart(state.token);

            uploadBloc = UploadBloc(backend);
            uploadBloc.onStart(state.token);

            journalBloc = JournalBloc(backend);
            journalBloc.onStart(state.token);

            previewBloc = PreviewBloc(backend);
            previewBloc.onStart(state.token);

            return BlocProvider<JoblistBloc>(
              bloc: joblistBloc,
              child: BlocProvider<UserBloc>(
                bloc: userBloc,
                child: BlocProvider<UploadBloc>(
                  bloc: uploadBloc,
                  child: BlocProvider<JournalBloc>(
                    bloc: journalBloc,
                    child: BlocProvider<PreviewBloc>(
                      bloc: previewBloc,
                      child: WillPopScope(
                        onWillPop: () async => !await _onWillPop(),
                        child: Navigator(
                          key: widget.navigatorKey,
                          initialRoute: '/',
                          onGenerateRoute: (RouteSettings settings) {
                            return MaterialPageRoute(
                              settings: settings,
                              maintainState: true,
                              builder: (context) =>
                                  routes[settings.name](context),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else if (state.isException) {
            String snackText = 'Fehler: ${state.error}';
            int code = (state.error as ApiException).statusCode;
            if (code == 401) {
              snackText = 'Fehler: Name oder Passwort ist falsch/Nutzer nicht vorhanden';
            } else if(code == 400 || (code > 401 && code < 500)) {
              snackText = 'Fehler: Anfrage war fehlerhaft. Falls mehr Fehler auftreten bitte App neu starten';
            } else if(code >= 500 && code < 600) {
              snackText = 'Fehler: Fehler auf dem Server - Bitte unter app@asta.upb.de melden';
            }
            SnackBar snackBar;
            return LoginPage(
              startSnack: SnackBar(
                content: Text(snackText),
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state.isBusy) {
            return Scaffold();
          } else if (state.isUnauthorized) {
            if (store.currentToken != null) {
              store.clearTokens();
            }
          }
          return LoginPage(authBloc: authBloc);
        },
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final NavigatorState navigator = widget.navigatorKey.currentState;
    assert(navigator != null);
    return await navigator.maybePop();
  }
}
