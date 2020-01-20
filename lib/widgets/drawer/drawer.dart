import 'package:blocs_copyclient/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info/package_info.dart';

import '../../db/db_store.dart';
import 'drawer_header.dart' as my;

class MainDrawer extends StatelessWidget {
  MainDrawer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          my.DrawerHeader(),
          ListTile(
            title: Text('Guthaben'),
            trailing: Icon(Icons.credit_card),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/credit');
            },
          ),
          ListTile(
            title: Text('Einstellungen'),
            trailing: Icon(Icons.settings),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
          ),
          ListTile(
            title: Text('Über'),
            trailing: Icon(Icons.help),
            onTap: () async {
              final packageInfo = await PackageInfo.fromPlatform();
              Navigator.of(context).pop();
              await showDialog<SimpleDialog>(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Text('AStA Copyclient'),
                    contentPadding: EdgeInsets.all(24.0),
                    children: <Widget>[
                      Divider(),
                      Text('Paketname: \n${packageInfo.packageName}'),
                      Text('\nVersion: \n${packageInfo.version}+${packageInfo.buildNumber}'),
                      Divider(),
                      Text('Copyright © AStA Paderborn 2019'),
                      RaisedButton(
                        child: Text('Lizenzen'),
                        onPressed: () => showLicensePage(context: context),
                      )
                    ],
                  );
                },
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text('Logout'),
            trailing: Icon(Icons.exit_to_app),
            onTap: () async {
              BlocProvider.of<AuthBloc>(context).onLogout();
              await DBStoreProvider.of(context).db.clearTokens();
              Navigator.of(context).popUntil(ModalRoute.withName('/'));
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
}
