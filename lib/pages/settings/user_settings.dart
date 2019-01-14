import 'package:blocs_copyclient/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: use user bloc again when user routes give me something
    //final UserBloc userBloc = BlocProvider.of<UserBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Benutzer'),
      ),
      body: ListView(
        children: <Widget>[
          Row(
            children: <Widget>[
              Spacer(),
              Card(
                margin: EdgeInsets.all(24.0),
                color: Colors.grey[700],
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Text(
                        'Name',
                        textScaleFactor: 1.5,
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        'x,xx€',
                        textScaleFactor: 1.2,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
          Divider(),
          ListTile(
            title: Text('Passwort ändern'),
            onTap: () => _showPasswordDialog(),
          ),
          ListTile(
            title: Text('Namen/SN ändern'),
            onTap: () => _showUsernameDialog(),
          ),
          ListTile(
            title: Text('Guthaben manuell aufladen'),
            onTap: () => _showCreditTokenDialog(),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    // TODO: show that password dialog
  }

  void _showUsernameDialog() {
    // TODO: also this username dialog
  }

  void _showCreditTokenDialog() {}
}
