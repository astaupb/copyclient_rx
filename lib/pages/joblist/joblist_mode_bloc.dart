import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';

enum JoblistMode { print, scan, copy }

class JoblistModeBloc extends Bloc<JoblistModeEvent, JoblistMode> {
  final Logger _log = Logger('JoblistModeBloc');
  JoblistMode mode;

  JoblistModeBloc(this.mode) : super(JoblistMode.print);

  @override
  Stream<JoblistMode> mapEventToState(JoblistModeEvent event) async* {
    _log.fine('Event: $event');

    if (event is SwitchMode) {
      mode = event.mode;
      yield mode;
    }
  }

  void onSwitch(JoblistMode mode) => add(SwitchMode(mode));
}

abstract class JoblistModeEvent {}

class SwitchMode extends JoblistModeEvent {
  final JoblistMode mode;

  SwitchMode(this.mode);

  @override
  String toString() => '[SwitchMode $mode]';
}
