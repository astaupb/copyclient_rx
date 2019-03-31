import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JoblistDeletionModal extends StatefulWidget {
  final List<int> ids;

  const JoblistDeletionModal(
    this.ids, {
    Key key,
  }) : super(key: key);

  @override
  _JoblistDeletionModalState createState() => _JoblistDeletionModalState();
}

class _JoblistDeletionModalState extends State<JoblistDeletionModal> {
  @override
  Widget build(BuildContext context) {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Text('Wirklich Ausgewählte löschen?'),
          Spacer(),
          MaterialButton(
            child: Text('Nein'),
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.teal,
          ),
          MaterialButton(
            child: Text('Ja'),
            onPressed: () {
              for (int id in widget.ids) {
                joblistBloc.onDeleteById(id);
              }
              Navigator.of(context).pop();
            },
            color: Colors.teal,
          )
        ],
      ),
    );
  }
}
