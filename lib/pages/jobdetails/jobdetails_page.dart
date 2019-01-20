import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/details_dialog.dart';
import '../../widgets/joboption_switches.dart';
import 'header_tile.dart';

///
/// A Page that holds additional information on each job on the joblist
/// Contains: Preview Grid, Header Tile, Joboptions Switches
///
class JobdetailsPage extends StatelessWidget {
  final Job _job;

  JobdetailsPage(this._job);

  @override
  Widget build(BuildContext context) {
    //JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_job.jobInfo.filename),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => showDialog(
                  context: context,
                  builder: (context) => DetailsDialog(_job),
                ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Text(_job.jobInfo.filename),
          Card(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: HeaderTile(_job),
            ),
          ),
          Card(
            child: JoboptionSwitches(_job),
          ),
        ],
      ),
    );
  }
}
