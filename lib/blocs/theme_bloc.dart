import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../db_store.dart';

final ThemeData astaTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.orange,
  accentColor: Colors.orangeAccent,
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.orange,
    disabledColor: Colors.orange[200],
    colorScheme: ColorScheme.dark(),
    shape: StadiumBorder(),
    minWidth: 16.0,
  ),
);

final ThemeData copyshopTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.pink,
  primaryColor: Colors.pink[600],
  primaryColorLight: Colors.pink[200],
  primaryColorDark: Colors.pink[900],
  accentColorBrightness: Brightness.light,
  accentColor: Colors.teal[800],
  canvasColor: Colors.grey[50],
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.teal[800],
    disabledColor: Colors.teal[200],
    colorScheme: ColorScheme.dark(),
    shape: StadiumBorder(),
    minWidth: 16.0,
  ),
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.android:
          CupertinoPageTransitionsBuilder(), //FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.teal[800],
    disabledColor: Colors.teal[200],
    colorScheme: ColorScheme.dark(),
    shape: StadiumBorder(),
    minWidth: 16.0,
  ),
  bottomAppBarTheme: BottomAppBarTheme(color: Colors.black),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.teal[800],
    //focusColor: Colors.tealAccent,
  ),
);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blue,
    disabledColor: Colors.blue[300],
    colorScheme: ColorScheme.dark(),
    shape: StadiumBorder(),
    minWidth: 16.0,
  ),
);

class ActivateAStATheme extends ThemeEvent {}

class ActivateDarkTheme extends ThemeEvent {}

class ActivateDefaultTheme extends ThemeEvent {}

class ActivateLightTheme extends ThemeEvent {}

enum CopyclientTheme { copyshop, dark, light, asta }

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  DBStore dbStore = DBStore();

  @override
  ThemeState get initialState => ThemeState.copyshopTheme();

  @override
  Stream<ThemeState> mapEventToState(ThemeEvent event) async* {
    if (event is ActivateDarkTheme) {
      await dbStore.insertSetting(MapEntry<String, String>('theme', 'dark'));
      yield ThemeState.darkTheme();
    } else if (event is ActivateLightTheme) {
      await dbStore.insertSetting(MapEntry<String, String>('theme', 'light'));
      yield ThemeState.lightTheme();
    } else if (event is ActivateDefaultTheme) {
      await dbStore.insertSetting(MapEntry<String, String>('theme', 'copyshop'));
      yield ThemeState.copyshopTheme();
    } else if (event is ActivateAStATheme) {
      await dbStore.insertSetting(MapEntry<String, String>('theme', 'asta'));
      yield ThemeState.astaTheme();
    }
  }

  void onSetAStATheme() => add(ActivateAStATheme());

  void onSetCopyshopTheme() => add(ActivateDefaultTheme());

  void onSetDarkTheme() => add(ActivateDarkTheme());

  void onSetLightTheme() => add(ActivateLightTheme());

  void onStart() {
    var theme = dbStore.settings['theme'];
    switch (theme) {
      case 'copyshop':
        onSetCopyshopTheme();
        break;
      case 'dark':
        onSetDarkTheme();
        break;
      case 'light':
        onSetLightTheme();
        break;
      case 'asta':
        onSetAStATheme();
        break;
      default:
    }
  }
}

abstract class ThemeEvent {}

class ThemeState {
  final ThemeData theme;
  final CopyclientTheme id;

  ThemeState(this.theme, this.id);

  factory ThemeState.astaTheme() => ThemeState(astaTheme, CopyclientTheme.asta);

  factory ThemeState.copyshopTheme() => ThemeState(copyshopTheme, CopyclientTheme.copyshop);

  factory ThemeState.darkTheme() => ThemeState(darkTheme, CopyclientTheme.dark);

  factory ThemeState.lightTheme() => ThemeState(lightTheme, CopyclientTheme.light);

  Map<String, dynamic> toMap() => <String, dynamic>{'theme': theme};

  @override
  String toString() => toMap().toString();
}
