import 'package:flutter/material.dart';

class TealOutlineButton extends OutlineButton {
  final Widget _child;
  final _onPressed;

  TealOutlineButton({@required Widget child, @required onPressed})
      : _child = child,
        _onPressed = onPressed;

  @override
  BorderSide get borderSide => BorderSide(color: Colors.teal[800]);

  @override
  Color get highlightedBorderColor => Colors.teal[700];

  @override
  Color get textColor => Colors.grey[850];

  @override
  Color get color => Colors.white70;

  @override
  Widget get child => _child;

  @override
  get onPressed => _onPressed;
}
