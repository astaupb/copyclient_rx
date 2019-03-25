import 'dart:io';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../widgets/details_dialog.dart';
import '../../widgets/joboption_switches.dart';
import '../../widgets/preview_grid.dart';
import 'header_tile.dart';
import 'job_deletion_modal.dart';

///
/// A Page that holds additional information on each job on the joblist
/// Contains: Preview Grid, Header Tile, Joboptions Switches
///
class JobdetailsPage extends StatelessWidget {
  final Job _job;

  JobdetailsPage(this._job);

  @override
  Widget build(BuildContext context) {
    //final JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_job.jobInfo.filename),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return JobDeletionModal(_job.id);
                }),
          ),
          (!Platform.isIOS)
              ? Builder(
                  builder: (BuildContext context) => IconButton(
                        icon: Icon(Icons.file_download),
                        onPressed: () => _onPdfDownload(context),
                      ),
                )
              : Container(width: 0.0, height: 0.0),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => showDialog(
                  context: context,
                  builder: (context) => DetailsDialog(_job),
                ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          PreviewGrid(_job),
          Card(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: HeaderTile(_job),
            ),
          ),
          Card(
            child: JoboptionSwitches(_job),
          ),
        ],
      ),
    );
  }

  void _onPdfDownload(BuildContext context) async {
    const SnackBar doneSnack = SnackBar(
      duration: const Duration(seconds: 1),
      content: Text('PDF unter Downloads gespeichert'),
    );
    const SnackBar errorSnack = SnackBar(
      duration: const Duration(seconds: 1),
      content: Text('Fehler beim Download der PDF'),
    );
    const SnackBar downloadSnack = SnackBar(
      duration: const Duration(seconds: 30),
      content: Text('Lade PDF...'),
    );
    PdfBloc pdfBloc = BlocProvider.of<PdfBloc>(context);

    await PermissionHandler().shouldShowRequestPermissionRationale(PermissionGroup.storage);
    await PermissionHandler().requestPermissions([PermissionGroup.storage]);

    pdfBloc.onGetPdf(_job.id);
    Scaffold.of(context).showSnackBar(downloadSnack);
    pdfBloc.state.listen((PdfState state) async {
      if (state.isResult && state.value.last.id == _job.id) {
        final String _basePath = (await (Directory(
                    (await getExternalStorageDirectory()).path + '/Download')
                .create(recursive: true)))
            .path;
        String _path;
        (_job.jobInfo.filename.isEmpty)
            ? _path = _basePath + '/${_job.id}.pdf'
            : _path = _basePath + '/${_job.jobInfo.filename}';
        await File(_path).writeAsBytes(state.value.last.file, flush: true);

        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(doneSnack);
      } else if (state.isException) {
        Scaffold.of(context).showSnackBar(errorSnack);
      }
    });
  }
}
