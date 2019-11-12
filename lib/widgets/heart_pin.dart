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
  JoblistBloc joblistBloc;

  int jobId;
  bool lastKeep;

  _HeartPinState(this.jobId);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JoblistBloc, JoblistState>(
      bloc: joblistBloc,
      builder: (BuildContext context, JoblistState state) {
        Job job;
        if (state.isResult) {
          job = state.value[joblistBloc.getIndexById(jobId)];
          lastKeep = job.jobOptions.keep;
        }
        bool keep = job?.jobOptions?.keep ?? lastKeep ?? false;
        return IconButton(
          color: Color(0xffff58ad),
          splashColor: Color(0xffff8ddf),
          icon: Icon(keep ? Icons.favorite : Icons.favorite_border),
          onPressed: () {
            job.jobOptions.keep = !keep;
            joblistBloc.onUpdateOptionsById(jobId, job.jobOptions);
          },
        );
      },
    );
  }

  @override
  void initState() {
    joblistBloc = BlocProvider.of<JoblistBloc>(context);
    super.initState();
  }
}
