import 'dart:async';
import 'dart:io';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/centered_text.dart';
import '../../widgets/drawer/drawer.dart';
import '../../widgets/exit_app_alert.dart';
import '../jobdetails/jobdetails.dart';
import 'joblist_tile.dart';

class JoblistPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _JoblistPageState();
}

class _JoblistPageState extends State<JoblistPage> {
  int lastCredit;

  @override
  Widget build(BuildContext context) {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    return WillPopScope(
      onWillPop: () => _onWillPop(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Jobliste'),
          actions: <Widget>[
            MaterialButton(
              child: BlocBuilder<UserEvent, UserState>(
                bloc: BlocProvider.of<UserBloc>(context),
                builder: (BuildContext context, UserState state) {
                  if (state.isResult) {
                    lastCredit = state.value.credit;
                    return Text(
                        '${(state.value.credit / 100).toStringAsFixed(2)} €');
                  } else
                    return Text(
                        '${((lastCredit ?? 0) / 100.0).toStringAsFixed(2)} €');
                },
              ),
              onPressed: () => Navigator.of(context).pushNamed('/transactions'),
            ),
            IconButton(
              tooltip: 'Dokument hochladen',
              icon: Icon(Icons.note_add),
              onPressed: () => _onSelectedUpload(),
            ),
          ],
        ),
        drawer: MainDrawer(),
        body: RefreshIndicator(
          onRefresh: () => _onRefresh(),
          child: BlocBuilder<JoblistEvent, JoblistState>(
            bloc: joblistBloc,
            builder: (BuildContext context, JoblistState state) {
              if (state.isResult) {
                if (state.value.length == 0) {
                  return ListView(
                    children: <Widget>[
                      ListTile(
                        title: Text('''
Die Jobliste ist aktuell leer. 
Oben rechts kannst du neue Dokumente hochladen.
                    '''),
                      )
                    ],
                  );
                } else {
                  final reverseList = state.value.reversed.toList();
                  return ListView.builder(
                    itemExtent: 72.0,
                    itemCount: reverseList.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (reverseList[index] != null)
                        return Column(
                          children: <Widget>[
                            Dismissible(
                              key: Key(reverseList[index].id.toString()),
                              onDismissed: (DismissDirection direction) =>
                                  _onTileDismissed(
                                      context, reverseList[index].id),
                              background: _dismissableBackground(),
                              confirmDismiss: (DismissDirection diection) {
                                bool keepJob = false;
                                SnackBar snack = SnackBar(
                                  duration: Duration(seconds: 2),
                                  content: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      MaterialButton(
                                        child:
                                            Text('Löschen rückgängig machen'),
                                        onPressed: () {
                                          keepJob = true;
                                        },
                                      )
                                    ],
                                  ),
                                );

                                ScaffoldFeatureController snackController =
                                    Scaffold.of(context).showSnackBar(snack);

                                if (keepJob) snackController.close();

                                return snackController.closed
                                    .then((val) => !keepJob);
                              },
                              child: JoblistTile(
                                context,
                                index,
                                reverseList[index],
                                onPress: (int index) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          JobdetailsPage(reverseList[index]),
                                    ),
                                  );
                                },
                                onLongTap: (int index) => _onLongTapped(
                                    context,
                                    reverseList[index].id,
                                    reverseList[index].jobOptions),
                              ),
                            ),
                            Divider(height: 0.0),
                          ],
                        );
                    },
                  );
                }
              } else if (state.isException) {
                return ListView(
                  children: <Widget>[
                    ListTile(
                      title: Text(state.error.toString()),
                    )
                  ],
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  Container _dismissableBackground() => Container(
        color: Colors.redAccent,
        child: Row(
          children: <Widget>[
            Text('Job löschen', style: TextStyle(color: Colors.white)),
            Spacer(),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
        padding: EdgeInsets.all(20.0),
      );

  Future<String> _getFilePath() async {
    String filePath;
    try {
      filePath = await FilePicker.getFilePath(
          type: FileType.CUSTOM, fileExtension: 'pdf');
      if (filePath != '') return filePath;
    } catch (e) {
      print("Error while picking the file: " + e.toString());
    }
    return '';
  }

  void _onLongTapped(BuildContext context, int id, JobOptions options) {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    JobOptions newOptions = options;

    newOptions.keep = !newOptions.keep;
    joblistBloc.onUpdateOptionsById(id, newOptions);

    Scaffold.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 1),
        content: Text((newOptions.keep)
            ? 'Job wird behalten'
            : 'Job wird nicht mehr behalten'),
      ),
    );
  }

  Future<void> _onRefresh() async {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    UserBloc userBloc = BlocProvider.of<UserBloc>(context);
    var listener;
    listener = joblistBloc.state.listen((JoblistState state) {
      if (state.isResult) {
        listener.cancel();
        return;
      }
    });
    userBloc.onRefresh();
    joblistBloc.onRefresh();
  }

  void _onSelectedUpload() async {
    UploadBloc uploadBloc = BlocProvider.of<UploadBloc>(context);
    String filePath = await _getFilePath();
    uploadBloc.onUpload(File(filePath).readAsBytesSync(),
        filename: filePath.split('/').last);
  }

  void _onTileDismissed(BuildContext context, int id) async {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    joblistBloc.onDeleteById(id);
  }

  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          builder: (context) => ExitAppAlert(),
        ) ??
        false;
  }
}
