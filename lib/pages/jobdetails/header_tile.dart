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
  final Job _job;

  _HeaderTileState(this._job);

  @override
  Widget build(BuildContext context) {
    final UserBloc userBloc = BlocProvider.of<UserBloc>(context);
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
          trailing: HeartPin(_job),
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
                      '${(_estimatePrice(_job) / 100.0).toStringAsFixed(2)} €'),
                ),
                icon: Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Icon(Icons.print),
                ),
                onPressed: ((userBloc.user.credit -
                            (_estimatePrice(_job) / 100.0)) >
                        0)
                    ? () async {
                        String target;
                        try {
                          target = await BarcodeScanner.scan();
                          if (target != null) {
                            BlocProvider.of<JoblistBloc>(context)
                                .onPrintbyId(target, _job.id);
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          print('MetaTile: $e');
                          Scaffold.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('Es wurde kein Drucker ausgewählt')));
                        }
                      }
                    : null,
              ),
              Text(
                ((userBloc.user.credit - (_estimatePrice(_job) / 100.0)) > 0)
                    ? 'Neues Guthaben vmtl.: ${(userBloc.user.credit - (_estimatePrice(_job) / 100.0)).toStringAsFixed(2)} €'
                    : 'Fehlendes Guthaben: ${((userBloc.user.credit - (_estimatePrice(_job) / 100.0)) * -1).toStringAsFixed(2)} €',
                textAlign: TextAlign.left,
                style: TextStyle(color: Colors.black54),
                textScaleFactor: 0.8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _estimatePrice(Job job, {basePrice: 2}) {
    int _basePrice = basePrice;
    int _colorPrice = 10;
    int _colorPages = job.jobInfo.colored;
    int _totalPages = job.jobInfo.pagecount;

    if (job.jobOptions.a3 || job.jobInfo.a3) {
      _basePrice *= 2;
      _colorPrice *= 2;
    }

    if (job.jobOptions.nup == 4 && _totalPages > 3) {
      _totalPages = _totalPages ~/ 4 + ((_totalPages % 4 > 0) ? 1 : 0);
    } else if (job.jobOptions.nup == 4 && _totalPages <= 4) {
      _totalPages = 1;
    }

    if (job.jobOptions.nup == 2 && _totalPages > 1)
      _totalPages = _totalPages ~/ 2 + _totalPages % 2;

    _basePrice *= ((_totalPages - _colorPages) * job.jobOptions.copies);
    if (_colorPages > 0 && job.jobOptions.color)
      _basePrice += (_colorPages * job.jobOptions.copies * _colorPrice);

    return _basePrice;
  }
}
