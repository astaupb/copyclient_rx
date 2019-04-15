import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';

import '../db_store.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  Logger _log = Logger('CameraBloc');
  DBStore _dbStore = DBStore();

  @override
  get initialState => CameraState.enabled();

  @override
  Stream<CameraState> mapEventToState(event) async* {
    _log.fine('Event: $event');

    if (event is DisableCamera) {
      _dbStore.insertSetting(MapEntry('camera_disabled', 'true'));
      yield CameraState.disabled();
    } else if (event is EnableCamera) {
      _dbStore.insertSetting(MapEntry('camera_disabled', 'false'));
      yield CameraState.enabled();
    }
  }

  @override
  void onTransition(Transition transition) {
    _log.fine(
        'Transition from ${transition.currentState} to ${transition.nextState}');
    super.onTransition(transition);
  }

  void onEnable() => dispatch(EnableCamera());

  void onDisable() => dispatch(DisableCamera());

  void onStart() async {
    if (await _dbStore.getSetting('camera_disabled') == 'true')
      onDisable();
    else
      onEnable();
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
