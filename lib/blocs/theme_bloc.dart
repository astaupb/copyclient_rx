import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../db_store.dart';

enum CopyclientTheme {
  copyshop,
  dark,
  light,
  custom
}

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
    backgroundColor: Colors.teal,
    //focusColor: Colors.tealAccent,
  ),
);

class ActivateDarkTheme extends ThemeEvent {}

class ActivateDefaultTheme extends ThemeEvent {}

class ActivateLightTheme extends ThemeEvent {}

class ChangeTheme extends ThemeEvent {
  final ThemeData newTheme;

  ChangeTheme(this.newTheme);
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  DBStore dbStore = DBStore();

  @override
  get initialState => ThemeState.copyshopTheme();

  @override
  Stream<ThemeState> mapEventToState(ThemeEvent event) async* {
    if (event is ChangeTheme) {
      yield ThemeState.custom(event.newTheme);
    }
    if (event is ActivateDarkTheme) {
      dbStore.insertSetting(MapEntry('theme', 'dark'));
      yield ThemeState.darkTheme();
    }
    if (event is ActivateLightTheme) {
      dbStore.insertSetting(MapEntry('theme', 'light'));
      yield ThemeState.lightTheme();
    }
    if (event is ActivateDefaultTheme) {
      dbStore.insertSetting(MapEntry('theme', 'copyshop'));
      yield ThemeState.copyshopTheme();
    }
  }

  void onSetCopyshopTheme() => this.add(ActivateDefaultTheme());

  void onSetDarkTheme() => this.add(ActivateDarkTheme());

  void onSetLightTheme() => this.add(ActivateLightTheme());

  void onStart() {
    String theme = dbStore.settings['theme'];
    if (theme == 'copyshop') {
      onSetCopyshopTheme();
    } else if (theme == 'dark') {
      onSetDarkTheme();
    } else if (theme == 'light') {
      onSetLightTheme();
    }
  }
}

abstract class ThemeEvent {}

class ThemeState {
  final ThemeData theme;
  final CopyclientTheme id;

  ThemeState(this.theme, this.id);

  factory ThemeState.copyshopTheme() => ThemeState(copyshopTheme, CopyclientTheme.copyshop);

  factory ThemeState.custom(ThemeData theme) => ThemeState(theme, CopyclientTheme.custom);

  factory ThemeState.darkTheme() => ThemeState(darkTheme, CopyclientTheme.dark);

  factory ThemeState.lightTheme() => ThemeState(ThemeData.light(), CopyclientTheme.light);

  Map<String, dynamic> toMap() => {'theme': theme};

  @override
  String toString() => toMap().toString();
}
