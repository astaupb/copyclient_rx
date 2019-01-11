import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs_copyclient/joblist.dart';

import 'joblist_tile.dart';
import '../../widgets/drawer.dart';

class JoblistPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _JoblistPageState();
}

class _JoblistPageState extends State<JoblistPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jobliste'),
      ),
      drawer: MainDrawer(),
      body: BlocBuilder<JoblistEvent, JoblistState>(
        bloc: BlocProvider.of<JoblistBloc>(context),
        builder: (BuildContext context, JoblistState state) {
          if (state.isResult) {
            if (state.value.length == 0) {
              return Center(
                child: Padding(
                  child: Text(
                      'Die Jobliste ist aktuell leer. Oben rechts kannst du neue Dokumente hochladen.'),
                  padding: EdgeInsets.only(left: 40.0, right: 40.0),
                ),
              );
            } else {
              return ListView.builder(
                itemExtent: 80.0,
                itemCount: state.value.length,
                itemBuilder: (BuildContext context, int index) {
                  if (state.value[index] != null)
                    return JoblistTile(context, index, state.value[index]);
                },
              );
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
