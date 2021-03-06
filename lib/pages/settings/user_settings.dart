import 'dart:async';

import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/journal.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../db/db_store.dart';
import 'user_dialogs/change_email_dialog.dart';
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
                      padding: EdgeInsets.fromLTRB(92.0, 24.0, 92.0, 24.0),
                      child: BlocBuilder<UserBloc, UserState>(
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
                    BlocBuilder<UserBloc, UserState>(
                      bloc: userBloc,
                      builder: (BuildContext context, UserState state) {
                        if (state.isResult) {
                          return Padding(
                              padding: EdgeInsets.only(bottom: 8.0, right: 8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    state.value.email ?? '',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(color: Color(0xE6FFFFFF)),
                                  ),
                                  Text(
                                    state.value.userId.toString(),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(color: Color(0xE6FFFFFF)),
                                  ),
                                ],
                              ));
                        } else {
                          return Container(width: 0.0, height: 0.0);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Spacer(),
              BlocBuilder<UserBloc, UserState>(
                bloc: userBloc,
                builder: (BuildContext context, UserState state) {
                  if (state.isResult) {
                    if (state.value.card != null) {
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
                    } else {
                      return Container(width: 0.0, height: 0.0);
                    }
                  } else {
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
            title: Text('E-Mail ändern'),
            onTap: () => _showEmailDialog(context),
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
    await showDialog<RedeemTokenDialog>(
      context: context,
      builder: (BuildContext context) => RedeemTokenDialog(journalBloc: journalBloc),
    );
    await Future<dynamic>.delayed(Duration(seconds: 2)).then((dynamic val) => userBloc.onRefresh());
  }

  void _showDefaultOptionsDialog(BuildContext context) async {
    await showDialog<DefaultOptionsDialog>(
        context: context,
        builder: (BuildContext context) => DefaultOptionsDialog(userBloc: userBloc));
  }

  Future<void> _showPasswordDialog(BuildContext context) async {
    if ((await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => ChangePasswordDialog(userBloc: userBloc))) ??
        false) {
      BlocProvider.of<AuthBloc>(context).onLogout();
      await DBStoreProvider.of(context).db.clearTokens();
    }
  }

  void _showUsernameDialog(BuildContext context) async {
    await showDialog<ChangeNameDialog>(
      context: context,
      builder: (BuildContext context) => ChangeNameDialog(userBloc: userBloc),
    );
  }

  void _showEmailDialog(BuildContext context) async {
    await showDialog<ChangeEmailDialog>(
      context: context,
      builder: (BuildContext context) => ChangeEmailDialog(userBloc: userBloc),
    );
  }
}
