import 'package:blocs_copyclient/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/teal_outline_button.dart';

class LoginForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  String _username = "";
  String _password = "";
  bool _stayLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.all(20.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    BlocBuilder(
                      bloc: BlocProvider.of<AuthBloc>(context),
                      builder: (BuildContext context, AuthState state) {
                        return TextFormField(
                          controller: TextEditingController(
                              text: (state.isRegistered) ? state.username : ''),
                          decoration: InputDecoration(labelText: 'Nutzername/SN'),
                          validator: (val) => val.length < 1 ? 'Nutzername benötigt' : null,
                          onSaved: (val) => _username = val.trim(),
                          obscureText: false,
                          keyboardType: TextInputType.text,
                          autocorrect: false,
                        );
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Passwort'),
                      validator: (val) => val.length < 1 ? 'Passwort benötigt' : null,
                      onSaved: (val) => _password = val.trim(),
                      obscureText: true,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 40.0, right: 40.0, bottom: 8.0),
                child: RaisedButton(
                  onPressed: () => _submitForm(),
                  child: Text('Login'),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 80.0, right: 80.0, bottom: 8.0),
                child: TealOutlineButton(
                  onPressed: () => setState(() => _stayLoggedIn = !_stayLoggedIn),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text('Login merken '),
                      (!_stayLoggedIn)
                          ? Icon(
                              Icons.check_box_outline_blank,
                              size: 24.0,
                              color: Colors.grey[600],
                            )
                          : Icon(
                              Icons.check_box,
                              size: 24.0,
                              color: Colors.teal[800],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  void _submitForm() {
    final FormState _form = _formKey.currentState;
    _form.save();
    final AuthBloc authBloc = BlocProvider.of<AuthBloc>(context);
    authBloc.login(_username, _password, persistent: _stayLoggedIn);
  }
}
