import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final Logger _log = Logger('ScanBloc');
  Timer _timer;

  void onStart() => add(EnableHeartbeat());

  void onCancel() => add(DisableHeartbeat());

  @override
  ScanState get initialState => ScanState.idle();

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
        _timer =
            Timer.periodic(const Duration(seconds: 50), (Timer t) => add(TriggerHeartbeat()));
      }
    } else if (event is DisableHeartbeat) {
      _log.finer('cancelling heartbeat');
      _timer.cancel();
      yield ScanState.idle();
    }
  }
}

class ScanState {
  final bool isIdle;
  final bool isBeating;

  final bool shouldBeat;

  ScanState(this.isIdle, this.isBeating, this.shouldBeat);

  factory ScanState.idle() => ScanState(true, false, false);

  factory ScanState.beating({bool shouldBeat = false}) => ScanState(false, true, shouldBeat);
}

abstract class ScanEvent {}

class EnableHeartbeat extends ScanEvent {}

class DisableHeartbeat extends ScanEvent {}

class TriggerHeartbeat extends ScanEvent {}
