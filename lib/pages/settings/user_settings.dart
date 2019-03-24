import 'package:blocs_copyclient/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'change_password_dialog.dart';

class UserSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                  child: BlocBuilder(
                    bloc: BlocProvider.of<UserBloc>(context),
                    builder: (BuildContext context, UserState state) {
                      if (state.isResult) {
                        return Column(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Text(
                              state.value?.name,
                              textScaleFactor: 1.5,
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              '${((state.value?.credit ?? 0) / 100.0).toStringAsFixed(2)}€',
                              textScaleFactor: 1.2,
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
              ),
              Spacer(),
              Divider(),
            ],
          ),
          ListTile(
            title: Text('Passwort ändern'),
            onTap: () => _showPasswordDialog(
                context, BlocProvider.of<UserBloc>(context)),
          ),
          ListTile(
            title: Text('Namen/SN ändern'),
            onTap: () => _showUsernameDialog(),
          ),
          ListTile(
            title: Text('Guthaben manuell aufladen'),
            onTap: () => _showCreditTokenDialog(),
          ),
        ].expand((Widget tile) => [tile, Divider(height: 0.0)]).toList(),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, UserBloc userBloc) {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ChangePasswordDialog(userBloc: userBloc));
  }

  void _showUsernameDialog() {
    // TODO: also this username dialog
  }

  void _showCreditTokenDialog() {}
}
