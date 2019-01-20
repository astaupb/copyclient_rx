import 'dart:io';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/drawer/drawer.dart';
import '../../widgets/exit_app_alert.dart';
import '../jobdetails/jobdetails.dart';
import 'joblist_tile.dart';

class JoblistPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _JoblistPageState();
}

class _JoblistPageState extends State<JoblistPage> {
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
                  if (state.isResult)
                    return Text('${state.value.credit}€');
                  else
                    return Text('0,00€');
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
                  return Center(
                    child: Padding(
                      child: Text(
                          'Die Jobliste ist aktuell leer. Oben rechts kannst du neue Dokumente hochladen.'),
                      padding: EdgeInsets.only(left: 40.0, right: 40.0),
                    ),
                  );
                } else {
                  return ListView.builder(
                    reverse: true,
                    itemExtent: 72.0,
                    itemCount: state.value.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (state.value[index] != null)
                        return Column(
                          children: <Widget>[
                            JoblistTile(
                              context,
                              index,
                              state.value[index],
                              onPress: (int index) =>
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          JobdetailsPage(state.value[index]),
                                    ),
                                  ),
                            ),
                            Divider(height: 0.0),
                          ],
                        );
                    },
                  );
                }
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
    var listener;
    listener = joblistBloc.state.listen((JoblistState state) {
      if (state.isResult) {
        listener.cancel();
        return;
      }
    });
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
