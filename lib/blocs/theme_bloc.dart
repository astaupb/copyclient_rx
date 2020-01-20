import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../db/db_store.dart';

const double dense = -2.0;

const double normal = 0.0;

const double spacey = 4.0;

const double veryDense = -4.0;

ThemeData astaTheme(VisualDensity density) => ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.orange,
      accentColor: Colors.orangeAccent,
      visualDensity: density,
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.orange,
        disabledColor: Colors.orange[200],
        colorScheme: ColorScheme.dark(),
        shape: StadiumBorder(),
        minWidth: 16.0,
      ),
    );

ThemeData copyshopTheme(VisualDensity density) => ThemeData(
      brightness: Brightness.light,
      visualDensity: density,
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

ThemeData darkTheme(VisualDensity density) => ThemeData(
      brightness: Brightness.dark,
      visualDensity: density,
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

ThemeData lightTheme(VisualDensity density) => ThemeData(
      brightness: Brightness.light,
      visualDensity: density,
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.blue,
        disabledColor: Colors.blue[300],
        colorScheme: ColorScheme.dark(),
        shape: StadiumBorder(),
        minWidth: 16.0,
      ),
    );

DensityLevel visualToDensity(VisualDensity density) {
  if (density.horizontal == veryDense) {
    return DensityLevel.veryDense;
  } else if (density.horizontal == dense) {
    return DensityLevel.dense;
  } else if (density.horizontal == normal) {
    return DensityLevel.normal;
  } else if (density.horizontal == spacey) {
    return DensityLevel.spacey;
  }
  return DensityLevel.normal;
}

class ActivateAStATheme extends ThemeEvent {}

class ActivateDarkTheme extends ThemeEvent {}

class ActivateDefaultTheme extends ThemeEvent {}

class ActivateLightTheme extends ThemeEvent {}

enum CopyclientTheme { copyshop, dark, light, asta }
enum DensityLevel { veryDense, dense, normal, spacey }

class SetDensity extends ThemeEvent {
  final DensityLevel density;

  SetDensity(this.density);

  @override
  String toString() => '[SetDensity $density]';
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  DensityLevel _density = DensityLevel.normal;

  DensityLevel get density => _density;
  final DBStore _dbStore;

  ThemeBloc(this._dbStore);

  ThemeState _lastState;

  @override
  ThemeState get initialState => ThemeState.copyshopTheme(_getVisualDensity(density));

  @override
  Stream<ThemeState> mapEventToState(ThemeEvent event) async* {
    if (event is ActivateDarkTheme) {
      await _dbStore.insertSetting(MapEntry<String, String>('theme', 'dark'));
      _lastState = ThemeState.darkTheme(_getVisualDensity(density));
      yield _lastState;
    } else if (event is ActivateLightTheme) {
      await _dbStore.insertSetting(MapEntry<String, String>('theme', 'light'));
      _lastState = ThemeState.lightTheme(_getVisualDensity(density));
      yield _lastState;
    } else if (event is ActivateDefaultTheme) {
      await _dbStore.insertSetting(MapEntry<String, String>('theme', 'copyshop'));
      _lastState = ThemeState.copyshopTheme(_getVisualDensity(density));
      yield _lastState;
    } else if (event is ActivateAStATheme) {
      await _dbStore.insertSetting(MapEntry<String, String>('theme', 'asta'));
      _lastState = ThemeState.astaTheme(_getVisualDensity(density));
      yield _lastState;
    } else if (event is SetDensity) {
      await _dbStore
          .insertSetting(MapEntry<String, String>('density', _getDensityString(event.density)));
      _density = event.density;
      switch (_lastState.id) {
        case CopyclientTheme.copyshop:
          yield ThemeState.copyshopTheme(_getVisualDensity(density));
          break;
        case CopyclientTheme.dark:
          yield ThemeState.darkTheme(_getVisualDensity(density));
          break;
        case CopyclientTheme.light:
          yield ThemeState.lightTheme(_getVisualDensity(density));
          break;
        case CopyclientTheme.asta:
          yield ThemeState.astaTheme(_getVisualDensity(density));
          break;
        default:
          yield ThemeState.copyshopTheme(_getVisualDensity(density));
          break;
      }
    }
  }

  void onSetAStATheme() => add(ActivateAStATheme());

  void onSetCopyshopTheme() => add(ActivateDefaultTheme());

  void onSetDarkTheme() => add(ActivateDarkTheme());

  void onSetDensity(DensityLevel density) => add(SetDensity(density));

  void onSetLightTheme() => add(ActivateLightTheme());

  void onStart() {
    var theme = _dbStore.settings['theme'];
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
        onSetCopyshopTheme();
        break;
    }

    var density = _dbStore.settings['density'];
    switch (density) {
      case 'very_dense':
        add(SetDensity(DensityLevel.veryDense));
        break;
      case 'dense':
        add(SetDensity(DensityLevel.dense));
        break;
      case 'normal':
        add(SetDensity(DensityLevel.normal));
        break;
      case 'spacey':
        add(SetDensity(DensityLevel.spacey));
        break;
      default:
        add(SetDensity(DensityLevel.normal));
        break;
    }
  }

  String _getDensityString(DensityLevel density) {
    switch (density) {
      case DensityLevel.veryDense:
        return 'very_dense';
      case DensityLevel.dense:
        return 'dense';
      case DensityLevel.normal:
        return 'normal';
      case DensityLevel.spacey:
        return 'spacey';
      default:
        return 'normal';
    }
  }

  static VisualDensity _getVisualDensity(DensityLevel density) {
    switch (density) {
      case DensityLevel.veryDense:
        return VisualDensity(horizontal: veryDense, vertical: veryDense);
      case DensityLevel.dense:
        return VisualDensity(horizontal: dense, vertical: dense);
      case DensityLevel.normal:
        return VisualDensity(horizontal: normal, vertical: normal);
      case DensityLevel.spacey:
        return VisualDensity(horizontal: spacey, vertical: spacey);
      default:
        return VisualDensity(horizontal: normal, vertical: normal);
    }
  }
}

abstract class ThemeEvent {}

class ThemeState {
  final ThemeData theme;
  final CopyclientTheme id;
  final DensityLevel density;

  ThemeState(this.theme, this.id, this.density);

  factory ThemeState.astaTheme(VisualDensity density) =>
      ThemeState(astaTheme(density), CopyclientTheme.asta, visualToDensity(density));

  factory ThemeState.copyshopTheme(VisualDensity density) =>
      ThemeState(copyshopTheme(density), CopyclientTheme.copyshop, visualToDensity(density));

  factory ThemeState.darkTheme(VisualDensity density) =>
      ThemeState(darkTheme(density), CopyclientTheme.dark, visualToDensity(density));

  factory ThemeState.lightTheme(VisualDensity density) =>
      ThemeState(lightTheme(density), CopyclientTheme.light, visualToDensity(density));

  Map<String, dynamic> toMap() => <String, dynamic>{'theme': theme};

  @override
  String toString() => toMap().toString();
}
