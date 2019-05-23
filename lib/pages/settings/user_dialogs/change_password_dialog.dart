import 'package:flutter/material.dart';
import 'package:blocs_copyclient/user.dart';

class ChangePasswordDialog extends StatefulWidget {
  final UserBloc userBloc;

  const ChangePasswordDialog({Key key, this.userBloc}) : super(key: key);

  @override
  ChangePasswordDialogState createState() {
    return ChangePasswordDialogState();
  }
}

class ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();

  String _oldPassword;
  String _newPassword;
  String _newPasswordRetype;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SimpleDialog(
        title: const Text('Passwort ändern'),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                TextFormField(
                  obscureText: true,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: 'Altes Passwort'),
                  validator: (val) => val.length < 1 ? 'Altes Passwort benötigt' : null,
                  onSaved: (val) => _oldPassword = val,
                ),
                TextFormField(
                  obscureText: true,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: 'Neues Passwort'),
                  validator: (val) =>
                      val.length < 6 ? 'Das neue Passwort sollte länger als 5 Zeichen sein' : null,
                  onSaved: (val) => _newPassword = val,
                ),
                TextFormField(
                  obscureText: true,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: 'Neues Passwort (bestätigen)'),
                  validator: (val) =>
                      val.length < 6 ? 'Das neue Passwort sollte länger als 5 Zeichen sein' : null,
                  onSaved: (val) => _newPasswordRetype = val,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  _formKey.currentState.reset();
                  Navigator.pop(context);
                },
                child: const Text('Schließen'),
              ),
              SimpleDialogOption(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    if (_newPassword == _newPasswordRetype) {
                      widget.userBloc.onChangePassword(_oldPassword, _newPassword);
                      _formKey.currentState.reset();
                      Navigator.pop<bool>(context, true);
                    }
                  }
                },
                child: const Text('Speichern'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
