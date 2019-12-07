import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class JoblistSlidable extends StatelessWidget {
  final Widget child;
  final Job job;

  JoblistSlidable({@required this.child, @required this.job});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: (job.jobOptions.keep) ? 'Nicht behalten' : 'Behalten',
          color: Color(0xffff58ad),
          icon: (job.jobOptions.keep) ? Icons.favorite_border : Icons.favorite,
          onTap: () => _onKeepJob(context, job.id, job.jobOptions),
        ),
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => _onDeleteJob(context, job.id),
        ),
      ],
      child: child,
    );
  }

  void _onDeleteJob(BuildContext context, int id) {
    BlocProvider.of<JoblistBloc>(context).onDeleteById(id);
  }

  void _onKeepJob(BuildContext context, int id, JobOptions jobOptions) {
    jobOptions.keep = !jobOptions.keep;
    BlocProvider.of<JoblistBloc>(context).onUpdateOptionsById(id, jobOptions);
  }
}
