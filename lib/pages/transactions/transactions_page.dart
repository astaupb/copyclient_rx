import 'dart:async';
import 'dart:io';

import 'package:blocs_copyclient/journal.dart';
import 'package:blocs_copyclient/pdf_creation.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../widgets/centered_text.dart';
import '../../widgets/transactions_tile.dart';

class TransactionsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const MethodChannel _mChannel =
      MethodChannel('de.upb.copyclient/download_path');
  JournalBloc journalBloc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaktionen'),
        actions: <Widget>[
          Builder(
              builder: (BuildContext context) => IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () => (Platform.isIOS)
                        ? _onExportJournal(context, true)
                        : _onShowShare(context),
                    tooltip: 'Transaktionen als PDF exportieren',
                  )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(),
        child: BlocBuilder<JournalEvent, JournalState>(
          bloc: BlocProvider.of<JournalBloc>(context),
          builder: (BuildContext context, JournalState state) {
            if (state.isResult) {
              return ListView.builder(
                itemCount: state.value.transactions.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Column(
                      children: <Widget>[
                        ListTile(
                          title: Text(
                            'Aktuelles Guthaben:',
                            textScaleFactor: 1.1,
                          ),
                          trailing: Text(
                            '${(state.value.credit / 100.0).toStringAsFixed(2)} €',
                            textScaleFactor: 1.3,
                          ),
                        ),
                      ],
                    );
                  }
                  return Container(
                    color: (index % 2 == 1) ? Colors.black12 : null,
                    child:
                        TransactionsTile(state.value.transactions[index - 1]),
                  );
                },
              );
            } else if (state.isException) {
              return ListView(
                children: <Widget>[CenteredText(state.error.toString())],
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    journalBloc = BlocProvider.of<JournalBloc>(context);
    super.initState();
  }

  void _onExportJournal(BuildContext context, bool share) {
    const SnackBar doneSnack = SnackBar(
      duration: Duration(seconds: 1),
      content: Text('PDF unter Downloads gespeichert'),
    );

    if (journalBloc.currentState.isResult) {
      PdfCreationBloc pdfCreation = PdfCreationBloc();

      StreamSubscription pdfListener;

      pdfListener = pdfCreation.state.listen((PdfCreationState state) async {
        if (state.isResult) {
          if (!share) {
            await PermissionHandler()
                .shouldShowRequestPermissionRationale(PermissionGroup.storage);
            await PermissionHandler()
                .requestPermissions([PermissionGroup.storage]);

            String downloadPath;
            try {
              downloadPath =
                  await _mChannel.invokeMethod('getDownloadsDirectory');
            } catch (e) {
              print(e.toString());
            }
            final String _basePath =
                (await Directory(downloadPath).create()).path;
            await File(
                    '$_basePath/transaktionen_${DateTime.now().toIso8601String()}.pdf')
                .writeAsBytes(state.value, flush: true);

            Scaffold.of(context).showSnackBar(doneSnack);
          } else {
            await Share.file(
                'Transaktionen vom ${DateTime.now().toIso8601String()}',
                'transaktionen_${DateTime.now().toIso8601String()}.pdf',
                state.value,
                'application/pdf');
          }
          pdfListener.cancel();
          pdfCreation.dispose();
        }
      });

      pdfCreation.onCreateFromCsv(journalBloc.csvJournal,
          showPageCount: true,
          header:
              'AStA Copyservice Druckvolumen und Aufladungen für "${BlocProvider.of<UserBloc>(context).currentState.value.name}" seit ${journalBloc.currentState.value.transactions.last.timestamp}',
          titles: ['Betrag in Euro', 'Beschreibung', 'Zeit']);
    }
  }

  Future<void> _onRefresh() async {
    var listener;
    listener = journalBloc.state.listen((JournalState state) {
      if (state.isResult) {
        listener.cancel();
        return;
      }
    });
    journalBloc.dispatch(RefreshJournal());
  }

  void _onShowShare(BuildContext scaffoldContext) async {
    await showModalBottomSheet(
      context: scaffoldContext,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              if (!Platform.isIOS)
                RaisedButton(
                  child: Row(children: <Widget>[
                    Icon(Icons.file_download),
                    Text('Als PDF speichern'),
                  ]),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    _onExportJournal(scaffoldContext, false);
                  },
                ),
              RaisedButton(
                child: Row(children: <Widget>[
                  Icon(Icons.share),
                  Text('PDF Teilen'),
                ]),
                onPressed: () => _onExportJournal(context, true),
              ),
            ],
          ),
        );
      },
    );
  }
}
