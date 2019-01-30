import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/heart_pin.dart';

///
/// [ListTile] on [JobdetailsPage] that displays the price and title of a job
/// A print button also makes the QR-Scanner availiable from that widget
///
class HeaderTile extends StatefulWidget {
  final Job job;

  const HeaderTile(this.job, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HeaderTileState(job);
}

class _HeaderTileState extends State<HeaderTile> {
  Job _job;

  _HeaderTileState(this._job);

  @override
  Widget build(BuildContext context) {
    final UserBloc userBloc = BlocProvider.of<UserBloc>(context);
    return BlocBuilder<JoblistEvent, JoblistState>(
      bloc: BlocProvider.of<JoblistBloc>(context),
      builder: (BuildContext context, JoblistState state) {
        if (state.isResult)
          _job = state.value.singleWhere((Job job) => job.id == _job.id);
        return Column(
          children: <Widget>[
            ListTile(
              title: Text(
                _job.jobInfo.filename,
                textScaleFactor: 1.3,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                  DateTime.fromMillisecondsSinceEpoch(_job.timestamp * 1000)
                      .toString()
                      .split('.')[0]),
              trailing: HeartPin(_job.id),
            ),
            ListTile(
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  RaisedButton.icon(
                    textColor: Colors.grey[100],
                    label: Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Text(
                          '${((_job.priceEstimation ?? 0) / 100.0).toStringAsFixed(2)} €'),
                    ),
                    icon: Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Icon(Icons.print),
                    ),
                    onPressed: ((userBloc.user.credit -
                                (_job.priceEstimation / 100.0)) >
                            0)
                        ? () async {
                            String target;
                            try {
                              target = await BarcodeScanner.scan();
                              if (target != null) {
                                BlocProvider.of<JoblistBloc>(context)
                                    .onPrintById(target, _job.id);
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              print('MetaTile: $e');
                              Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      'Es wurde kein Drucker ausgewählt')));
                            }
                          }
                        : null,
                  ),
                  Text(
                    ((userBloc.user.credit - (_job.priceEstimation / 100.0)) >
                            0)
                        ? 'Neues Guthaben vmtl.: ${((userBloc.user.credit - _job.priceEstimation) / 100.0).toStringAsFixed(2)} €'
                        : 'Fehlendes Guthaben: ${(((userBloc.user.credit - _job.priceEstimation) / 100.0) * -1).toStringAsFixed(2)} €',
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.black54),
                    textScaleFactor: 0.8,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
