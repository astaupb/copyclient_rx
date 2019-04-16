import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/theme_bloc.dart';

class AppearanceSettingsPage extends StatefulWidget {
  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  ThemeBloc themeBloc;

  void _changeTheme(bool dark) {
    if (!dark) {
      themeBloc.dispatch(ActivateDefaultTheme());
    } else {
      themeBloc.dispatch(ActivateDarkTheme());
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
          BlocBuilder<ThemeEvent, ThemeState>(
            bloc: themeBloc,
            builder: (BuildContext context, ThemeState state) {
              return ListTile(
                title: Text('Dunkles Theme'),
                onTap: () => _changeTheme(
                      (state.theme.brightness == Brightness.dark)
                          ? false
                          : true,
                    ),
                trailing: Switch(
                  onChanged: (bool value) => _changeTheme(value),
                  value: (state.theme.brightness == Brightness.dark)
                      ? true
                      : false,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
