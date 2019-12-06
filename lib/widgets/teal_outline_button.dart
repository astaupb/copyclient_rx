import 'package:flutter/material.dart';

class TealOutlineButton extends OutlineButton {
  @override
  final Widget child;

  @override
  final onPressed;

  TealOutlineButton({@required this.child, @required this.onPressed});

  @override
  BorderSide get borderSide => BorderSide(color: Colors.teal[800]);

  @override
  Color get highlightedBorderColor => Colors.teal[700];

  @override
  Color get textColor => Colors.grey[850];

  @override
  Color get color => Colors.white70;
}
