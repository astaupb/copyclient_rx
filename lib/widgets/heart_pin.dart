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
  bool last_keep;

  _HeartPinState(this.jobId);

  @override
  Widget build(BuildContext context) {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    return BlocBuilder<JoblistEvent, JoblistState>(
        bloc: joblistBloc,
        builder: (BuildContext context, JoblistState state) {
          Job job;
          if (state.isResult) {
            job = state.value[joblistBloc.getIndexById(jobId)];
            last_keep = job.jobOptions.keep;
          }
          bool keep = job?.jobOptions?.keep ?? last_keep ?? false;
          return IconButton(
            color: Color(0xffff58ad),
            splashColor: Color(0xffff8ddf),
            icon: Icon(keep ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              job.jobOptions.keep = !keep;
              joblistBloc.onUpdateOptionsById(jobId, job.jobOptions);
            },
          );
        });
  }
}
