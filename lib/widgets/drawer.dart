import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barcode_scan/barcode_scan.dart';

class MainDrawer extends StatefulWidget {
  static const List<String> _headerImages = [
    'images/drawer/screen.jpeg',
  ];

  MainDrawer({
    Key key,
  }) : super(key: key);

  @override
  _MainDrawerState createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  User _currentUser;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          BlocBuilder<UserEvent, UserState>(
            bloc: BlocProvider.of<UserBloc>(context),
            builder: (BuildContext context, state) {
              if (state.isResult) {
                return UserAccountsDrawerHeader(
                  accountName: Text(state.value.username,
                      style: TextStyle(fontSize: 27.0)),
                  accountEmail: Text(
                      'Restliches Guthaben: ${state.value.credit.toString()}'),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(
                          MainDrawer._headerImages[math.Random()
                              .nextInt(MainDrawer._headerImages.length)],
                        ),
                        fit: BoxFit.fill),
                  ),
                );
              } else {
                return UserAccountsDrawerHeader(
                  accountName: Text(''),
                  accountEmail: Text('Restliches Guthaben: '),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(MainDrawer._headerImages[math.Random()
                            .nextInt(MainDrawer._headerImages.length)]),
                        fit: BoxFit.fill),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: Text('Aufladen'),
            trailing: Icon(Icons.credit_card),
            onTap: () async {
              try {
                String token = await BarcodeScanner.scan();
                // TODO: AYYYY
              } catch (e) {}
            },
          ),
          ListTile(
              title: Text('Einstellungen'),
              trailing: Icon(Icons.settings),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/settings');
              }),
          ListTile(
              title: Text('Transaktionsjournal'),
              trailing: Icon(Icons.local_atm),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/transactions');
              }),
          ListTile(
              title: Text('Über'),
              trailing: Icon(Icons.help),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                        title: Text('AStA Copyclient'),
                        contentPadding: EdgeInsets.all(24.0),
                        children: <Widget>[
                          Text('Version 0.1.0+1'),
                          Text('Copyright 2019 AStA Paderborn'),
                          RaisedButton(
                            child: Text('Lizenzen'),
                            onPressed: () => showLicensePage(context: context),
                          )
                        ],
                      );
                    });
                //showAboutDialog(context: context);
              }),
          Divider(),
          ListTile(
            title: Text('Logout'),
            trailing: Icon(Icons.exit_to_app),
            onTap: () {
              _logout();
            },
          ),
          Divider(),
          ListTile(
            title: Text('Schließen'),
            trailing: Icon(Icons.cancel),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _logout() {}
}
