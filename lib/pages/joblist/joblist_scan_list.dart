import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
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

  StreamSubscription _uploadListener;
  Timer _uploadTimer;
  int _lastUploads = 0;

  String _device = '';

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
    _uploadTimer.cancel();
    _uploadListener.cancel();
    super.dispose();
  }

  @override
  void initState() {
    _startIds = BlocProvider.of<JoblistBloc>(context).state.value.map((Job job) => job.id).toList();

    _initDevice();

    _uploadListener = BlocProvider.of<UploadBloc>(context).listen((UploadState state) {
      if (state.isResult) {
        if (state.value.length < _lastUploads) BlocProvider.of<JoblistBloc>(context).onRefresh();
        _lastUploads = state.value.length;
      }
    });

    _uploadTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      BlocProvider.of<UploadBloc>(context).onRefresh();
    });

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
