import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:copyclient_rx/blocs/selection_bloc.dart';
import 'package:copyclient_rx/pages/jobdetails/jobdetails.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'joblist_tile.dart';

class JoblistJobList extends StatefulWidget {
  @override
  _JoblistJobListState createState() => _JoblistJobListState();
}

class _JoblistJobListState extends State<JoblistJobList> {
  List<Job> _jobs = [];

  StreamSubscription<JoblistState> _joblistListener;

  Timer _refreshTimer;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JoblistBloc, JoblistState>(
      builder: (BuildContext context, JoblistState state) {
        if (state.isResult || state.isBusy) {
          if (state.isResult) {
            _jobs = state.value;
          }
          if (_jobs.isNotEmpty) {
            return Column(
              children: <Widget>[
                ListTile(
                  title: Text('Jobs', textScaleFactor: 1.7),
                  subtitle: Text('${_jobs.length} Jobs in der Liste'),
                  trailing: Column(
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
                ),
                Divider(indent: 16.0, endIndent: 16.0, height: 0.0),
                for (int i = _jobs.length - 1; i >= 0; i--)
                  BlocBuilder<SelectionBloc, SelectionState>(
                    builder: (BuildContext context, SelectionState state) => Slidable(
                      actionPane: SlidableDrawerActionPane(),
                      secondaryActions: <Widget>[
                        IconSlideAction(
                          caption: (_jobs[i].jobOptions.keep) ? 'Nicht behalten' : 'Behalten',
                          color: Color(0xffff58ad),
                          icon: (_jobs[i].jobOptions.keep) ? Icons.favorite_border : Icons.favorite,
                          onTap: () => _onKeepJob(_jobs[i].id, _jobs[i].jobOptions),
                        ),
                        IconSlideAction(
                          caption: 'Delete',
                          color: Colors.red,
                          icon: Icons.delete,
                          onTap: () => _onDeleteJob(_jobs[i].id),
                        ),
                      ],
                      child: Container(
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
                          leader: (state.items.isNotEmpty)
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
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (Timer t) {
      BlocProvider.of<JoblistBloc>(context).onRefresh();
      BlocProvider.of<UserBloc>(context).onRefresh();
      BlocProvider.of<UploadBloc>(context).onRefresh();
    });

    _joblistListener = BlocProvider.of<JoblistBloc>(context).listen((JoblistState state) {
      if (state.isException) {
        final status = (state.error as ApiException).statusCode;
        String message;
        switch (status) {
          case 401:
            BlocProvider.of<AuthBloc>(context).onLogout();
            break;
          case 404:
            Navigator.of(context).popUntil((Route route) => route.settings.name == '/');
            message = 'Dieser Job war nie da oder ist nicht mehr da.';
            break;
          case 423:
            message = 'Der ausgewählte Drucker ist gerade von einem anderen Nutzer reserviert.';
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

  void _onDeleteJob(int id) {
    BlocProvider.of<JoblistBloc>(context).onDeleteById(id);
  }

  void _onPressed(Job job) {
    if (BlocProvider.of<SelectionBloc>(context).items.isNotEmpty) {
      BlocProvider.of<SelectionBloc>(context).onToggleItem(job.id);
    } else {
      Navigator.of(context).push<JobdetailsPage>(
        MaterialPageRoute(builder: (BuildContext context) => JobdetailsPage(job)),
      );
    }
  }

  void _onPressedPrint(int id) async {
    String barcode;
    try {
      barcode = await BarcodeScanner.scan();
    } catch (e) {
      print('exception while scanning barcode: $e');
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

    if (barcode != null && barcode != '') {
      BlocProvider.of<JoblistBloc>(context).onPrintById(barcode, id);

      await Future<dynamic>.delayed(const Duration(seconds: 10)).then<void>((dynamic _) {
        BlocProvider.of<UserBloc>(context).onRefresh();
        BlocProvider.of<JoblistBloc>(context).onRefresh();
      });
    }
  }

  void _onKeepJob(int id, JobOptions jobOptions) {
    jobOptions.keep = !jobOptions.keep;
    BlocProvider.of<JoblistBloc>(context).onUpdateOptionsById(id, jobOptions);
  }
}
