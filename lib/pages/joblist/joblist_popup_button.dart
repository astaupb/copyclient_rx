import 'package:blocs_copyclient/joblist.dart';
import 'package:copyclient_rx/blocs/camera_bloc.dart';
import 'package:copyclient_rx/blocs/theme_bloc.dart';
import 'package:copyclient_rx/widgets/select_printer_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'joblist_qr_code.dart';

class JoblistPopupButton extends StatefulWidget {
  @override
  _JoblistPopupButtonState createState() => _JoblistPopupButtonState();
}

enum PopupMenuEntry {
  deleteAll,
  printAll,
}

class _JoblistPopupButtonState extends State<JoblistPopupButton> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      onSelected: _onPopupButtonSelected,
      icon: Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: PopupMenuEntry.deleteAll,
          child: Row(children: [
            Icon(
              Icons.delete,
              color: (BlocProvider.of<ThemeBloc>(context).state.id == CopyclientTheme.copyshop)
                  ? Colors.grey[800]
                  : null,
            ),
            Text(' Alle Jobs löschen')
          ]),
        ),
        if (!kIsWeb)
          PopupMenuItem(
            value: PopupMenuEntry.printAll,
            child: Row(children: [
              Icon(
                Icons.print,
                color: (BlocProvider.of<ThemeBloc>(context).state.id == CopyclientTheme.copyshop)
                    ? Colors.grey[800]
                    : null,
              ),
              Text(' Alle Jobs drucken')
            ]),
          ),
      ],
    );
  }

  void _onDeleteAll() async {
    var dialogPositive = false;

    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Wirklich alle Jobs löschen?'),
        content: Text(
            'Die Dokumente sind danach für immer gelöscht und können nicht wiederhergestellt werden'),
        actions: <Widget>[
          MaterialButton(
            color: Colors.teal[800],
            onPressed: () {
              dialogPositive = true;
              Navigator.of(context).pop();
            },
            child: Text('Ja'),
          ),
          MaterialButton(
            color: Colors.teal[800],
            onPressed: () {
              dialogPositive = false;
              Navigator.of(context).pop();
            },
            child: Text('Abbrechen'),
          )
        ],
      ),
    );

    if (dialogPositive) BlocProvider.of<JoblistBloc>(context).onDeleteAll();
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
    String barcode;
    if (BlocProvider.of<CameraBloc>(context).state.cameraDisabled) {
      barcode = await showDialog<String>(
          context: context, builder: (BuildContext context) => selectPrinterDialog(context));
    } else {
      barcode = (await getDeviceId(context)).toString();
    }

    var dialogPositive = false;

    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Wirklich alle Jobs drucken?'),
        content: Text(
            'Es werden alle Dokumente in der Reihenfolge unten an den Drucker ($barcode) gesendet.\nJobs die nicht geherzt wurden sind danach weg.'),
        actions: <Widget>[
          MaterialButton(
            color: Colors.teal[800],
            onPressed: () {
              dialogPositive = true;
              Navigator.of(context).pop();
            },
            child: Text('Ja'),
          ),
          MaterialButton(
            color: Colors.teal[800],
            onPressed: () {
              dialogPositive = false;
              Navigator.of(context).pop();
            },
            child: Text('Abbrechen'),
          )
        ],
      ),
    );

    if (dialogPositive) {
      for (var job in BlocProvider.of<JoblistBloc>(context).state.value) {
        BlocProvider.of<JoblistBloc>(context).onPrintById(barcode, job.id);
      }
    }
  }
}
