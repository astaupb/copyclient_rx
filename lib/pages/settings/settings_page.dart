import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Einstellungen'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Benutzer'),
            onTap: () => Navigator.of(context).pushNamed('/settings/user'),
          ),
          ListTile(
            title: Text('Aussehen'),
            onTap: () =>
                Navigator.of(context).pushNamed('/settings/appearance'),
          )
        ],
      ),
    );
  }
}
