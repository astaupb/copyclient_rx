import 'dart:async';
import 'dart:io';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/print_queue.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:copyclient_rx/blocs/camera_bloc.dart';
import 'package:copyclient_rx/blocs/selection_bloc.dart';
import 'package:copyclient_rx/blocs/theme_bloc.dart';
import 'package:copyclient_rx/pages/joblist/joblist_mode_bloc.dart';
import 'package:copyclient_rx/pages/joblist/joblist_popup_button.dart';
import 'package:copyclient_rx/widgets/select_printer_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../widgets/drawer/drawer.dart';
import '../../widgets/exit_app_alert.dart';
import 'joblist_intent_handlers.dart';
import 'joblist_job_list.dart';
import 'joblist_qr_code.dart';
import 'joblist_refreshing_bloc.dart';
import 'joblist_scan_list.dart';
import 'joblist_upload_fab.dart';
import 'joblist_upload_queue.dart';

class JoblistPage extends StatefulWidget {
  @override
  _JoblistPageState createState() => _JoblistPageState();
}

class _JoblistPageState extends State<JoblistPage> {
  SelectionBloc selectionBloc;
  RefreshingBloc refreshingBloc;
  JoblistModeBloc joblistModeBloc;

  JoblistMode _mode = JoblistMode.print;

  StreamSubscription<String> _intentTextSubscription;
  StreamSubscription<List<String>> _intentImageSubscription;
  StreamSubscription<List<String>> _intentDataStreamSubscription;

  StreamSubscription _uploadListener;
  StreamSubscription<SelectionState> _selectionListener;
  StreamSubscription<JoblistMode> _joblistModeListener;
  StreamSubscription _refreshingListener;

  List<int> _selectedItems = [];

  bool allSelected = false;

