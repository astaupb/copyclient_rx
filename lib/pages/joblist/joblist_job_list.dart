import 'package:barcode_scan/barcode_scan.dart';
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

  @override
  void initState() {
    BlocProvider.of<JoblistBloc>(context).onRefresh();
    super.initState();
  }

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
                        onPressPrint: () => _onPressedPrint(_jobs[i].id),
                        onLongTap: () =>
                            BlocProvider.of<SelectionBloc>(context).onToggleItem(_jobs[i].id),
                        chosen: state.items.contains(_jobs[i].id),
                        leader: (state.items.length > 0)
                            ? Padding(
                                padding: EdgeInsets.fromLTRB(8.0, 8.0, 0.0, 0.0),
                                child: Icon((state.items.contains(_jobs[i].id))
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank))
                            : null,
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
