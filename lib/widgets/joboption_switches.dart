import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Map<int, String> translateNupOrder(NupPageOrder order) {
  switch (order) {
    case NupPageOrder.RIGHTTHENDOWN:
      return {order.index: 'Rechts dann Runter'};
    case NupPageOrder.DOWNTHENRIGHT:
      return {order.index: 'Runter dann Rechts'};
    case NupPageOrder.LEFTTHENDOWN:
      return {order.index: 'Links dann Runter'};
    case NupPageOrder.DOWNTHENLEFT:
      return {order.index: 'Runter dann Links'};
    default:
      return {-1: 'Durcheinander?'};
  }
}

///
/// Switches for setting options on print jobs using BLoCs
///
class JoboptionSwitches extends StatefulWidget {
  final Job _job;

  const JoboptionSwitches(this._job, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _JoboptionSwitchesState(_job);
}

enum OptionType { DUPLEX, COPIES, COLLATE, A3, RANGE, NUP, NUPPAGEORDER, KEEP }

class _JoboptionSwitchesState extends State<JoboptionSwitches> {
  JoblistBloc joblistBloc;
  Job _job;

  String newRange = '';
  int newCopies = 1;

  _JoboptionSwitchesState(this._job);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: joblistBloc,
      builder: (BuildContext context, JoblistState state) {
        if (state.isResult) {
          _job = state.value.singleWhere(
            (Job j) => j.id == _job.id,
            orElse: () => _job,
          );
          return Column(
            children: <Widget>[
              if (_job.jobInfo.colored > 0)
                ListTile(
                  onTap: () {
                    _job.jobOptions.color = !_job.jobOptions.color;
                    joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                  },
                  leading: Icon(Icons.palette),
                  title: Text('Farbe'),
                  trailing: Switch(
                    onChanged: (val) {
                      _job.jobOptions.color = val;
                      joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                    },
                    value: _job.jobOptions.color,
                  ),
                ),
              if (_job.jobInfo.pagecount * _job.jobOptions.copies >= 2)
                Column(
                  children: <Widget>[
                    ListTile(
                      onTap: null,
                      title: Text('Duplex'),
                      trailing: DropdownButton(
                        items: <Map<int, String>>[
                          {0: 'Aus'},
                          {1: 'Lange Kante'},
                          {2: 'Kurze Kante'},
                        ]
                            .map((Map<int, String> duplex) => DropdownMenuItem<int>(
                                  value: duplex.keys.single,
                                  child: Text(duplex.values.single),
                                ))
                            .toList(),
                        value: _job.jobOptions.duplex,
                        onChanged: (val) {
                          _job.jobOptions.duplex = val;
                          joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                        },
                      ),
                    ),
                    Divider(indent: 10.0),
                  ],
                ),
              ListTile(
                onTap: () {
                  _job.jobOptions.a3 = !_job.jobOptions.a3;
                  joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                },
                leading: Icon(Icons.photo_size_select_large),
                title: Text('A3'),
                trailing: Switch(
                  onChanged: (val) {
                    _job.jobOptions.a3 = val;
                    joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                  },
                  value: _job.jobOptions.a3,
                ),
              ),
              Divider(indent: 10.0),
              ListTile(
                onTap: () => showDialog(
                    context: context,
                    builder: (BuildContext context) => _copiesDialog(context, joblistBloc)),
                leading: Icon(Icons.clear_all),
                title: Text('Anzahl Kopien'),
                trailing: Container(
                  width: 100.0,
                  child: Row(
                    children: <Widget>[
                      (_job.jobOptions.copies > 1)
                          ? Expanded(
                              flex: 1,
                              child: IconButton(
                                icon: Icon(Icons.expand_more),
                                onPressed: () {
                                  if (_job.jobOptions.copies > 1) {
                                    _job.jobOptions.copies--;
                                    joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                                  } else
                                    Scaffold.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Nicht weniger als eine Kopie möglich'),
                                      ),
                                    );
                                },
                              ),
                            )
                          : Expanded(
                              flex: 1,
                              child: Text(''),
                            ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          _job.jobOptions.copies.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(Icons.expand_less),
                          onPressed: () {
                            if (_job.jobOptions.copies < 1000) {
                              _job.jobOptions.copies++;
                              joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                            } else
                              Scaffold.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Nicht mehr als 999 Kopien möglich'),
                                ),
                              );
                          },
                        ),
                      ),
                    ].where((widget) => widget != null).toList(),
                  ),
                ),
              ),
              if (_job.jobOptions.copies > 1)
                ListTile(
                  onTap: () {
                    _job.jobOptions.collate = !_job.jobOptions.collate;
                    joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                  },
                  leading: null,
                  title: Text('Gleiche Seiten zusammenstellen'),
                  trailing: Switch(
                    onChanged: (val) {
                      _job.jobOptions.collate = val;
                      joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                    },
                    value: _job.jobOptions.collate,
                  ),
                ),
              Divider(indent: 10.0),
              ListTile(
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => _rangeDialog(context, joblistBloc));
                }, //open text edit
                title: Text('Seitenbereich'),
                trailing: Text(_job.jobOptions.range.isEmpty ? 'Alle' : _job.jobOptions.range),
              ),
              Divider(indent: 10.0),
              if ((_job.jobInfo.pagecount * _job.jobOptions.copies) > 1)
                ListTile(
                  onTap: null,
                  title: Text('Seiten pro Blatt'),
                  trailing: DropdownButton(
                    items: [1, 2, 4]
                        .map(
                          (int value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString()),
                          ),
                        )
                        .toList(),
                    value: _job.jobOptions.nup,
                    onChanged: (val) {
                      _job.jobOptions.nup = val;
                      joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                    },
                  ),
                ),
              if (_job.jobOptions.nup > 2)
                ListTile(
                  onTap: null,
                  title: Text('Reihenfolge auf Blatt'),
                  trailing: DropdownButton(
                    items: <Map<int, String>>[
                      translateNupOrder(NupPageOrder.RIGHTTHENDOWN),
                      translateNupOrder(NupPageOrder.DOWNTHENRIGHT),
                      translateNupOrder(NupPageOrder.LEFTTHENDOWN),
                      translateNupOrder(NupPageOrder.DOWNTHENLEFT),
                    ]
                        .map(
                          (Map<int, String> order) => DropdownMenuItem<int>(
                            value: order.keys.single,
                            child: Text(order.values.single),
                          ),
                        )
                        .toList(),
                    value: _job.jobOptions.nupPageOrder,
                    onChanged: (val) {
                      _job.jobOptions.nupPageOrder = val;
                      joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                    },
                  ),
                ),
            ],
          );
        } else if (state.isException) {
          if ((state.error as ApiException).statusCode == 400) {
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Der angegebene Seitenbereich ist falsch formatiert oder liegt außerhalb des Seitenbereichs'),
              duration: Duration(seconds: 2),
            ))
              ..closed.then((_) => joblistBloc.onRefresh());
          }
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void initState() {
    joblistBloc = BlocProvider.of<JoblistBloc>(context);
    super.initState();
  }

  Dialog _copiesDialog(BuildContext context, JoblistBloc joblistBloc) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Kopien einstellen',
                  textScaleFactor: 1.2,
                  textAlign: TextAlign.start,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    TextField(
                      controller: TextEditingController(text: _job.jobOptions.copies.toString()),
                      decoration: InputDecoration(labelText: 'z.B. "4"'),
                      autofocus: true,
                      autocorrect: false,
                      onChanged: (String text) {
                        try {
                          newCopies = int.parse(text);
                        } catch (e) {
                          Scaffold.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Fehler beim Lesen der angebenen Kopien. Die Anzahl der Kopien sollte eine Zahl sein.'),
                            duration: const Duration(seconds: 3),
                          ));
                        }
                      },
                    ),
                    MaterialButton(
                      textColor: Colors.black87,
                      child: Text('Okay'),
                      onPressed: () {
                        _job.jobOptions.copies = newCopies;
                        joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Dialog _rangeDialog(BuildContext context, JoblistBloc joblistBloc) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Seitenbereich einstellen',
                  textScaleFactor: 1.2,
                  textAlign: TextAlign.start,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    TextField(
                      controller: TextEditingController(text: _job.jobOptions.range),
                      decoration: InputDecoration(labelText: 'z.B. "1,4-7,10"'),
                      autofocus: true,
                      autocorrect: false,
                      onChanged: (String text) => newRange = text,
                    ),
                    MaterialButton(
                      textColor: Colors.black87,
                      child: Text('Okay'),
                      onPressed: () {
                        _job.jobOptions.range = newRange;
                        joblistBloc.onUpdateOptionsById(_job.id, _job.jobOptions);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
