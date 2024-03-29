import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';

class ClearItems extends SelectionEvent {}

class SelectionBloc extends Bloc<SelectionEvent, SelectionState> {
  final Logger _log = Logger('SelectionBloc');

  List<int> items = [];

  SelectionBloc() : super(SelectionState.empty());

  @override
  Stream<SelectionState> mapEventToState(event) async* {
    _log.fine('Event: $event');

    if (event is ToggleItem) {
      if (items.contains(event.id)) {
        items.remove(event.id);
      } else {
        items.add(event.id);
      }
      yield SelectionState.result(items);
    } else if (event is ClearItems) {
      items = [];
      yield SelectionState.result(items);
    }
  }

  void onClear() => add(ClearItems());

  void onToggleItem(int id) => add(ToggleItem(id));

  @override
  void onTransition(Transition<SelectionEvent, SelectionState> transition) {
    _log.fine('Transition from ${transition.currentState} to ${transition.nextState}');
    super.onTransition(transition);
  }
}

abstract class SelectionEvent {}

class SelectionState {
  final List<int> items;

  SelectionState(this.items);

  factory SelectionState.empty() => SelectionState([]);

  factory SelectionState.result(List<int> items) => SelectionState(items);

  @override
  String toString() => '[CameraState: $items]';
}

class ToggleItem extends SelectionEvent {
  final int id;

  ToggleItem(this.id);

  @override
  String toString() => '[ToggleItem: $id]';
}
