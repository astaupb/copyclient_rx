import 'dart:async';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'joblist_tile.dart';

class JoblistScanList extends StatefulWidget {
  @override
  _JoblistScanListState createState() => _JoblistScanListState();
}

class _JoblistScanListState extends State<JoblistScanList> {
  List<Job> _jobs = [];
  List<int> _startIds;

  StreamSubscription _uploadListener;
  Timer _uploadTimer;
  int lastUploads = 0;

  @override
  void initState() {
    _startIds = BlocProvider.of<JoblistBloc>(context).state.value.map((Job job) => job.id).toList();

    _uploadListener = BlocProvider.of<UploadBloc>(context).listen((UploadState state) {
      if (state.isResult) {
        if (state.value.length < lastUploads) BlocProvider.of<JoblistBloc>(context).onRefresh();
        lastUploads = state.value.length;
      }
    });

    _uploadTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      BlocProvider.of<UploadBloc>(context).onRefresh();
    });
    
    super.initState();
  }

  @override
  void dispose() {
    _uploadTimer.cancel();
    _uploadListener.cancel();
    super.dispose();
  }

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
                  'Es sind noch keine Scans in dieser Liste. Wähle von der Startseite des Druckers "Scanner" und dort das Ziel "scan2asta" um Dokumente in diese Liste zu senden.'),
            );
          }
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
