import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/theme_bloc.dart';

class AppearanceSettingsPage extends StatefulWidget {
  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  bool _darkThemeEnabled = false;
  ThemeBloc themeBloc;

  void _toggleDarkTheme() {
    if (_darkThemeEnabled) {
      themeBloc.dispatch(ActivateDefaultTheme());
      setState(() => _darkThemeEnabled = false);
    } else {
      themeBloc.dispatch(ActivateDarkTheme());
      setState(() => _darkThemeEnabled = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    themeBloc = BlocProvider.of<ThemeBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Aussehen'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Dunkles Theme'),
            trailing: Switch(
              onChanged: (bool value) => _toggleDarkTheme(),
              value: _darkThemeEnabled,
            ),
            onTap: () => _toggleDarkTheme(),
          ),
        ],
      ),
    );
  }
}
