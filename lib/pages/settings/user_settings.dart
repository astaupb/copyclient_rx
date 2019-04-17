import 'dart:async';

import 'package:blocs_copyclient/journal.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'user_dialogs/change_name_dialog.dart';
import 'user_dialogs/change_password_dialog.dart';
import 'user_dialogs/default_options_dialog.dart';
import 'user_dialogs/redeem_token_dialog.dart';

class UserSettingsPage extends StatelessWidget {
  static UserBloc userBloc;

  @override
  Widget build(BuildContext context) {
    userBloc = BlocProvider.of<UserBloc>(context);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(40.0, 24.0, 40.0, 24.0),
                      child: BlocBuilder<UserEvent, UserState>(
                        bloc: userBloc,
                        builder: (BuildContext context, UserState state) {
                          if (state.isResult) {
                            return Column(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Text(
                                  state.value?.name,
                                  textScaleFactor: 1.5,
                                  style:
                                      TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                Divider(),
                                Text(
                                  '${((state.value?.credit ?? 0) / 100.0).toStringAsFixed(2)}€',
                                  textScaleFactor: 1.3,
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
                    BlocBuilder<UserEvent, UserState>(
                      bloc: userBloc,
                      builder: (BuildContext context, UserState state) {
                        if (state.isResult)
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8.0, right: 8.0),
                            child: Text(
                              state.value.userId.toString(),
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Color(0xE6FFFFFF)),
                            ),
                          );
                        else
                          Container(width: 0.0, height: 0.0);
                      },
                    ),
                  ],
                ),
              ),
              Spacer(),
              BlocBuilder<UserEvent, UserState>(
                bloc: userBloc,
                builder: (BuildContext context, UserState state) {
                  if (state.isResult) {
                    if (state.value.card != null)
                      return Padding(
                        padding: EdgeInsets.only(right: 24.0),
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.credit_card,
                              size: 48.0,
                            ),
                            Text('${state.value.card}', textScaleFactor: 1.2),
                            Text('${state.value.pin}', textScaleFactor: 1.2),
                          ],
                        ),
                      );
                    else
                      return Container(width: 0.0, height: 0.0);
                  }
                },
              ),
              //(state.value.card != null) ? Spacer() : Container(width: 0.0, height: 0.0),
            ],
          ),
          ListTile(
            title: Text('Passwort/PIN ändern'),
            onTap: () => _showPasswordDialog(context),
          ),
          ListTile(
            title: Text('Namen/SN ändern'),
            onTap: () => _showUsernameDialog(context),
          ),
          ListTile(
            title: Text('Standard-Joboptionen festlegen'),
            subtitle: Text(
                'Alle hochgeladenen Drucke, PDFs oder Scans bekommen automatisch die hier festgelegten Optionen eingestellt'),
            onTap: () => _showDefaultOptionsDialog(context),
          ),
          ListTile(
            title: Text('Guthaben manuell aufladen'),
            subtitle: Text(
                'Für Handys mit defekter Kamera. Die Zeichenfolgen die hinter den QR Codes stecken kannst du hier manuell eingeben.'),
            onTap: () => _showCreditTokenDialog(context, BlocProvider.of<JournalBloc>(context)),
          ),
        ].expand((Widget tile) => [tile, Divider(height: 0.0)]).toList(),
      ),
    );
  }

  void _showCreditTokenDialog(BuildContext context, JournalBloc journalBloc) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => RedeemTokenDialog(journalBloc: journalBloc),
    );
    Future.delayed(Duration(seconds: 2)).then((val) => userBloc.onRefresh());
  }

  _showDefaultOptionsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) => DefaultOptionsDialog(userBloc: userBloc));
  }

  void _showPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ChangePasswordDialog(userBloc: userBloc),
    );
  }

  void _showUsernameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ChangeNameDialog(userBloc: userBloc),
    );
  }
}
