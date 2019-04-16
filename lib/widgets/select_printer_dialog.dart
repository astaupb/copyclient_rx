import 'package:flutter/material.dart'
    show
        BuildContext,
        Column,
        Dialog,
        EdgeInsets,
        InputBorder,
        InputDecoration,
        MainAxisSize,
        Navigator,
        Padding,
        Text,
        TextField,
        TextInputType,
        Widget;

Dialog selectPrinterDialog(BuildContext context) {
  String input;
  return Dialog(
    child: Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Drucker manuell eingeben', textScaleFactor: 1.3),
          TextField(
            onChanged: (String val) => input = val,
            onEditingComplete: () => Navigator.pop<String>(context, input),
            decoration: InputDecoration(
                border: InputBorder.none, hintText: 'z.B. 44332'),
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.numberWithOptions(),
          ),
        ],
      ),
    ),
  );
}
