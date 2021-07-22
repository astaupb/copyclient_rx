import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';

class DisableHeartbeat extends ScanEvent {}

class EnableHeartbeat extends ScanEvent {}

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final Logger _log = Logger('ScanBloc');
  Timer _timer;

  ScanBloc() : super(ScanState.idle());

  @override
  Stream<ScanState> mapEventToState(ScanEvent event) async* {
    _log.fine('Event: $event');

    if (event is TriggerHeartbeat) {
      yield ScanState.beating(shouldBeat: true);
    } else if (event is EnableHeartbeat) {
      if (_timer?.isActive ?? false) {
        _log.finer('heartbeat already running');
      } else {
        _log.finer('starting heartbeat');
        _timer = Timer.periodic(const Duration(seconds: 50), (Timer t) => add(TriggerHeartbeat()));
      }
    } else if (event is DisableHeartbeat) {
      _log.finer('cancelling heartbeat');
      _timer.cancel();
      yield ScanState.idle();
    }
  }

  void onCancel() => add(DisableHeartbeat());

  void onStart() => add(EnableHeartbeat());
}

abstract class ScanEvent {}

class ScanState {
  final bool isIdle;
  final bool isBeating;

  final bool shouldBeat;

  ScanState(this.isIdle, this.isBeating, this.shouldBeat);

  factory ScanState.beating({bool shouldBeat = false}) => ScanState(false, true, shouldBeat);

  factory ScanState.idle() => ScanState(true, false, false);
}

class TriggerHeartbeat extends ScanEvent {}
