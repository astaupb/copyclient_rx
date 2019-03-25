import 'package:blocs_copyclient/journal.dart';
import 'package:flutter/material.dart';

class RedeemTokenDialog extends StatefulWidget {
  final JournalBloc journalBloc;

  const RedeemTokenDialog({Key key, this.journalBloc}) : super(key: key);

  @override
  RedeemTokenDialogState createState() {
    return RedeemTokenDialogState();
  }
}

class RedeemTokenDialogState extends State<RedeemTokenDialog> {
  final _formKey = GlobalKey<FormState>();

  String _token;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SimpleDialog(
        title: const Text('Code einlösen'),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                TextFormField(
                  autocorrect: false,
                  decoration: InputDecoration(labelText: 'Aufladecode'),
                  validator: (val) =>
                      val.length < 16 ? 'Code ist mindestens 16-stellig' : null,
                  onSaved: (val) => _token = val,
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
                    widget.journalBloc.onAddTransaction('"$_token"');
                    _formKey.currentState.reset();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Einlösen'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
