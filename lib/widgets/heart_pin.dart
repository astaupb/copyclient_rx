import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';

class HeartPin extends StatefulWidget {
  final Job job;

  HeartPin(this.job);

  @override
  State<StatefulWidget> createState() => _HeartPinState(job);
}

class _HeartPinState extends State<HeartPin> {
  Job job;

  _HeartPinState(this.job);

  @override
  Widget build(BuildContext context) {
    if (job.jobOptions.keep) {
      return IconButton(
        color: Color(0xffff58ad),
        splashColor: Color(0xffff8ddf),
        icon: Icon(Icons.favorite),
        onPressed: () {
          // TODO: unfavorite this
        },
      );
    } else {
      return IconButton(
        color: Color(0xffff58ad),
        splashColor: Color(0xffff8ddf),
        icon: Icon(Icons.favorite_border),
        onPressed: () {
          // TODO: favorite this
        },
      );
    }
  }
}
