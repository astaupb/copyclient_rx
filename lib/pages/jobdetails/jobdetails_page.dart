import 'dart:async';
import 'dart:io';

import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../blocs/theme_bloc.dart';
import '../../widgets/details_dialog.dart';
import '../../widgets/joboption_switches.dart';
import '../../widgets/preview_grid.dart';
import 'header_tile.dart';
import 'job_deletion_modal.dart';

enum PopupMenuEntry { delete, info, copy, copyImage }

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
        title: Text('Jobdetails'),
        actions: <Widget>[
          if (!kIsWeb)
            Builder(
              builder: (BuildContext context) => IconButton(
                icon: Icon(Icons.share),
                tooltip: 'Job teilen',
                onPressed: () => (Platform.isIOS) ? _onShare(context) : _onShowShare(context),
              ),
            ),
          PopupMenuButton<PopupMenuEntry>(
            onSelected: _onPopupButtonSelected,
            icon: Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<PopupMenuEntry>(
                child: Row(children: [
                  Icon(
                    Icons.delete,
                    color:
                        (BlocProvider.of<ThemeBloc>(context).state.id == CopyclientTheme.copyshop)
                            ? Colors.grey[800]
                            : null,
                  ),
                  Text(' Job löschen')
                ]),
                value: PopupMenuEntry.delete,
              ),
              PopupMenuItem<PopupMenuEntry>(
                child: Row(children: [
                  Icon(
                    Icons.info,
                    color:
                        (BlocProvider.of<ThemeBloc>(context).state.id == CopyclientTheme.copyshop)
                            ? Colors.grey[800]
                            : null,
                  ),
                  Text(' Details anzeigen')
                ]),
                value: PopupMenuEntry.info,
              ),
              PopupMenuItem<PopupMenuEntry>(
                child: Row(children: [
                  Icon(
                    Icons.content_copy,
                    color:
                        (BlocProvider.of<ThemeBloc>(context).state.id == CopyclientTheme.copyshop)
                            ? Colors.grey[800]
                            : null,
                  ),
                  Text(' Job duplizieren')
                ]),
                value: PopupMenuEntry.copy,
              ),
              PopupMenuItem<PopupMenuEntry>(
                child: Row(children: [
                  Icon(
                    Icons.photo_library,
                    color:
                        (BlocProvider.of<ThemeBloc>(context).state.id == CopyclientTheme.copyshop)
                            ? Colors.grey[800]
                            : null,
                  ),
                  Text(' Job als Bild duplizieren')
                ]),
                value: PopupMenuEntry.copyImage,
              ),
            ],
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
    const doneSnack = SnackBar(
      duration: Duration(seconds: 1),
      content: Text('PDF unter Downloads gespeichert'),
    );
    const errorSnack = SnackBar(
      duration: Duration(seconds: 1),
      content: Text('Fehler beim Download der PDF'),
    );
    const downloadSnack = SnackBar(
      duration: Duration(seconds: 30),
      content: Text('Lade PDF...'),
    );

    await PermissionHandler().shouldShowRequestPermissionRationale(PermissionGroup.storage);
    await PermissionHandler().requestPermissions([PermissionGroup.storage]);

    Scaffold.of(context).showSnackBar(downloadSnack);
    BlocProvider.of<PdfBloc>(context).listen((PdfState state) async {
      if (state.isResult && state.value.last.id == widget._job.id) {
        String downloadPath;
        try {
          downloadPath = await _mChannel.invokeMethod('getDownloadsDirectory');
          print(downloadPath);
        } catch (e) {
          print(e.toString());
        }
        final _basePath = (await Directory(downloadPath).create()).path;
        String _path;
        if (widget._job.jobInfo.filename.isEmpty) {
          _path = _basePath + '/${widget._job.id}.pdf';
        } else {
          if (widget._job.jobInfo.filename.endsWith('.pdf')) {
            _path = _basePath + '/${widget._job.jobInfo.filename}';
          } else {
            _path = _basePath + '/${widget._job.jobInfo.filename}.pdf';
          }
        }
        await File(_path).writeAsBytes(state.value.last.file, flush: true);

        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(doneSnack);
      } else if (state.isException) {
        Scaffold.of(context).showSnackBar(errorSnack);
      }
    });

    BlocProvider.of<PdfBloc>(context).onGetPdf(widget._job.id);
  }

  void _onShare(BuildContext context) {
    StreamSubscription listen;
    listen = BlocProvider.of<PdfBloc>(context).listen((PdfState state) async {
      if (state.isResult && state.value.last.id == widget._job.id) {
        //Navigator.of(context).pop();
        final pdf = state.value.last;
        await Share.file(
            'Copyclient Download',
            (widget._job.jobInfo.filename == '')
                ? 'DOC_${DateTime.now().toString()}.pdf'
                : (widget._job.jobInfo.filename.endsWith('.pdf'))
                    ? widget._job.jobInfo.filename
                    : '${widget._job.jobInfo.filename}.pdf',
            pdf.file,
            'application/pdf');
        await listen.cancel();
      }
    });
    BlocProvider.of<PdfBloc>(context).onGetPdf(widget._job.id);
  }

  void _onShowShare(BuildContext scaffoldContext) async {
    await showModalBottomSheet<Padding>(
      context: scaffoldContext,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              if (!kIsWeb && !Platform.isIOS)
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

  void _onPopupButtonSelected(PopupMenuEntry value) async {
    switch (value) {
      case PopupMenuEntry.delete:
        await showModalBottomSheet<JobDeletionModal>(
          context: context,
          builder: (BuildContext context) {
            return JobDeletionModal(widget._job.id);
          },
        );
        break;
      case PopupMenuEntry.info:
        await showDialog<DetailsDialog>(
          context: context,
          builder: (context) => DetailsDialog(widget._job),
        );
        break;
      case PopupMenuEntry.copy:
        BlocProvider.of<JoblistBloc>(context).onCopyById(widget._job.id, false);
        await Future<void>.delayed(const Duration(seconds: 1));
        BlocProvider.of<UploadBloc>(context).onRefresh();
        BlocProvider.of<JoblistBloc>(context).onRefresh();
        Navigator.of(context).pop();
        break;
      case PopupMenuEntry.copyImage:
        BlocProvider.of<JoblistBloc>(context).onCopyById(widget._job.id, true);
        await Future<void>.delayed(const Duration(seconds: 1));
        BlocProvider.of<UploadBloc>(context).onRefresh();
        BlocProvider.of<JoblistBloc>(context).onRefresh();
        Navigator.of(context).pop();
        break;
      default:
    }
  }
}
