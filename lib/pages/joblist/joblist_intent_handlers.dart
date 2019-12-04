import 'dart:async';
import 'dart:io';

import 'package:blocs_copyclient/pdf_creation.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';

void handleIntentText(String text, BuildContext context, Timer timer) {
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
    if (state.isResult && state.value.where((DispatcherTask task) => task.isUploading).length > 0) {
      timer = Timer.periodic(
          const Duration(seconds: 1), (_) => BlocProvider.of<UploadBloc>(context).onRefresh());
      listener.cancel();
    }
  });
}

void handleIntentValue(List<String> value, BuildContext context, Timer uploadTimer) async {
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
