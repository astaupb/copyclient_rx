import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';

class JoblistTile extends ListTile {
  static const double height = 80.0;
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
      EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 4.0);

  @override
  Widget get leading => Container(
        width: 0.0,
        height: 0.0,
      );

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
        width: 60.0,
        child: Column(
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
      );
}
