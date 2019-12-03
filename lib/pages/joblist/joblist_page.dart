import 'dart:async';
import 'dart:io';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_creation.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../widgets/drawer/drawer.dart';
import '../../widgets/exit_app_alert.dart';
import 'joblist_job_list.dart';
import 'joblist_scan_list.dart';
import 'joblist_upload_fab.dart';
import 'joblist_upload_queue.dart';

class JoblistPage extends StatefulWidget {
  @override
  _JoblistPageState createState() => _JoblistPageState();
}

enum ListMode { print, scan, copy }

class _JoblistPageState extends State<JoblistPage> {
  ListMode _mode = ListMode.print;

  StreamSubscription<String> _intentTextSubscription;
  StreamSubscription<List<String>> _intentImageSubscription;
  StreamSubscription<List<String>> _intentDataStreamSubscription;

  Timer uploadTimer;
  StreamSubscription uploadListener;

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

  @override
  void dispose() {
    _intentTextSubscription.cancel();
    _intentImageSubscription.cancel();
    _intentDataStreamSubscription.cancel();
    uploadListener.cancel();

    if (uploadTimer != null) uploadTimer.cancel();

    super.dispose();
  }

  @override
  void initState() {
    uploadListener = BlocProvider.of<UploadBloc>(context).listen((UploadState state) {
      if (state.isResult && state.value.length == 0) {
        if (uploadTimer != null) uploadTimer.cancel();
      }
    });

    _intentTextSubscription = ReceiveSharingIntent.getTextStream().listen((String text) {
      ReceiveSharingIntent.reset();
      _handleIntentText(text);
    }, onError: (err) {
      print("intentTextSubscription error: $err");
    });

    ReceiveSharingIntent.getInitialText().then((String text) {
      ReceiveSharingIntent.reset();
      _handleIntentText(text);
    });

    _intentImageSubscription = ReceiveSharingIntent.getImageStream().listen((List<String> value) {
      ReceiveSharingIntent.reset();
      _handleIntentValue(value);
    }, onError: (err) {
      print("intentImageSubscription error: $err");
    });

    ReceiveSharingIntent.getInitialImage().then((List<String> value) {
      // Call reset method if you don't want to see this callback again.
      ReceiveSharingIntent.reset();
      _handleIntentValue(value);
    });

    // For sharing images coming from outside the app while the app is in the memory
    if (Platform.isAndroid)
      _intentDataStreamSubscription =
          ReceiveSharingIntent.getPdfStream().listen((List<String> value) {
        // Call reset method if you don't want to see this callback again.
        ReceiveSharingIntent.reset();
        _handleIntentValue(value);
      }, onError: (err) {
        print("intentDataStreamSubscription error: $err");
      });

    // For sharing images coming from outside the app while the app is closed
    if (Platform.isAndroid)
      ReceiveSharingIntent.getInitialPdf().then((List<String> value) {
        // Call reset method if you don't want to see this callback again.
        ReceiveSharingIntent.reset();
        _handleIntentValue(value);
      });

    super.initState();
  }

  void _handleIntentText(String text) {
    if (text != null) {
      StreamSubscription listener;
      listener = BlocProvider.of<PdfCreationBloc>(context).skip(1).listen((PdfCreationState state) {
        if (state.isResult) {
          BlocProvider.of<UploadBloc>(context)
              .onUpload(state.value, filename: 'text_${DateTime.now().toIso8601String()}.txt');
          listener.cancel();
        }
      });
      BlocProvider.of<PdfCreationBloc>(context).onCreateFromText(text);
    }

    StreamSubscription listener;
    listener = BlocProvider.of<UploadBloc>(context).listen((UploadState state) {
      if (state.isResult &&
          state.value.where((DispatcherTask task) => task.isUploading).length > 0) {
        uploadTimer = Timer.periodic(
            const Duration(seconds: 1), (_) => BlocProvider.of<UploadBloc>(context).onRefresh());
        listener.cancel();
      }
    });
  }

  void _handleIntentValue(List<String> value) async {
    if (value != null) {
      await PermissionHandler().shouldShowRequestPermissionRationale(PermissionGroup.storage);
      await PermissionHandler().requestPermissions([PermissionGroup.storage]);

      for (String url in value) {
        final File file = File(url);
        final String filename = file.path.split('/').last;
        final int numericFilename = int.tryParse(filename);
        print('upload filename $filename');

        if (lookupMimeType(filename).contains('application/pdf')) {
          BlocProvider.of<UploadBloc>(context).onUpload(await file.readAsBytes(),
              filename: (numericFilename == null) ? filename : null);
        } else if (lookupMimeType(filename).contains('image/')) {
          StreamSubscription listener;
          listener =
              BlocProvider.of<PdfCreationBloc>(context).skip(1).listen((PdfCreationState state) {
            if (state.isResult) {
              BlocProvider.of<UploadBloc>(context).onUpload(state.value, filename: filename);
              listener.cancel();
            }
          });

          BlocProvider.of<PdfCreationBloc>(context).onCreateFromImage(await file.readAsBytes());
        }
      }

      StreamSubscription listener;
      listener = BlocProvider.of<UploadBloc>(context).listen((UploadState state) {
        if (state.isResult &&
            state.value.where((DispatcherTask task) => task.isUploading).length > 0) {
          uploadTimer = Timer.periodic(
              const Duration(seconds: 1), (_) => BlocProvider.of<UploadBloc>(context).onRefresh());
          listener.cancel();
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    BlocProvider.of<JoblistBloc>(context).onRefresh();
    BlocProvider.of<UploadBloc>(context).onRefresh();
    return;
  }

  void _onTapTab(int value) {
    setState(
        () => _mode = (value == 0) ? ListMode.print : (value == 1) ? ListMode.scan : ListMode.copy);
  }

  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          builder: (context) => ExitAppAlert(),
        ) ??
        false;
  }
}
