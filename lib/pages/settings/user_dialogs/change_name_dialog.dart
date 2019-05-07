import 'package:flutter/material.dart';
import 'package:blocs_copyclient/user.dart';

import '../../../string_sanitization.dart';

class ChangeNameDialog extends StatefulWidget {
  final UserBloc userBloc;

  const ChangeNameDialog({Key key, this.userBloc}) : super(key: key);

  @override
  ChangeNameDialogState createState() {
    return ChangeNameDialogState();
  }
}

class ChangeNameDialogState extends State<ChangeNameDialog> {
  final _formKey = GlobalKey<FormState>();

  String _newName;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SimpleDialog(
        title: const Text('Nutzernamen ändern'),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                TextFormField(
                  autocorrect: false,
                  decoration: InputDecoration(labelText: 'Neuer Nutzername'),
                  validator: onValidateUsername,
                  onSaved: (val) => _newName = val,
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
                    widget.userBloc.onChangeUsername(_newName);
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
}
