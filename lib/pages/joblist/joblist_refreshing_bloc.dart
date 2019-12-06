import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:logging/logging.dart';

class ForceRefreshing extends RefreshingEvent {}

class PutUploads extends RefreshingEvent {
  final List<DispatcherTask> uploads;

  PutUploads(this.uploads);
}

class RefreshingBloc extends Bloc<RefreshingEvent, RefreshingState> {
  final Logger _log = Logger('RefreshingBloc');
  List<DispatcherTask> _uploads = [];
  int _lastUploads;

  Timer _timer;

  bool _force = false;

  RefreshingBloc() {
    _lastUploads = 0;
  }

  @override
  RefreshingState get initialState => RefreshingState.idle();

  @override
  Stream<RefreshingState> mapEventToState(RefreshingEvent event) async* {
    _log.fine('Event: $event');

    if (event is ForceRefreshing) {
      _force = true;
      if (_timer?.isActive ?? false) {
        _log.finer('timer already running');
      } else {
        _log.finer('starting locked timer');
        _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => add(Trigger()));
      }
    } else if (event is UnforceRefreshing) {
      _force = false;
      _log.finer('cancelling locked timer');
      _timer.cancel();
      yield RefreshingState.idle();
    } else if (event is PutUploads) {
      _log.finer('${event.uploads.length} ${event.uploads}');
      _uploads = event.uploads;

      if (_uploads.isNotEmpty && !_force) {
        if (_timer?.isActive ?? false) {
          _log.finer('timer already running');
        } else {
          _log.finer('starting timer');
          _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => add(Trigger()));
        }
      } else if (!_force) {
        _log.finer('cancelling timer');
        _timer.cancel();
        yield RefreshingState.idle();
      }
    } else if (event is Trigger) {
      if (_lastUploads < _uploads.length) {
        yield RefreshingState.refreshing(refreshJobs: true, refreshQueue: true);
      } else {
        yield RefreshingState.refreshing(refreshQueue: true, refreshJobs: _force);
      }
    }
  }

  void onAddUploads(List<DispatcherTask> uploads) => add(PutUploads(uploads));

  void onDisableForce() => add(UnforceRefreshing());

  void onEnableForce() => add(ForceRefreshing());
}

abstract class RefreshingEvent {}

class RefreshingState {
  final bool isIdle;
  final bool isRefreshing;

  final bool refreshJobs;
  final bool refreshQueue;

  RefreshingState({
    this.isIdle = false,
    this.isRefreshing = false,
    this.refreshJobs = false,
    this.refreshQueue = false,
  });

  factory RefreshingState.idle() =>
      RefreshingState(isIdle: true, isRefreshing: false, refreshJobs: false, refreshQueue: false);

  factory RefreshingState.refreshing({bool refreshJobs = false, bool refreshQueue = false}) =>
      RefreshingState(
          isRefreshing: true, isIdle: false, refreshJobs: refreshJobs, refreshQueue: refreshQueue);

  Map<String, dynamic> toMap() => <String, dynamic>{'isIdle': isIdle, 'isRefreshing': isRefreshing};

  @override
  String toString() => '[RefreshingState ${toMap().toString()}]';
}

class Trigger extends RefreshingEvent {}

class UnforceRefreshing extends RefreshingEvent {}
