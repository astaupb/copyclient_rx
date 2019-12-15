import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';

import '../db/db_store.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final Logger _log = Logger('CameraBloc');
  final DBStore _dbStore;

  CameraBloc(this._dbStore);

  @override
  CameraState get initialState => CameraState.enabled();

  @override
  Stream<CameraState> mapEventToState(event) async* {
    _log.fine('Event: $event');

    if (event is DisableCamera) {
      await _dbStore.insertSetting(MapEntry<String, String>('camera_disabled', 'true'));
      yield CameraState.disabled();
    } else if (event is EnableCamera) {
      await _dbStore.insertSetting(MapEntry<String, String>('camera_disabled', 'false'));
      yield CameraState.enabled();
    }
  }

  void onDisable() => add(DisableCamera());

  void onEnable() => add(EnableCamera());

  void onStart() async {
    if (_dbStore.settings['camera_disabled'] == 'true') {
      onDisable();
    } else {
      onEnable();
    }
  }

  @override
  void onTransition(Transition<CameraEvent, CameraState> transition) {
    _log.fine('Transition from ${transition.currentState} to ${transition.nextState}');
    super.onTransition(transition);
  }
}

abstract class CameraEvent {}

class CameraState {
  final bool cameraDisabled;

  CameraState(this.cameraDisabled);

  factory CameraState.disabled() => CameraState(true);

  factory CameraState.enabled() => CameraState(false);

  Map<String, bool> toMap() => {'camera_disabled': cameraDisabled};

  @override
  String toString() => 'CameraState: ${toMap().toString()}';
}

class DisableCamera extends CameraEvent {}

class EnableCamera extends CameraEvent {}
