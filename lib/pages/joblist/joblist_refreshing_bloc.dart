import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:logging/logging.dart';

class PutUploads extends RefreshingEvent {
  final List<DispatcherTask> uploads;

  PutUploads(this.uploads);
}

class RefreshingBloc extends Bloc<RefreshingEvent, RefreshingState> {
  Logger _log = Logger('RefreshingBloc');
  List<DispatcherTask> _uploads = [];
  int _lastUploads = 0;

  Timer _timer;

  @override
  get initialState => RefreshingState.idle();

  @override
  Stream<RefreshingState> mapEventToState(RefreshingEvent event) async* {
    if (event is PutUploads) {
      _log.finer('[RefreshingBloc] ${event.uploads.length} ${event.uploads}');
      _uploads = event.uploads;

      if (_uploads.isNotEmpty) {
        if (_timer?.isActive ?? false) {
          _log.finer('[RefreshingBloc] timer already running');
        } else {
          _log.finer('[RefreshingBloc] starting timer');
          _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => this.add(Trigger()));
        }
      } else {
        _log.finer('[RefreshingBloc] cancelling timer');
        _timer.cancel();
        yield RefreshingState.idle();
      }
    } else if (event is Trigger) {
      if (_lastUploads < _uploads.length) {
        yield RefreshingState.refreshing(refreshJobs: true, refreshQueue: true);
      } else {
        yield RefreshingState.refreshing(refreshQueue: true, refreshJobs: false);
      }
    }
  }

  void onAddUploads(List<DispatcherTask> uploads) => this.add(PutUploads(uploads));
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

  Map<String, dynamic> toMap() => {'isIdle': isIdle, 'isRefreshing': isRefreshing};

  @override
  String toString() => '[RefreshingState ${toMap().toString()}]';
}

class Trigger extends RefreshingEvent {}
