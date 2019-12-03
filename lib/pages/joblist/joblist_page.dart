import 'dart:async';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/drawer/drawer.dart';
import '../../widgets/exit_app_alert.dart';
import 'joblist_job_list.dart';
import 'joblist_scan_list.dart';
import 'joblist_upload_fab.dart';
import 'joblist_upload_queue.dart';

enum ListMode { print, scan, copy }

class JoblistPage extends StatefulWidget {
  @override
  _JoblistPageState createState() => _JoblistPageState();
}

class _JoblistPageState extends State<JoblistPage> {
  ListMode _mode = ListMode.print;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          bottomNavigationBar: CupertinoTabBar(
            currentIndex: _mode.index,
            onTap: _onTapTab,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.print), title: Text('Drucken')),
              BottomNavigationBarItem(icon: Icon(Icons.scanner), title: Text('Scannen')),
              BottomNavigationBarItem(icon: Icon(Icons.content_copy), title: Text('Kopieren')),
            ],
          ),
          appBar: AppBar(
            title: Text('AStA Copyclient'),
          ),
          drawer: MainDrawer(),
          floatingActionButton: (_mode == ListMode.print) ? JoblistUploadFab() : null,
          body: RefreshIndicator(
            onRefresh: () => _onRefresh(),
            child: ListView(
              semanticChildCount: 2,
              children: <Widget>[
                JoblistUploadQueue(),
                if (_mode == ListMode.print) JoblistJobList(),
                if (_mode == ListMode.scan) JoblistScanList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    BlocProvider.of<JoblistBloc>(context).onRefresh();
    BlocProvider.of<UploadBloc>(context).onRefresh();
    return;
  }

  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          builder: (context) => ExitAppAlert(),
        ) ??
        false;
  }

  void _onTapTab(int value) {
    setState(
        () => _mode = (value == 0) ? ListMode.print : (value == 1) ? ListMode.scan : ListMode.copy);
  }
}
