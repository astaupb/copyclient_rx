import 'dart:async';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:copyclient_rx/blocs/selection_bloc.dart';
import 'package:copyclient_rx/blocs/theme_bloc.dart';
import 'package:copyclient_rx/pages/joblist/joblist_popup_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../widgets/drawer/drawer.dart';
import '../../widgets/exit_app_alert.dart';
import 'joblist_intent_handlers.dart';
import 'joblist_job_list.dart';
import 'joblist_refreshing_bloc.dart';
import 'joblist_scan_list.dart';
import 'joblist_upload_fab.dart';
import 'joblist_upload_queue.dart';

class JoblistPage extends StatefulWidget {
  @override
  _JoblistPageState createState() => _JoblistPageState();
}

enum ListMode { print, scan, copy }

class _JoblistPageState extends State<JoblistPage> {
  SelectionBloc selectionBloc;
  RefreshingBloc refreshingBloc;
  ListMode _mode = ListMode.print;

  StreamSubscription<String> _intentTextSubscription;
  StreamSubscription<List<String>> _intentImageSubscription;
  StreamSubscription<List<String>> _intentDataStreamSubscription;

  StreamSubscription _uploadListener;
  StreamSubscription<SelectionState> _selectionListener;
  StreamSubscription _refreshingListener;

  List<int> _selectedItems = [];

