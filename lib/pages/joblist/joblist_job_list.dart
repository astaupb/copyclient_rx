import 'dart:async';

import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:copyclient_rx/blocs/camera_bloc.dart';
import 'package:copyclient_rx/blocs/selection_bloc.dart';
import 'package:copyclient_rx/pages/jobdetails/jobdetails.dart';
import 'package:copyclient_rx/pages/joblist/joblist_credit_text.dart';
import 'package:copyclient_rx/pages/joblist/joblist_qr_code.dart';
import 'package:copyclient_rx/widgets/select_printer_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'joblist_slidable.dart';
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
                  trailing: CreditText(),
                ),
                Divider(indent: 16.0, endIndent: 16.0, height: 0.0),
                for (int i = _jobs.length - 1; i >= 0; i--)
                  BlocBuilder<SelectionBloc, SelectionState>(
                    builder: (BuildContext context, SelectionState state) => JoblistSlidable(
                      job: _jobs[i],
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
                                  padding: EdgeInsets.fromLTRB(8.0, 8.0, 24.0, 0.0),
                                  child: Icon((state.items.contains(_jobs[i].id))
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank))
                              : (!kIsWeb)
                                  ? MaterialButton(
                                      color: Colors.teal[800],
                                      child: Icon(
                                        Icons.print,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => _onPressedPrint(_jobs[i].id),
                                    )
                                  : null,
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
      BlocProvider.of<UserBloc>(context).onRefresh();
    });

    _joblistListener = BlocProvider.of<JoblistBloc>(context).listen((JoblistState state) async {
      if (state.isException) {
        final status = (state.error as ApiException).statusCode;
        String message;
        var showMessage = true;
        switch (status) {
          case 401:
            BlocProvider.of<AuthBloc>(context).onLogout();
            break;
          case 404:
            Navigator.of(context).popUntil((Route route) => route.settings.name == '/');
            message = 'Dieser Job oder Drucker existiert nicht';
            break;
          case 423:
            message = 'Der ausgewählte Drucker ist gerade von einem anderen Nutzer reserviert.';
            break;
          case 502:
            message =
                'Der AStAPrint Dienst ist gerade nicht aktiv. Das könnte an einem geplanten Neustart liegen.';
            showMessage = false;
            break;
          default:
            message = 'Ein unbekannter Fehler ist auf der Jobliste aufgetreten';
        }
        if (showMessage) {
          Scaffold.of(context).showSnackBar(
              SnackBar(duration: Duration(seconds: 3), content: Text('$message ($status)')));
        }
        await Future<dynamic>.delayed(Duration(seconds: 1));
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
      Navigator.of(context).push<JobdetailsPage>(
        MaterialPageRoute(builder: (BuildContext context) => JobdetailsPage(job)),
      );
    }
  }

  void _onPressedPrint(int id) async {
    String device;
    if (BlocProvider.of<CameraBloc>(context).state.cameraDisabled) {
      device = await showDialog<String>(
              context: context, builder: (BuildContext context) => selectPrinterDialog(context)) ??
          '';
    } else {
      device = (await getDeviceId(context)).toString();
      print('devicelool: $device');
    }

    if (device != null) {
      BlocProvider.of<JoblistBloc>(context).onPrintById(device, id);

      await Future<dynamic>.delayed(const Duration(seconds: 10)).then<void>((dynamic _) {
        BlocProvider.of<UserBloc>(context).onRefresh();
        BlocProvider.of<JoblistBloc>(context).onRefresh();
      });
    }
  }
}
