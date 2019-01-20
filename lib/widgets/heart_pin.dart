import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HeartPin extends StatefulWidget {
  final int jobId;

  HeartPin(this.jobId);

  @override
  State<StatefulWidget> createState() => _HeartPinState(jobId);
}

class _HeartPinState extends State<HeartPin> {
  int jobId;

  _HeartPinState(this.jobId);

  @override
  Widget build(BuildContext context) {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    return BlocBuilder<JoblistEvent, JoblistState>(
      bloc: joblistBloc,
      builder: (BuildContext context, JoblistState state) {
        if (state.isResult) {
          Job job = state.value[joblistBloc.getIndexById(jobId)];
          if (job.jobOptions.keep) {
            return IconButton(
              color: Color(0xffff58ad),
              splashColor: Color(0xffff8ddf),
              icon: Icon(Icons.favorite),
              onPressed: () {
                job.jobOptions.keep = false;
                joblistBloc.onUpdateOptionsById(jobId, job.jobOptions);
              },
            );
          } else {
            return IconButton(
              color: Color(0xffff58ad),
              splashColor: Color(0xffff8ddf),
              icon: Icon(Icons.favorite_border),
              onPressed: () {
                job.jobOptions.keep = true;
                joblistBloc.onUpdateOptionsById(jobId, job.jobOptions);
              },
            );
          }
        } else {
          return IconButton(
            onPressed: () => null,
            icon: Icon(
              Icons.favorite,
              color: Colors.grey,
            ),
          );
        }
      },
    );
  }
}
