import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/print_queue.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:copyclient_rx/pages/jobdetails/jobdetails.dart';
import 'package:copyclient_rx/pages/joblist/joblist_mode_bloc.dart';
import 'package:copyclient_rx/pages/joblist/joblist_refreshing_bloc.dart';
import 'package:copyclient_rx/pages/joblist/joblist_scan_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<int> _copiedIds;

  String _device = '';
  bool _deviceSelected = false;

  StreamSubscription<PrintQueueState> _printQueueListener;
  StreamSubscription<ScanState> _scanListener;
  StreamSubscription<JoblistState> _joblistListener;

  _JoblistScanListState() {
    _copiedIds = [];
  }

  @override
  Widget build(BuildContext context) {
    if (_deviceSelected) {
      return BlocBuilder<JoblistBloc, JoblistState>(
        builder: (BuildContext context, JoblistState state) {
          if (state.isResult || state.isBusy) {
            if (state.isResult) {
              _jobs = state.value;
              _jobs.removeWhere((Job job) => _startIds.contains(job.id));
              if (widget.copyMode) {
                for (var job in _jobs) {
                  if (!_copiedIds.contains(job.id)) {
                    BlocProvider.of<JoblistBloc>(context).onPrintById(_device, job.id);
                    _copiedIds.add(job.id);
                  }
                }
              } else {
                for (var job in _jobs) {
                  if (!_copiedIds.contains(job.id)) _copiedIds.add(job.id);
                }
              }
            }
            if (_jobs.isNotEmpty) {
              return Column(children: <Widget>[
                ListTile(
                  title: Text(widget.copyMode ? 'Kopien' : 'Scans', textScaleFactor: 1.7),
                  subtitle:
                      Text('${_jobs.length} ${widget.copyMode ? 'Kopien' : 'Scans'} in der Liste'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (widget.copyMode)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text('Guthaben'),
                            BlocBuilder<UserBloc, UserState>(
                              builder: (BuildContext context, UserState state) {
                                if (state.isResult) {
                                  return Text('${(state.value.credit / 100.0).toStringAsFixed(2)}€',
                                      textScaleFactor: 1.5);
                                } else {
                                  return Container(width: 0.0, height: 0.0);
                                }
                              },
                            ),
                          ],
                        ),
                      BlocBuilder<PrintQueueBloc, PrintQueueState>(
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
                    ],
                  ),
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
                      Navigator.of(context).push<JobdetailsPage>(MaterialPageRoute(
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
    } else {
      return Container(width: 0.0, height: 0.0);
    }
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

    _startIds =
        (BlocProvider.of<JoblistBloc>(context).state.value ?? []).map((Job job) => job.id).toList();

    _scanListener = _scanBloc.listen((ScanState state) {
      if (state.isBeating && state.shouldBeat) {
        BlocProvider.of<PrintQueueBloc>(context).onLockDevice();
      }
    });

    _joblistListener = BlocProvider.of<JoblistBloc>(context).listen((JoblistState state) {
      if (state.isException) {
        final status = (state.error as ApiException).statusCode;
        String message;
        var showError = true;
        switch (status) {
          case 401:
            BlocProvider.of<AuthBloc>(context).onLogout();
            break;
          case 404:
            Navigator.of(context).popUntil((Route route) => route.settings.name == '/');
            message = 'Dieser Job war nie da oder ist nicht mehr da.';
            break;
          case 423:
            BlocProvider.of<JoblistModeBloc>(context).onSwitch(JoblistMode.print);
            message = 'Der ausgewählte Drucker ist gerade von einem anderen Nutzer reserviert.';
            break;
          case 424:
            showError = false;
            break;
          case 403:
            showError = false;
            break;
          default:
            message = 'Ein unbekannter Fehler ist auf der Jobliste aufgetreten.';
        }
        if (showError) {
          Scaffold.of(context).showSnackBar(
              SnackBar(duration: Duration(seconds: 3), content: Text('$message ($status)')));
        }
        BlocProvider.of<JoblistBloc>(context).onRefresh();
      }
    });

    _printQueueListener = BlocProvider.of<PrintQueueBloc>(context).listen((PrintQueueState state) {
      if (state.isException) {
        final status = (state.error as ApiException).statusCode;
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
          case 423:
            BlocProvider.of<JoblistModeBloc>(context).onSwitch(JoblistMode.print);
            message = 'Der ausgewählte Drucker ist gerade von einem anderen Nutzer reserviert.';
            break;
          default:
            message = 'Unbekanntes Problem bei der Druckerwarteschlange aufgetreten';
        }
        Scaffold.of(context).showSnackBar(
            SnackBar(duration: Duration(seconds: 3), content: Text('$message ($status)')));
      }
    });

    _initDevice(context);

    super.initState();
  }

  void _initDevice(BuildContext context) async {
    try {
      _device = await BarcodeScanner.scan();
      setState(() => _deviceSelected = true);

      int deviceId;

      if (_device != '' && !(_device.length > 5)) deviceId = int.tryParse(_device);

      if (deviceId != null) {
        BlocProvider.of<PrintQueueBloc>(context)
          ..setDeviceId(int.tryParse(_device))
          ..onLockDevice();

        _scanBloc.onStart();
      } else {
        BlocProvider.of<JoblistModeBloc>(context).onSwitch(JoblistMode.print);
        Scaffold.of(context).showSnackBar(SnackBar(
            duration: Duration(seconds: 5),
            content: Text(
                'Es wurde kein gültiger QR-Code gescannt. Bitte nutze die QR Codes auf den Displays der Drucker.')));
      }
    } catch (e) {
      print('exception while scanning barcode: $e');
      BlocProvider.of<JoblistModeBloc>(context).onSwitch(JoblistMode.print);
      if (e is PlatformException) {
        print('PlatformException: ${e.code} ${e.details} ${e.message}');
        if (e.code == 'PERMISSION_NOT_GRANTED') {
          Scaffold.of(context).showSnackBar(SnackBar(
              duration: Duration(seconds: 5),
              content: Text(
                  'Keine Berechtigung zum Nutzen der Kamera. Bitte erlaube dies in den Einstellungen um den Druck per QR-Code zu nutzen.')));
        }
      }
    }
  }

  void _onPressedPrint(int id) {
    if (_device != '') {
      BlocProvider.of<JoblistBloc>(context).onPrintById(_device, id);
    }
  }
}
