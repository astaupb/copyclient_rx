import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../models/backend_sunrise.dart';
import 'joblist/joblist.dart';
import 'login/login.dart';

class RootPage extends StatefulWidget {
  RootPage({Key key}) : super(key: key);

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  static final http.Client client = http.Client();
  static final Backend backend = BackendSunrise(client);

  AuthBloc authBloc = AuthBloc(backend: backend);
  JoblistBloc joblistBloc;
  UserBloc userBloc;
  UploadBloc uploadBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      bloc: authBloc,
      child: BlocBuilder<AuthEvent, AuthState>(
        bloc: authBloc,
        builder: (BuildContext context, AuthState state) {
          if (state.isUnauthorized) {
            return LoginPage();
          } else if (state.isBusy) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (state.isAuthorized) {
            // AUTHORIZED AND READY TO HUSTLE
            joblistBloc = JoblistBloc(backend);
            joblistBloc.onStart(state.token);

            userBloc = UserBloc(backend);
            userBloc.onStart(state.token);

            uploadBloc = UploadBloc(backend);
            uploadBloc.onStart(state.token);

            return BlocProvider<JoblistBloc>(
              bloc: joblistBloc,
              child: BlocProvider<UserBloc>(
                bloc: userBloc,
                child: BlocProvider<UploadBloc>(
                  bloc: uploadBloc,
                  child: JoblistPage(),
                ),
              ),
            );
          } else {
            if (state.isException) {
              return Center(child: Text(state.error.toString()));
            }
          }
        },
      ),
    );
  }
}
