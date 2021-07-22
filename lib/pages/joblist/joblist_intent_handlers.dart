import 'dart:async';
import 'dart:io';

import 'package:blocs_copyclient/pdf_creation.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';

void handleIntentText(String text, BuildContext context) {
  if (text != null) {
    StreamSubscription listener;
    listener =
        BlocProvider.of<PdfCreationBloc>(context).stream.skip(1).listen((PdfCreationState state) {
      if (state.isResult) {
        BlocProvider.of<UploadBloc>(context)
            .onUpload(state.value, filename: 'text_${DateTime.now().toIso8601String()}.txt');
        listener.cancel();
      }
    });
    BlocProvider.of<PdfCreationBloc>(context).onCreateFromText(text);
  }
}

void handleIntentValue(List<String> value, BuildContext context) async {
  if (value != null) {
    if (!(await Permission.contacts.request().isGranted)) {
      Map<Permission, PermissionStatus> statuses = await [Permission.storage].request();
      print(statuses[Permission.storage]);
    }

    for (var url in value) {
      final file = File(url);
      final filename = file.path.split('/').last;
      final numericFilename = int.tryParse(filename);
      print('upload filename $filename');

      if (lookupMimeType(filename).contains('application/pdf')) {
        BlocProvider.of<UploadBloc>(context).onUpload(await file.readAsBytes(),
            filename: (numericFilename == null) ? filename : null);
      } else if (lookupMimeType(filename).contains('image/')) {
        StreamSubscription listener;
        listener = BlocProvider.of<PdfCreationBloc>(context)
            .stream
            .skip(1)
            .listen((PdfCreationState state) {
          if (state.isResult) {
            BlocProvider.of<UploadBloc>(context).onUpload(state.value, filename: filename);
            listener.cancel();
          }
        });

        BlocProvider.of<PdfCreationBloc>(context).onCreateFromImage(await file.readAsBytes());
      }
    }
  }
}
