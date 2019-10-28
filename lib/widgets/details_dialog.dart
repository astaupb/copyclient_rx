import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///
/// A Dialog showing more raw info on the job as seen by the server.
/// Should also give a nice overview of all the features of the document.
///
class DetailsDialog extends SimpleDialog {
  static TextStyle descTextStyle = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
    letterSpacing: 0.5,
    fontSize: 18.0,
    height: 1.0,
  );

  final Job _job;

  DetailsDialog(this._job);

  @override
  List<Widget> get children => <Widget>[
        DefaultTextStyle.merge(
          style: descTextStyle,
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text('ID:'),
                subtitle: Text(_job.id.toString()),
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: _job.id.toString()));
                }, //copy,
              ),
              ListTile(
                title: Text('Zeitstempel:'),
                subtitle: Text(_job.timestamp.toString()),
                onLongPress: () {
                  Clipboard.setData(
                      ClipboardData(text: _job.timestamp.toString()));
                },
              ),
              Divider(),
              Text(
                'Beim Upload erkannt:',
              ),
            ],
          ),
        ),
        DefaultTextStyle.merge(
          style: descTextStyle,
          child: Container(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.photo_size_select_large),
                          Text('A3:'),
                          Text(_job.jobInfo.a3 ? 'Ja' : 'Nein'),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.color_lens),
                          Text('Farbseiten:'),
                          Text(
                            _job.jobInfo.colored.toString(),
                            textScaleFactor: 0.9,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Column(
                        children: [
                          Icon(Icons.filter_none),
                          Text('Seiten:'),
                          Text(_job.jobInfo.pagecount.toString()),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.landscape),
                          Text('Querformat:'),
                          Text(_job.jobInfo.landscape ? 'Ja' : 'Nein'),
                        ],
                      ),
                    ],
                  )
                ],
              )),
        )
      ];

  @override
  Widget get title => const Text('Mehr Infos');
}
