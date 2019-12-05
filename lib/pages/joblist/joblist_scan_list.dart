import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/print_queue.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'joblist_tile.dart';

class JoblistScanList extends StatefulWidget {
  final bool copyMode;

  JoblistScanList({this.copyMode = false});

  @override
  _JoblistScanListState createState() => _JoblistScanListState();
}

class _JoblistScanListState extends State<JoblistScanList> {
  List<Job> _jobs = [];
  List<int> _startIds;

  String _device = '';

  Timer _heartbeatTimer;

  StreamSubscription<PrintQueueState> _printQueueListener;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JoblistBloc, JoblistState>(
      builder: (BuildContext context, JoblistState state) {
        if (state.isResult || state.isBusy) {
          if (state.isResult) {
            _jobs = state.value;
            _jobs.removeWhere((Job job) => _startIds.contains(job.id));
          }
          if (_jobs.length > 0) {
            return Column(children: <Widget>[
              ListTile(
                title: Text('Scans', textScaleFactor: 1.5),
                subtitle: Text('${_jobs.length} Scans in der Liste'),
                trailing: BlocBuilder<PrintQueueBloc, PrintQueueState>(
                    builder: (BuildContext context, PrintQueueState state) {
                  if (state.isResult || state.isLocked) {
                    return Icon(
                      Icons.fiber_manual_record,
                      color: (state.value.processing.isNotEmpty) ? Colors.green : Colors.grey,
                    );
                  }
                  return Container(width: 0, height: 0);
                }),
              ),
              Divider(indent: 16.0, endIndent: 16.0, height: 0.0),
              for (int i = _jobs.length - 1; i >= 0; i--)
                JoblistTile(
                  context,
                  i,
                  _jobs[i],
                  onPress: () => null,
                  onPressPrint: () => null,
                ),
            ]);
          } else if (state.isResult) {
            return ListTile(
              title: Text(
                  'Es sind noch keine Scans in dieser Liste. Wähle von der Startseite des Druckers "Scanner" und dort das Ziel "scan2asta" um Dokumente in diese Liste zu senden.\n\nDein ausgewählter Drucker hat die Stellplatznummer $_device'),
            );
          }
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  void dispose() {
    _printQueueListener.cancel();

    if (_heartbeatTimer != null) _heartbeatTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    _startIds = BlocProvider.of<JoblistBloc>(context).state.value.map((Job job) => job.id).toList();

    _printQueueListener = BlocProvider.of<PrintQueueBloc>(context).listen((PrintQueueState state) {
      if (state.isLocked) {
        _heartbeatTimer = Timer.periodic(
            const Duration(seconds: 50), BlocProvider.of<PrintQueueBloc>(context).onLockDevice());
      } else if (state.isException) {
        final int status = (state.error as ApiException).statusCode;
        String message;
        switch (status) {
          case 404:
            message = 'Dieser Drucker konnte nicht im System gefunden werden';
            break;
          case 400:
            message = 'Problem bei der Anfrage an die Druckerwarteschlange';
            break;
          case 401:
            BlocProvider.of<AuthBloc>(context).onLogout();
            break;
          default:
            message = 'Unbekanntes Problem bei der Druckerwarteschlange aufgetreten';
        }
        Scaffold.of(context).showSnackBar(
            SnackBar(duration: Duration(seconds: 3), content: Text('$message ($status)')));
      }
    });

    _initDevice();

    super.initState();
  }

  void _initDevice() async {
    try {
      _device = await BarcodeScanner.scan();
      setState(() => _device);
    } catch (e) {
      print(e);
    }

    BlocProvider.of<PrintQueueBloc>(context)
      ..setDeviceId(int.tryParse(_device))
      ..onLockDevice();
  }
}
