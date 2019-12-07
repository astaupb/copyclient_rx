import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/theme_bloc.dart';

class AppearanceSettingsPage extends StatefulWidget {
  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  ThemeBloc themeBloc;

  @override
  Widget build(BuildContext context) {
    themeBloc = BlocProvider.of<ThemeBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Aussehen'),
      ),
      body: BlocBuilder<ThemeBloc, ThemeState>(
          bloc: themeBloc,
          builder: (BuildContext context, ThemeState state) {
            return ListView(
              children: <Widget>[
                ListTile(
                  title: Text('Aktuelles Theme', textScaleFactor: 1.7),
                ),
                Divider(height: 24.0, indent: 8.0),
                for (var theme in (CopyclientTheme.values.map(
                    (CopyclientTheme theme) => (theme != CopyclientTheme.asta) ? theme : null)))
                  Column(
                    children: <Widget>[
                      ListTile(
                        title: Text(translateThemeId(theme)),
                        onTap: () => _onTapTheme(theme),
                        trailing: (theme == state.id)
                            ? Icon(Icons.check)
                            : Container(height: 0.0, width: 0.0),
                      ),
                      Divider(),
                    ],
                  )
              ],
            );
          }),
    );
  }

  String translateThemeId(CopyclientTheme theme) {
    switch (theme) {
      case CopyclientTheme.copyshop:
        return 'Copyservice';
      case CopyclientTheme.dark:
        return 'Dunkel';
      case CopyclientTheme.light:
        return 'Hell';
      case CopyclientTheme.asta:
        return 'AStA';
      default:
        return '???';
    }
  }

  void _onTapTheme(CopyclientTheme theme) {
    print('switching to theme $theme');
    switch (theme) {
      case CopyclientTheme.copyshop:
        themeBloc.add(ActivateDefaultTheme());
        break;
      case CopyclientTheme.dark:
        themeBloc.add(ActivateDarkTheme());
        break;
      case CopyclientTheme.light:
        themeBloc.add(ActivateLightTheme());
        break;
      case CopyclientTheme.asta:
        themeBloc.add(ActivateAStATheme());
        break;
      default:
        print('theme not found $theme');
    }
  }
}
