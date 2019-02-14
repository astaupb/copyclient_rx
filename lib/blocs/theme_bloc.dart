import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

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

class ActivateDarkTheme extends ThemeEvent {}

class ActivateDefaultTheme extends ThemeEvent {}

class ActivateLightTheme extends ThemeEvent {}

class ChangeTheme extends ThemeEvent {
  final ThemeData newTheme;

  ChangeTheme(this.newTheme);
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  @override
  get initialState => ThemeState.copyshopTheme();

  @override
  Stream<ThemeState> mapEventToState(
      ThemeState currentState, ThemeEvent event) async* {
    if (event is ChangeTheme) {
      yield ThemeState.custom(event.newTheme);
    }
    if (event is ActivateDarkTheme) {
      yield ThemeState.darkTheme();
    }
    if (event is ActivateLightTheme) {
      yield ThemeState.lightTheme();
    }
    if (event is ActivateDefaultTheme) {
      yield ThemeState.copyshopTheme();
    }
  }
}

abstract class ThemeEvent {}

class ThemeState {
  final ThemeData theme;

  ThemeState(this.theme);

  factory ThemeState.copyshopTheme() => ThemeState(copyshopTheme);

  factory ThemeState.custom(ThemeData theme) => ThemeState(theme);

  factory ThemeState.darkTheme() => ThemeState(ThemeData.dark());

  factory ThemeState.lightTheme() => ThemeState(ThemeData.light());

  Map<String, dynamic> toMap() => {'theme': theme};

  @override
  String toString() => toMap().toString();
}