  bool allSelected = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: DefaultTabController(
        length: 3,
        child: BlocProvider<SelectionBloc>(
          create: (BuildContext context) => selectionBloc,
          child: Scaffold(
            bottomNavigationBar: CupertinoTabBar(
              backgroundColor:
                  (BlocProvider.of<ThemeBloc>(context).state.id == CopyclientTheme.dark)
                      ? Colors.grey[900]
                      : null,
              currentIndex: _mode.index,
              onTap: _onTapTab,
              activeColor: (BlocProvider.of<ThemeBloc>(context).state.id == CopyclientTheme.dark)
                  ? Colors.white
                  : null,
              iconSize: 28.0,
              items: [
                BottomNavigationBarItem(
                    icon: Icon(Icons.print), title: Text('Drucken', textScaleFactor: 1.3)),
                BottomNavigationBarItem(
                    icon: Icon(Icons.scanner), title: Text('Scannen', textScaleFactor: 1.3)),
                BottomNavigationBarItem(
                    icon: Icon(Icons.content_copy), title: Text('Kopieren', textScaleFactor: 1.3)),
              ],
            ),
            appBar: AppBar(
              actions: (_selectedItems.isNotEmpty)
                  ? <Widget>[
                      IconButton(icon: Icon(Icons.clear), onPressed: () => selectionBloc.onClear()),
                      Center(
                          child: Text(
                        '${selectionBloc.items.length} Job${selectionBloc.items.length > 1 ? 's' : ''} ausgewählt',
                        style: TextStyle(fontSize: 20.0),
                      )),
                      Spacer(),
                      IconButton(icon: Icon(Icons.select_all), onPressed: _onSelectAll),
                    ]
                  : <Widget>[JoblistPopupButton()],
              automaticallyImplyLeading: _selectedItems.isEmpty,
              title: Text('AStA Copyclient'),
            ),
            drawer: MainDrawer(),
            floatingActionButton: (_mode == ListMode.print)
                ? (selectionBloc.items.isEmpty)
                    ? JoblistUploadFab()
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FloatingActionButton(
                            child: Icon(Icons.delete, color: Colors.white),
                            onPressed: _onDeleteSelected,
                          ),
                          Container(width: 8.0, height: 0.0),
                          FloatingActionButton(
                            child: Icon(Icons.print, color: Colors.white),
                            onPressed: _onPrintSelected,
                          ),
                        ],
                      )
                : null,
            body: RefreshIndicator(
              onRefresh: () => _onRefresh(),
              child: ListView(
                semanticChildCount: 2,
                children: <Widget>[
                  JoblistUploadQueue(),
                  if (_mode == ListMode.print) JoblistJobList(),
                  if (_mode == ListMode.scan) JoblistScanList(),
                  if (_mode == ListMode.copy) JoblistScanList(copyMode: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _intentTextSubscription.cancel();
    _intentImageSubscription.cancel();
    _intentDataStreamSubscription.cancel();
    _uploadListener.cancel();
    _selectionListener.cancel();
    selectionBloc.close();
    refreshingBloc.close();

    super.dispose();
  }

  @override
  void initState() {
    selectionBloc = SelectionBloc();
    refreshingBloc = RefreshingBloc();

    _refreshingListener = refreshingBloc.listen((RefreshingState state) {
      if (state.isRefreshing) {
        if (state.refreshJobs) {
          BlocProvider.of<JoblistBloc>(context).onRefresh();
        }
        if (state.refreshQueue) {
          BlocProvider.of<UploadBloc>(context).onRefresh();
        }
      }
    });

    _selectionListener = selectionBloc.listen((SelectionState state) {
      setState(() => _selectedItems = state.items);
    });

    _uploadListener = BlocProvider.of<UploadBloc>(context).listen((UploadState state) {
      if (state.isResult) {
        refreshingBloc.onAddUploads(state.value);
      }
    });

    _intentTextSubscription = ReceiveSharingIntent.getTextStream().listen((String text) {
      ReceiveSharingIntent.reset();
      handleIntentText(text, context);
    }, onError: (err) {
      print("intentTextSubscription error: $err");
    });

    ReceiveSharingIntent.getInitialText().then((String text) {
      ReceiveSharingIntent.reset();
      handleIntentText(text, context);
    });

    _intentImageSubscription = ReceiveSharingIntent.getImageStream().listen((List<String> value) {
      ReceiveSharingIntent.reset();
      handleIntentValue(value, context);
    }, onError: (err) {
      print("intentImageSubscription error: $err");
    });

    ReceiveSharingIntent.getInitialImage().then((List<String> value) {
      // Call reset method if you don't want to see this callback again.
      ReceiveSharingIntent.reset();
      handleIntentValue(value, context);
    });

    // For sharing images coming from outside the app while the app is in the memory
    if (Platform.isAndroid)
      _intentDataStreamSubscription =
          ReceiveSharingIntent.getPdfStream().listen((List<String> value) {
        // Call reset method if you don't want to see this callback again.
        ReceiveSharingIntent.reset();
        handleIntentValue(value, context);
      }, onError: (err) {
        print("intentDataStreamSubscription error: $err");
      });

    // For sharing images coming from outside the app while the app is closed
    if (Platform.isAndroid)
      ReceiveSharingIntent.getInitialPdf().then((List<String> value) {
        // Call reset method if you don't want to see this callback again.
        ReceiveSharingIntent.reset();
        handleIntentValue(value, context);
      });

    super.initState();
  }

  void _onDeleteSelected() {
    for (int item in selectionBloc.items) {
      BlocProvider.of<JoblistBloc>(context).onDeleteById(item);
      selectionBloc.onToggleItem(item);
    }
  }

  void _onPrintSelected() async {
    String barcode = '';
    try {
      barcode = await BarcodeScanner.scan();
    } catch (e) {
      print(e);
    }

    for (int item in selectionBloc.items) {
      BlocProvider.of<JoblistBloc>(context).onPrintById(barcode, item);
      selectionBloc.onToggleItem(item);
    }
  }

  Future<void> _onRefresh() async {
    BlocProvider.of<JoblistBloc>(context).onRefresh();
    BlocProvider.of<UploadBloc>(context).onRefresh();
    return;
  }

  void _onSelectAll() {
    selectionBloc.onClear();
    if (!allSelected) {
      for (Job job in BlocProvider.of<JoblistBloc>(context).jobs) {
        selectionBloc.onToggleItem(job.id);
      }
      allSelected = true;
    } else
      allSelected = false;
  }

  void _onTapTab(int value) {
    setState(
        () => _mode = (value == 0) ? ListMode.print : (value == 1) ? ListMode.scan : ListMode.copy);
    if (_mode == ListMode.scan || _mode == ListMode.copy) {
      refreshingBloc.onEnableForce();
    } else if (_mode == ListMode.print) {
      refreshingBloc.onDisableForce();
    }
  }

  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          builder: (context) => ExitAppAlert(),
        ) ??
        false;
  }
}
