import 'dart:async';
import 'dart:io';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
class JobdetailsPage extends StatefulWidget {
  final Job _job;

  JobdetailsPage(this._job);

  @override
  _JobdetailsPageState createState() => _JobdetailsPageState();
}

class _JobdetailsPageState extends State<JobdetailsPage> {
  static const MethodChannel _mChannel = MethodChannel('de.upb.copyclient/download_path');

  @override
  Widget build(BuildContext context) {
    //final JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            (widget._job.jobInfo.filename.isEmpty) ? 'Ohne Titel' : widget._job.jobInfo.filename),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return JobDeletionModal(widget._job.id);
                }),
          ),
          Builder(
            builder: (BuildContext context) => IconButton(
              icon: Icon(Icons.share),
              onPressed: () => (Platform.isIOS) ? _onShare(context) : _onShowShare(context),
            ),
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => DetailsDialog(widget._job),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          PreviewGrid(widget._job),
          Card(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: HeaderTile(widget._job),
            ),
          ),
          Card(
            child: JoboptionSwitches(widget._job),
          ),
        ],
      ),
    );
  }

  Future<void> _onPdfDownload(BuildContext context) async {
    const SnackBar doneSnack = SnackBar(
      duration: Duration(seconds: 1),
      content: Text('PDF unter Downloads gespeichert'),
    );
    const SnackBar errorSnack = SnackBar(
      duration: Duration(seconds: 1),
      content: Text('Fehler beim Download der PDF'),
    );
    const SnackBar downloadSnack = SnackBar(
      duration: Duration(seconds: 30),
      content: Text('Lade PDF...'),
    );
    PdfBloc pdfBloc = BlocProvider.of<PdfBloc>(context);

    await PermissionHandler().shouldShowRequestPermissionRationale(PermissionGroup.storage);
    await PermissionHandler().requestPermissions([PermissionGroup.storage]);

    pdfBloc.onGetPdf(widget._job.id);
    Scaffold.of(context).showSnackBar(downloadSnack);
    pdfBloc.state.listen((PdfState state) async {
      if (state.isResult && state.value.last.id == widget._job.id) {
        String downloadPath;
        try {
          downloadPath = await _mChannel.invokeMethod('getDownloadsDirectory');
          print(downloadPath);
        } catch (e) {
          print(e.toString());
        }
        final String _basePath = (await Directory(downloadPath).create()).path;
        String _path;
        (widget._job.jobInfo.filename.isEmpty)
            ? _path = _basePath + '/${widget._job.id}.pdf'
            : _path = _basePath + '/${widget._job.jobInfo.filename}';
        await File(_path).writeAsBytes(state.value.last.file, flush: true);

        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(doneSnack);
      } else if (state.isException) {
        Scaffold.of(context).showSnackBar(errorSnack);
      }
    });
  }

  void _onShare(BuildContext context) {
    PdfBloc pdfBloc = BlocProvider.of<PdfBloc>(context);
    StreamSubscription listen;
    listen = pdfBloc.state.listen((PdfState state) async {
      if (state.isResult && state.value.last.id == widget._job.id) {
        //Navigator.of(context).pop();
        final PdfFile pdf = state.value.last;
        await Share.file(
            'Copyclient Download',
            (widget._job.jobInfo.filename == '')
                ? 'DOC_${DateTime.now().toString()}.pdf'
                : widget._job.jobInfo.filename,
            pdf.file,
            'application/pdf');
        listen.cancel();
      }
    });
    pdfBloc.onGetPdf(widget._job.id);
  }

  void _onShowShare(BuildContext scaffoldContext) async {
    await showModalBottomSheet(
      context: scaffoldContext,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              if (!Platform.isIOS)
                RaisedButton(
                  child: Row(children: <Widget>[
                    Icon(Icons.file_download),
                    Text('Download'),
                  ]),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _onPdfDownload(scaffoldContext);
                  },
                ),
              RaisedButton(
                child: Row(children: <Widget>[
                  Icon(Icons.share),
                  Text('Teilen'),
                ]),
                onPressed: () => _onShare(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
