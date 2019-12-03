import 'dart:async';
import 'dart:io';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_creation.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';

class JoblistUploadFab extends StatefulWidget {
  @override
  _JoblistUploadFabState createState() => _JoblistUploadFabState();
}

class _JoblistUploadFabState extends State<JoblistUploadFab> {
  Timer uploadTimer;

  StreamSubscription uploadListener;
  int lastUploads = 0;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _onUploadPressed,
      child: Icon(Icons.cloud_upload, color: Colors.white),
    );
  }

  @override
  void dispose() {
    uploadListener.cancel();
    if (uploadTimer != null) uploadTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    uploadListener = BlocProvider.of<UploadBloc>(context).listen((UploadState state) async {
      if (state.isResult) {
        if (state.value.length < lastUploads) {
          await Future.delayed(Duration(milliseconds: 100));
          BlocProvider.of<JoblistBloc>(context).onRefresh();
        }
        if (state.value.length == 0) {
          if (uploadTimer != null) uploadTimer.cancel();
        }
        lastUploads = state.value.length;
      }
    });
    super.initState();
  }

  Future<Map<String, String>> _getFilePath() async {
    Map<String, String> filePaths;
    try {
      filePaths = await FilePicker.getMultiFilePath(type: FileType.ANY);
      print('got filepaths: $filePaths');
      if (filePaths != null && filePaths.isNotEmpty) return filePaths;
    } catch (e) {
      print("Error while picking the file: " + e.toString());
    }
    return {};
  }

  void _onUploadPressed() async {
    await _getFilePath().then(
      (Map<String, String> paths) => paths.forEach((String filename, String path) {
        if (lookupMimeType(filename).contains('application/pdf')) {
          BlocProvider.of<UploadBloc>(context)
              .onUpload(File(path).readAsBytesSync(), filename: filename);
        } else if (lookupMimeType(filename).contains('image/')) {
          StreamSubscription listener;
          listener =
              BlocProvider.of<PdfCreationBloc>(context).skip(1).listen((PdfCreationState state) {
            if (state.isResult) {
              BlocProvider.of<UploadBloc>(context).onUpload(state.value, filename: filename);
              listener.cancel();
            }
          });

          BlocProvider.of<PdfCreationBloc>(context).onCreateFromImage(File(path).readAsBytesSync());
        } else if (lookupMimeType(filename).contains('text/')) {
          StreamSubscription listener;
          listener =
              BlocProvider.of<PdfCreationBloc>(context).skip(1).listen((PdfCreationState state) {
            if (state.isResult) {
              BlocProvider.of<UploadBloc>(context).onUpload(state.value, filename: filename);
              listener.cancel();
            }
          });

          BlocProvider.of<PdfCreationBloc>(context)
              .onCreateFromText(File(path).readAsStringSync(), monospace: (!path.endsWith('txt')));
        } else {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(
                'Nicht unterstütztes Dateiformat in $filename. Es werden nur PDF Dokumente, Bilder und einfacher Text unterstützt.'),
            duration: Duration(seconds: 3),
          ));
        }
      }),
    );
    uploadTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => BlocProvider.of<UploadBloc>(context).onRefresh());
  }
}