  int _deviceId;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: DefaultTabController(
        length: 3,
        child: BlocProvider<SelectionBloc>(
          create: (BuildContext context) => selectionBloc,
          child: Scaffold(
            bottomNavigationBar: (!kIsWeb)
                ? Builder(
                    builder: (BuildContext context) => CupertinoTabBar(
                      backgroundColor:
                          (BlocProvider.of<ThemeBloc>(context).state.id == CopyclientTheme.dark)
                              ? Colors.grey[900]
                              : null,
                      currentIndex: _mode.index,
                      onTap: (int index) => _onTapTab(context, index),
                      activeColor:
                          (BlocProvider.of<ThemeBloc>(context).state.id == CopyclientTheme.dark)
                              ? Colors.white
                              : null,
                      iconSize: 28.0,
                      items: [
                        BottomNavigationBarItem(
                            icon: Icon(Icons.print), title: Text('Drucken', textScaleFactor: 1.5)),
                        BottomNavigationBarItem(
                            icon: Icon(Icons.scanner),
                            title: Text('Scannen', textScaleFactor: 1.5)),
                        BottomNavigationBarItem(
                            icon: Icon(Icons.content_copy),
                            title: Text('Kopieren', textScaleFactor: 1.4)),
                      ],
                    ),
                  )
                : null,
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
            floatingActionButton: BlocBuilder<JoblistModeBloc, JoblistMode>(
              bloc: joblistModeBloc,
              builder: (BuildContext context, JoblistMode mode) {
                if (mode == JoblistMode.print) {
                  if (selectionBloc.items.isEmpty) {
                    return JoblistUploadFab();
                  } else {
                    return Row(
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
                    );
                  }
                } else {
                  return Container(width: 0.0, height: 0.0);
                }
              },
            ),
            body: RefreshIndicator(
              onRefresh: () => _onRefresh(),
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<RefreshingBloc>(create: (BuildContext context) => refreshingBloc),
                  BlocProvider<JoblistModeBloc>(create: (BuildContext context) => joblistModeBloc),
                ],
                child: ListView(
                  semanticChildCount: 2,
                  children: <Widget>[
                    JoblistUploadQueue(),
                    if (_mode == JoblistMode.print)
                      JoblistJobList()
                    else if (_mode == JoblistMode.scan)
                      JoblistScanList(_deviceId)
                    else if (_mode == JoblistMode.copy)
                      JoblistScanList(_deviceId, copyMode: true),
                  ],
                ),
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
    if (_intentDataStreamSubscription != null) _intentDataStreamSubscription.cancel();
    _uploadListener.cancel();
    _selectionListener.cancel();
    _refreshingListener.cancel();
    _joblistModeListener.cancel();
    selectionBloc.close();
    refreshingBloc.close();

    super.dispose();
  }

  @override
  void initState() {
    joblistModeBloc = JoblistModeBloc(JoblistMode.print);
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

    _joblistModeListener = joblistModeBloc.listen((JoblistMode mode) {
      setState(() => _mode = mode);
      if (mode == JoblistMode.print) {
        if (BlocProvider.of<PrintQueueBloc>(context).state.isLocked) {
          BlocProvider.of<PrintQueueBloc>(context).onDelete();
        }
        refreshingBloc.onDisableForce();
      }
    });

    _uploadListener = BlocProvider.of<UploadBloc>(context).listen((UploadState state) {
      if (state.isResult) {
        refreshingBloc.onAddUploads(state.value);
      }
    });

    _intentTextSubscription = ReceiveSharingIntent.getTextStream().listen((String text) {
      ReceiveSharingIntent.reset();
      handleIntentText(text, context);
    }, onError: (dynamic err) {
      print('intentTextSubscription error: $err');
    });

    ReceiveSharingIntent.getInitialText().then((String text) {
      ReceiveSharingIntent.reset();
      handleIntentText(text, context);
    });

    _intentImageSubscription = ReceiveSharingIntent.getImageStream().listen((List<String> value) {
      ReceiveSharingIntent.reset();
      handleIntentValue(value, context);
    }, onError: (dynamic err) {
      print('intentImageSubscription error: $err');
    });

    ReceiveSharingIntent.getInitialImage().then((List<String> value) {
      // Call reset method if you don't want to see this callback again.
      ReceiveSharingIntent.reset();
      handleIntentValue(value, context);
    });

    // For sharing images coming from outside the app while the app is in the memory
    if (!kIsWeb && Platform.isAndroid) {
      _intentDataStreamSubscription =
          ReceiveSharingIntent.getPdfStream().listen((List<String> value) {
        // Call reset method if you don't want to see this callback again.
        ReceiveSharingIntent.reset();
        handleIntentValue(value, context);
      }, onError: (dynamic err) {
        print('intentDataStreamSubscription error: $err');
      });
    }

    // For sharing images coming from outside the app while the app is closed
    if (!kIsWeb && Platform.isAndroid) {
      ReceiveSharingIntent.getInitialPdf().then((List<String> value) {
        // Call reset method if you don't want to see this callback again.
        ReceiveSharingIntent.reset();
        handleIntentValue(value, context);
      });
    }

    super.initState();
  }

  void _onDeleteSelected() {
    for (var item in selectionBloc.items) {
      BlocProvider.of<JoblistBloc>(context).onDeleteById(item);
      selectionBloc.onToggleItem(item);
    }
  }

  void _onPrintSelected() async {
    String barcode;
    if (BlocProvider.of<CameraBloc>(context).state.cameraDisabled) {
      barcode = await showDialog<String>(
          context: context, builder: (BuildContext context) => selectPrinterDialog(context));
    } else {
      barcode = (await getDeviceId(context)).toString();
    }

    for (var item in selectionBloc.items) {
      BlocProvider.of<JoblistBloc>(context).onPrintById(barcode, item);
      selectionBloc.onToggleItem(item);
    }
  }

  Future<void> _onRefresh() async {
    BlocProvider.of<JoblistBloc>(context).onRefresh();
    BlocProvider.of<UploadBloc>(context).onRefresh();
    BlocProvider.of<UserBloc>(context).onRefresh();
    return;
  }

  void _onSelectAll() {
    selectionBloc.onClear();
    if (!allSelected) {
      for (var job in BlocProvider.of<JoblistBloc>(context).jobs) {
        selectionBloc.onToggleItem(job.id);
      }
      allSelected = true;
    } else {
      allSelected = false;
    }
  }

  void _onTapTab(BuildContext context, int value) async {
    if (value > 0) {
      int id;
      if (BlocProvider.of<CameraBloc>(context).state.cameraDisabled) {
        id = int.tryParse(await showDialog<String>(
                context: context,
                builder: (BuildContext context) => selectPrinterDialog(context)) ??
            '');
      } else {
        id = await getDeviceId(context);
      }

      if (id != null) {
        _deviceId = id;
        joblistModeBloc.onSwitch((value == 1) ? JoblistMode.scan : JoblistMode.copy);
      }
    } else {
      joblistModeBloc.onSwitch(JoblistMode.print);
    }
  }

  Future<bool> _onWillPop() async {
    if (joblistModeBloc.mode != JoblistMode.print) {
      joblistModeBloc.onSwitch(JoblistMode.print);
      refreshingBloc.onDisableForce();
      return Future.value(false);
    } else {
      return await showDialog(
            context: context,
            builder: (context) => ExitAppAlert(),
          ) ??
          false;
    }
  }
}
