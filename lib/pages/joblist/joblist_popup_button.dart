import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum PopupMenuEntry {
  deleteAll,
  printAll,
}

class JoblistPopupButton extends StatefulWidget {
  @override
  _JoblistPopupButtonState createState() => _JoblistPopupButtonState();
}

class _JoblistPopupButtonState extends State<JoblistPopupButton> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      onSelected: _onPopupButtonSelected,
      icon: Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
            child: Row(children: [Icon(Icons.delete), Text(' Alle Jobs löschen')]),
            value: PopupMenuEntry.deleteAll),
        PopupMenuItem(
            child: Row(children: [Icon(Icons.print), Text(' Alle Jobs drucken')]),
            value: PopupMenuEntry.printAll),
      ],
    );
  }

  void _onPopupButtonSelected(PopupMenuEntry value) {
    switch (value) {
      case PopupMenuEntry.printAll:
        _onPrintAll();
        break;
      case PopupMenuEntry.deleteAll:
        _onDeleteAll();
        break;
      default:
        break;
    }
  }

  void _onPrintAll() async {
    String barcode = '';
    try {
      barcode = await BarcodeScanner.scan();
    } catch (e) {
      print(e);
    }

    bool dialogPositive = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Wirklich alle Jobs drucken?'),
        content: Text(
            'Es werden alle Dokumente in der Reihenfolge unten an den Drucker ($barcode) gesendet.\nJobs die nicht geherzt wurden sind danach weg.'),
        actions: <Widget>[
          MaterialButton(
            child: Text('Ja'),
            onPressed: () {
              dialogPositive = true;
              Navigator.of(context).pop();
            },
          ),
          MaterialButton(
            child: Text('Abbrechen'),
            onPressed: () {
              dialogPositive = false;
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );

    if (dialogPositive)
      for (Job job in BlocProvider.of<JoblistBloc>(context).state.value) {
        BlocProvider.of<JoblistBloc>(context).onPrintById(barcode, job.id);
      }
  }

  void _onDeleteAll() async {
    bool dialogPositive = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Wirklich alle Jobs löschen?'),
        content: Text(
            'Die Dokumente sind danach für immer gelöscht und können nicht wiederhergestellt werden'),
        actions: <Widget>[
          MaterialButton(
            child: Text('Ja'),
            onPressed: () {
              dialogPositive = true;
              Navigator.of(context).pop();
            },
          ),
          MaterialButton(
            child: Text('Abbrechen'),
            onPressed: () {
              dialogPositive = false;
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );

    if (dialogPositive) BlocProvider.of<JoblistBloc>(context).onDeleteAll();
  }
}
