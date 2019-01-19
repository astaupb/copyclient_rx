import 'dart:io';

import 'package:flutter/material.dart';

class ExitAppAlert extends StatelessWidget {
  const ExitAppAlert({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
          title: Text('Bist du sicher?'),
          content:
              Text('Willst du den AStA Copyclient wirklich beenden?'),
          actions: <Widget>[
            FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Nein'),
            ),
            FlatButton(
              onPressed: () => exit(0),
              child: Text('Ja'),
            ),
          ],
        );
  }
}
