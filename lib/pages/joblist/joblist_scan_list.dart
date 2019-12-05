import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/print_queue.dart';
import 'package:copyclient_rx/pages/jobdetails/jobdetails.dart';
import 'package:copyclient_rx/pages/joblist/joblist_mode_bloc.dart';
import 'package:copyclient_rx/pages/joblist/joblist_refreshing_bloc.dart';
import 'package:copyclient_rx/pages/joblist/joblist_scan_bloc.dart';
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
  ScanBloc _scanBloc;

  List<Job> _jobs = [];
  List<int> _startIds;
  List<int> _copiedIds = [];

  String _device = '';

  StreamSubscription<PrintQueueState> _printQueueListener;
  StreamSubscription<ScanState> _scanListener;
  StreamSubscription<JoblistState> _joblistListener;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JoblistBloc, JoblistState>(
      builder: (BuildContext context, JoblistState state) {
        if (state.isResult || state.isBusy) {
          if (state.isResult) {
            _jobs = state.value;
            _jobs.removeWhere((Job job) => _startIds.contains(job.id));
            if (widget.copyMode) {
              for (Job job in _jobs) {
                if (!_copiedIds.contains(job.id)) {
                  BlocProvider.of<JoblistBloc>(context).onPrintById(_device, job.id);
                  _copiedIds.add(job.id);
                }
              }
            }
          }
          if (_jobs.length > 0) {
            return Column(children: <Widget>[
              ListTile(
                title: Text(widget.copyMode ? 'Kopien' : 'Scans', textScaleFactor: 1.5),
                subtitle:
                    Text('${_jobs.length} ${widget.copyMode ? 'Kopien' : 'Scans'} in der Liste'),
                trailing: BlocBuilder<PrintQueueBloc, PrintQueueState>(
                    builder: (BuildContext context, PrintQueueState state) {
                  return GestureDetector(
                    child: Icon(
                      Icons.fiber_manual_record,
                      color: state.isLocked ? Colors.green : Colors.red,
                    ),
                    onDoubleTap: () => (state.isLocked)
                        ? BlocProvider.of<PrintQueueBloc>(context).onDelete()
                        : BlocProvider.of<PrintQueueBloc>(context).onLockDevice(),
                  );
                }),
              ),
              Divider(indent: 16.0, endIndent: 16.0, height: 0.0),
              for (int i = _jobs.length - 1; i >= 0; i--)
                JoblistTile(
                  context,
                  i,
                  _jobs[i],
                  onPress: () {
                    BlocProvider.of<RefreshingBloc>(context).onDisableForce();
                    BlocProvider.of<JoblistModeBloc>(context).onSwitch(JoblistMode.print);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) => JobdetailsPage(_jobs[i])));
                  },
                  leader: widget.copyMode
                      ? null
                      : MaterialButton(
                          onPressed: () => _onPressedPrint(_jobs[i].id),
                          color: Colors.teal[800],
                          child: Icon(
                            Icons.print,
                            color: Colors.white,
                          ),
                        ),
                ),
            ]);
          }
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(
                  'Es sind noch keine ${widget.copyMode ? 'Kopien' : 'Scans'} in dieser Liste.\n\nWähle von der Startseite des Druckers "Scanner" und dort das Ziel "scan2asta" um Dokumente in diese Liste zu senden.\n\nAusgewählter Drucker:'),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(height: 64.0),
                Icon(Icons.print, size: 64.0),
                Text(_device, textScaleFactor: 3.0),
              ],
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _printQueueListener.cancel();
    _scanListener.cancel();
    _joblistListener.cancel();

    _scanBloc
      ..onCancel()
      ..close();
    super.dispose();
  }

  @override
  void initState() {
    _scanBloc = ScanBloc();

    _startIds = (BlocProvider.of<JoblistBloc>(context).state.value ?? []).map((Job job) => job.id).toList();

    _scanListener = _scanBloc.listen((ScanState state) {
      if (state.isBeating && state.shouldBeat) {
        BlocProvider.of<PrintQueueBloc>(context).onLockDevice();
      }
    });

    _joblistListener = BlocProvider.of<JoblistBloc>(context).listen((JoblistState state) {
      if (state.isException) {
        final int status = (state.error as ApiException).statusCode;
        String message;
        switch (status) {
          case 401:
            BlocProvider.of<AuthBloc>(context).onLogout();
            break;
          case 404:
            Navigator.of(context).popUntil((Route route) => route.settings.name == '/');
            message = 'Dieser Job war nie da oder ist nicht mehr da.';
            break;
          default:
            message = 'Ein unbekannter Fehler ist auf der Jobliste aufgetreten';
        }
        Scaffold.of(context).showSnackBar(
            SnackBar(duration: Duration(seconds: 3), content: Text('$message ($status)')));
        BlocProvider.of<JoblistBloc>(context).onRefresh();
      }
    });

    _printQueueListener = BlocProvider.of<PrintQueueBloc>(context).listen((PrintQueueState state) {
      if (state.isException) {
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

    _scanBloc.onStart();
  }

  _onPressedPrint(int id) {}
}
