import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';

import '../../widgets/details_dialog.dart';
import '../../widgets/joboption_switches.dart';
import '../../widgets/preview_grid.dart';
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
    //final JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
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
          PreviewGrid(_job),
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
