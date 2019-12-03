import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';

class SelectionBloc extends Bloc<SelectionEvent, SelectionState> {
  Logger _log = Logger('SelectionBloc');

  List<int> items = [];

  void onToggleItem(int id) => this.add(ToggleItem(id));

  void onClear() => this.add(ClearItems());

  @override
  get initialState => SelectionState.empty();

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

  @override
  void onTransition(Transition transition) {
    _log.fine('Transition from ${transition.currentState} to ${transition.nextState}');
    super.onTransition(transition);
  }
}

abstract class SelectionEvent {}

class ClearItems extends SelectionEvent {}

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
