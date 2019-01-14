import 'package:flutter/material.dart';

class AppearanceSettingsPage extends StatefulWidget {
  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  bool _darkThemeEnabled = false;

  _AppearanceSettingsPageState() {
    // TODO: use bloc or something to store theme state and mirror to shared preferences
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aussehen'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Dunkles Theme'),
            trailing: Switch(
              onChanged: (bool value) => _darkThemeEnabled = value,
              value: _darkThemeEnabled,
            ),
          ),
        ],
      ),
    );
  }
}
