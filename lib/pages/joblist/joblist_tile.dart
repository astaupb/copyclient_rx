import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JoblistTile extends ListTile {
  static const double height = 64.0;
  final Job job;
  final int index;
  final BuildContext context;

  final onLongTap;
  final onPress;

  final bool chosen;

  JoblistTile(this.context, this.index, this.job,
      {this.onLongTap, this.onPress, this.chosen = false});

  @override
  EdgeInsetsGeometry get contentPadding =>
      EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0);

  @override
  Widget get leading => null;

  @override
  get onLongPress => () => onLongTap(index);

  @override
  get onTap => () => onPress(index);

  @override
  bool get selected => chosen;

  @override
  Widget get subtitle => new Text(
        '${DateTime.fromMillisecondsSinceEpoch(job.timestamp * 1000)}'
            .split('.')[0],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

  @override
  Widget get title => Text(
        job.jobInfo.filename,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

  @override
  Widget get trailing => Container(
        width: 112.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.color_lens,
                            color: (job.jobInfo.colored > 0)
                                ? Colors.teal[800]
                                : Colors.grey),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.photo_size_select_large,
                            color: (job.jobInfo.a3 || job.jobOptions.a3)
                                ? Colors.teal[800]
                                : Colors.grey),
                      ],
                    ),
                  ],
                ),
                Divider(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_none, color: Colors.black38, size: 19.0),
                    Text(
                      ' ${job.jobInfo.pagecount.toString()}',
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
            MaterialButton(
              color: Colors.teal[800],
              child: Icon(Icons.print, color: Colors.white,),
              onPressed: () async => BlocProvider.of<JoblistBloc>(context)
                  .onPrintById(await BarcodeScanner.scan(), job.id),
            ),
          ],
        ),
      );
}
