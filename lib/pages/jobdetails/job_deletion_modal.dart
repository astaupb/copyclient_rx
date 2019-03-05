import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JobDeletionModal extends StatefulWidget {
  final int id;

  const JobDeletionModal(
    this.id, {
    Key key,
  }) : super(key: key);

  @override
  _JobDeletionModalState createState() => _JobDeletionModalState();
}

class _JobDeletionModalState extends State<JobDeletionModal> {
  @override
  Widget build(BuildContext context) {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Text('Wirklich löschen?'),
          Spacer(),
          MaterialButton(
            child: Text('Nein'),
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.teal,
          ),
          MaterialButton(
            child: Text('Ja'),
            onPressed: () {
              joblistBloc.onDeleteById(widget.id);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            color: Colors.teal,
          )
        ],
      ),
    );
  }
}
