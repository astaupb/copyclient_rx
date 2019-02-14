import 'dart:io';
import 'dart:async';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/drawer/drawer.dart';
import '../../widgets/exit_app_alert.dart';
import '../../widgets/centered_text.dart';
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
            bloc: BlocProvider.of<JoblistBloc>(context),
            builder: (BuildContext context, JoblistState state) {
              if (state.isResult) {
                if (state.value.length == 0) {
                  return GestureDetector(
                    onTap: () =>
                        BlocProvider.of<JoblistBloc>(context).onRefresh(),
                    child: CenteredText('''
Die Jobliste ist aktuell leer. 
Oben rechts kannst du neue Dokumente hochladen.
                    '''),
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
                            JoblistTile(
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
                            ),
                            Divider(height: 0.0),
                          ],
                        );
                    },
                  );
                }
              } else if (state.isException) {
                return CenteredText(state.error.toString());
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

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

  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          builder: (context) => ExitAppAlert(),
        ) ??
        false;
  }
}
