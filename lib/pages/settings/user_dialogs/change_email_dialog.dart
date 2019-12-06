import 'package:flutter/material.dart';
import 'package:blocs_copyclient/user.dart';

class ChangeEmailDialog extends StatefulWidget {
  final UserBloc userBloc;

  const ChangeEmailDialog({Key key, this.userBloc}) : super(key: key);

  @override
  ChangeEmailDialogState createState() {
    return ChangeEmailDialogState();
  }
}

class ChangeEmailDialogState extends State<ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();

  String _newEmail;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SimpleDialog(
        title: const Text('E-Mail ändern'),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                TextFormField(
                  initialValue: widget.userBloc.state.value.email,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: 'Neue E-Mail'),
                  validator: _validateEmail,
                  onSaved: (val) => _newEmail = val,
                  onEditingComplete: () => _formKey.currentState.validate(),
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
                    widget.userBloc.onChangeEmail(_newEmail);
                    _formKey.currentState.reset();
                    Navigator.pop(context);
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

  String _validateEmail(String value) {
    final email = value.split('@');

    if(email.length == 2 && email[1].contains('.')) {
      print(email);
      return null;
    }
    
    return 'Bitte gebe eine richtige E-Mail Adresse ein';
  }
}
