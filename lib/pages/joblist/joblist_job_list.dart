import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:copyclient_rx/blocs/selection_bloc.dart';
import 'package:copyclient_rx/pages/jobdetails/jobdetails.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'joblist_tile.dart';

class JoblistJobList extends StatefulWidget {
  @override
  _JoblistJobListState createState() => _JoblistJobListState();
}

class _JoblistJobListState extends State<JoblistJobList> {
  List<Job> _jobs = [];

  StreamSubscription<JoblistState> _joblistListener;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JoblistBloc, JoblistState>(
      builder: (BuildContext context, JoblistState state) {
        if (state.isResult || state.isBusy) {
          if (state.isResult) {
            _jobs = state.value;
          }
          if (_jobs.length > 0) {
            return Column(
              children: <Widget>[
                ListTile(
                  title: Text('Jobs', textScaleFactor: 1.5),
                  subtitle: Text('${_jobs.length} Jobs in der Liste'),
                ),
                Divider(indent: 16.0, endIndent: 16.0, height: 0.0),
                for (int i = _jobs.length - 1; i >= 0; i--)
                  BlocBuilder<SelectionBloc, SelectionState>(
                    builder: (BuildContext context, SelectionState state) => Container(
                      decoration: BoxDecoration(
                        color: state.items.contains(_jobs[i].id) ? Colors.black12 : null,
                      ),
                      child: JoblistTile(
                        context,
                        i,
                        _jobs[i],
                        onPress: () => _onPressed(_jobs[i]),
                        onLongTap: () =>
                            BlocProvider.of<SelectionBloc>(context).onToggleItem(_jobs[i].id),
                        chosen: state.items.contains(_jobs[i].id),
                        leader: (state.items.length > 0)
                            ? Padding(
                                padding: EdgeInsets.fromLTRB(8.0, 8.0, 0.0, 0.0),
                                child: Icon((state.items.contains(_jobs[i].id))
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank))
                            : MaterialButton(
                                color: Colors.teal[800],
                                child: Icon(
                                  Icons.print,
                                  color: Colors.white,
                                ),
                                onPressed: () => _onPressedPrint(_jobs[i].id),
                              ),
                      ),
                    ),
                  ),
              ],
            );
          } else if (state.isResult) {
            return ListTile(
              title: Text(
                  'Die Jobliste ist gerade leer, füge mit dem Button unten rechts Dokumente hinzu oder teile sie aus einer anderen App'),
            );
          }
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  void dispose() {
    _joblistListener.cancel();
    super.dispose();
  }

  @override
  void initState() {
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

    BlocProvider.of<JoblistBloc>(context).onRefresh();
    super.initState();
  }

  void _onPressed(Job job) {
    if (BlocProvider.of<SelectionBloc>(context).items.isNotEmpty) {
      BlocProvider.of<SelectionBloc>(context).onToggleItem(job.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (BuildContext context) => JobdetailsPage(job)),
      );
    }
  }

  void _onPressedPrint(int id) async {
    String barcode = await BarcodeScanner.scan();
    BlocProvider.of<JoblistBloc>(context).onPrintById(barcode, id);
  }
}
