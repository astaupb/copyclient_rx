import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/camera_bloc.dart';
import '../../widgets/heart_pin.dart';
import '../../widgets/select_printer_dialog.dart';

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
        if (state.isResult) {
          _job = state.value.singleWhere((Job job) => job.id == _job.id);
          return Column(
            children: <Widget>[
              ListTile(
                title: TextField(
                  controller: TextEditingController(
                      text: (_job.jobOptions.displayName.isNotEmpty)
                          ? _job.jobOptions.displayName
                          : (_job.jobInfo.filename.isEmpty)
                              ? 'Ohne Titel'
                              : _job.jobInfo.filename),
                  style: TextStyle(fontSize: 20.0),
                  autocorrect: false,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                      isDense: true,
                      suffixIcon: Icon(Icons.edit),
                      border: InputBorder.none),
                  onSubmitted: (String value) {
                    if (_job.jobOptions.displayName != value) {
                      _job.jobOptions.displayName = value;
                      BlocProvider.of<JoblistBloc>(context)
                          .onUpdateOptionsById(_job.id, _job.jobOptions);
                    }
                  },
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(DateTime.fromMillisecondsSinceEpoch(
                            _job.timestamp * 1000)
                        .toString()
                        .split('.')[0]),
                    (!Platform.isIOS)
                        ? BlocBuilder<PdfEvent, PdfState>(
                            bloc: BlocProvider.of<PdfBloc>(context),
                            builder: (BuildContext context, PdfState state) {
                              if (state.isResult || state.isInit) {
                                Iterable idResults = state.value.where(
                                    (PdfFile file) => file.id == _job.id);
                                return Text(
                                  (idResults.length == 1)
                                      ? 'Heruntergeladen'
                                      : 'Nicht heruntergeladen',
                                );
                              } else if (state.isBusy) {
                                return Text('Am Herunterladen...');
                              } else if (state.isException) {
                                return Text(
                                    'Fehler beim Download der PDF: ${state.error.toString()}');
                              }
                              return Text('');
                            },
                          )
                        : Container(width: 0.0, height: 0.0),
                  ],
                ),
                trailing: HeartPin(_job.id),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
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
                        onPressed: () async {
                          String target;
                          try {
                            if (BlocProvider.of<CameraBloc>(context)
                                .currentState
                                .cameraDisabled) {
                              target = await showDialog<String>(
                                context: context,
                                builder: (BuildContext context) =>
                                    selectPrinterDialog(context),
                              );
                            } else {
                              target = await BarcodeScanner.scan();
                            }
                            if (target != null) {
                              BlocProvider.of<JoblistBloc>(context)
                                  .onPrintById(target, _job.id);
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            print('MetaTile: $e');
                            Scaffold.of(context).showSnackBar(SnackBar(
                                content:
                                    Text('Es wurde kein Drucker ausgewählt')));
                          }
                        },
                      ),
                      BlocBuilder(
                        bloc: userBloc,
                        builder: (BuildContext context, UserState state) {
                          if (state.isResult) {
                            return Text(
                              ((userBloc.user.credit -
                                          (_job.priceEstimation / 100.0)) >
                                      0)
                                  ? 'Neues Guthaben vmtl.: ${((userBloc.user.credit - _job.priceEstimation) / 100.0).toStringAsFixed(2)} €'
                                  : 'Fehlendes Guthaben vmtl.: ${(((userBloc.user.credit - _job.priceEstimation) / 100.0) * -1).toStringAsFixed(2)} €',
                              textAlign: TextAlign.left,
                              style: TextStyle(color: Colors.black54),
                              textScaleFactor: 0.8,
                            );
                          }
                          return Container(width: 0.0, height: 0.0);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
