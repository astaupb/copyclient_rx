import 'dart:async';

import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../string_sanitization.dart';

class RegisterPage extends StatefulWidget {
  final AuthBloc authBloc;

  const RegisterPage({Key key, this.authBloc}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _password;
  String _retypedPassword;
  String _username;
  String _email;

  StreamSubscription authListener;

  bool showPw1 = false;
  bool showPw2 = false;

  _RegisterPageState()
      : _password = '',
        _retypedPassword = '',
        _username = '',
        _email = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrieren')),
      body: ListView(
        children: <Widget>[
          _registerForm(),
          BlocBuilder<AuthBloc, AuthState>(
            bloc: widget.authBloc,
            builder: (BuildContext context, AuthState state) {
              if (authListener != null) authListener.cancel();
              authListener = widget.authBloc.listen((AuthState state) {
                if (state.isRegistered) {
                  ScaffoldFeatureController snackbarFeatureController =
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Registrierung erfolgreich'),
                          duration: Duration(seconds: 2)));
                  snackbarFeatureController.closed.then((dynamic val) => Navigator.pop(context));
                } else if (state.isException) {
                  SnackBar snack;
                  var error = state.error as ApiException;
                  if (error.statusCode == 470) {
                    snack = SnackBar(
                        content: Text('Dieser Nutzername ist schon vergeben'),
                        duration: Duration(seconds: 2));
                  } else if (error.statusCode == 471) {
                    snack = SnackBar(
                        content: Text(
                            'Nutzername oder Passwort enthält unerlaubte Zeichen oder ist zu lang (> 32 Zeichen)'),
                        duration: Duration(seconds: 2));
                  } else if (error.statusCode >= 500) {
                    snack = SnackBar(
                        content: Text('Serverfehler - Bitte versuche es in einer Minute noch mal'),
                        duration: Duration(seconds: 2));
                  }

                  ScaffoldMessenger.of(context).showSnackBar(snack);
                  authListener.cancel();
                }
              });

              return Padding(
                padding: EdgeInsets.all(16.0),
                child: RaisedButton(
                  textColor: Colors.white,
                  onPressed: () => _onPressedButton(context, widget.authBloc),
                  child: Text('Registrieren'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void deactivate() {
    if (authListener != null) authListener.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    if (authListener != null) authListener.cancel();
    super.dispose();
  }

  String onValidateEmail(String value) {
    if (!value.contains('@')) {
      return 'Bitte gebe ein gültige E-Mail Adresse ein';
    }
    return null;
  }

  void _onPressedButton(BuildContext context, AuthBloc authBloc) {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      authBloc.onRegister(_username, _password, _email);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registriert neuen Nutzer...'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  Form _registerForm() => Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.always,
        child: Card(
          margin: EdgeInsets.all(8.0),
          child: Padding(
            padding: EdgeInsets.only(bottom: 16.0, left: 8.0, right: 8.0),
            child: Column(
              children: <Widget>[
                TextFormField(
                  autocorrect: false,
                  initialValue: _username,
                  decoration: InputDecoration(labelText: 'Benutzername', hintText: 'maxmuster'),
                  validator: onValidateUsername,
                  onSaved: (value) => _username = value,
                ),
                TextFormField(
                  initialValue: _password,
                  autocorrect: false,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Passwort',
                    suffix: IconButton(
                        iconSize: 20.0,
                        icon: Icon(Icons.remove_red_eye,
                            color: (showPw1) ? Colors.lightBlueAccent : Colors.grey),
                        onPressed: () => setState(() => showPw1 = !showPw1)),
                  ),
                  obscureText: !showPw1,
                  validator: (value) {
                    if (value.length > 5) {
                      _password = value;
                    } else {
                      return 'Ein Passwort muss mindestens 6 Zeichen enthalten';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value,
                ),
                TextFormField(
                  initialValue: _retypedPassword,
                  autocorrect: false,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Passwort bestätigen',
                    suffix: IconButton(
                      iconSize: 20.0,
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: (showPw2) ? Colors.lightBlueAccent : Colors.grey,
                      ),
                      onPressed: () => setState(() => showPw2 = !showPw2),
                    ),
                  ),
                  obscureText: !showPw2,
                  validator: (value) {
                    if (value.length < 5) {
                      return 'Ein Passwort muss mindestens 6 Zeichen enthalten';
                    } else if (value != _password) {
                      return 'Die Passwörter müssen miteinander übereinstimmen';
                    }
                    return null;
                  },
                  onSaved: (value) => _retypedPassword = value,
                ),
                TextFormField(
                  autocorrect: false,
                  initialValue: _email,
                  decoration: InputDecoration(labelText: 'E-Mail', hintText: 'maxmuster@web.de'),
                  validator: onValidateEmail,
                  onSaved: (value) => _email = value,
                ),
              ],
            ),
          ),
        ),
      );
}
