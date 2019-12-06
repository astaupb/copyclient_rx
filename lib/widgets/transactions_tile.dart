import 'package:blocs_copyclient/journal.dart';
import 'package:flutter/material.dart';

class TransactionsTile extends ListTile {
  final Transaction transaction;

  TransactionsTile(this.transaction);

  @override
  bool get dense => true;

  @override
  Widget get leading => (transaction.value < 0) ? Icon(Icons.remove) : Icon(Icons.add);

  @override
  Function() get onTap => () => null;

  @override
  Widget get subtitle => Text(transaction.timestamp);

  @override
  Widget get title => Text(transaction.description);

  @override
  Widget get trailing => Container(
        width: 100.0,
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${(transaction.value / 100.0).toStringAsFixed(2)} €',
                  textScaleFactor: 1.3,
                  style: (transaction.value < 0)
                      ? TextStyle(color: Colors.red)
                      : TextStyle(color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      );
}
