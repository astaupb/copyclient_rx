import 'package:blocs_copyclient/joblist.dart' show JobOptions, NupPageOrder;
import 'package:blocs_copyclient/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../widgets/joboption_switches.dart';

class DefaultOptionsDialog extends StatefulWidget {
  final UserBloc userBloc;

  DefaultOptionsDialog({Key key, this.userBloc}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DefaultOptionsDialogState();
}

class _DefaultOptionsDialogState extends State<DefaultOptionsDialog> {
  JobOptions jobOptions = JobOptions();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserEvent, UserState>(
      bloc: widget.userBloc,
      builder: (BuildContext context, UserState state) {
        if (state.isResult && state.value.options != null) {
          jobOptions = state.value.options;
          return SimpleDialog(
            title: Text('Standard-Joboptionen festlegen'),
            contentPadding: EdgeInsets.all(16.0),
            children: <Widget>[
              ListTile(
                onTap: () {
                  setState(() => jobOptions.color = !jobOptions.color);
                },
                leading: Icon(Icons.palette),
                title: Text('Farbe'),
                trailing: Switch(
                  onChanged: (val) {
                    jobOptions.color = val;
                  },
                  value: jobOptions.color,
                ),
              ),
              Divider(indent: 10.0),
              Column(
                children: <Widget>[
                  ListTile(
                    title: Text('Duplex'),
                    trailing: DropdownButton(
                      items: <Map<int, String>>[
                        {0: 'Aus'},
                        {1: 'Lange Kante'},
                        {2: 'Kurze Kante'},
                      ]
                          .map(
                            (Map<int, String> duplex) => DropdownMenuItem<int>(
                                  value: duplex.keys.single,
                                  child: Text(duplex.values.single),
                                ),
                          )
                          .toList(),
                      value: jobOptions.duplex,
                      onChanged: (val) {
                        setState(() => jobOptions.duplex = val);
                      },
                    ),
                  ),
                  Divider(indent: 10.0),
                ],
              ),
              ListTile(
                onTap: () {
                  setState(() => jobOptions.a3 = !jobOptions.a3);
                },
                leading: Icon(Icons.photo_size_select_large),
                title: Text('A3'),
                trailing: Switch(
                  onChanged: (val) {
                    jobOptions.a3 = val;
                  },
                  value: jobOptions.a3,
                ),
              ),
              Divider(indent: 10.0),
              ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Anzahl Kopien'),
                trailing: Container(
                  width: 100.0,
                  child: TextField(
                    controller: TextEditingController(text: jobOptions.copies.toString()),
                    autocorrect: false,
                    keyboardType: TextInputType.numberWithOptions(),
                    onChanged: (String input) => jobOptions.copies = int.tryParse(input),
                  ),
                ),
              ),
              ListTile(
                onTap: () {
                  setState(() => jobOptions.collate = !jobOptions.collate);
                },
                title: Text('Gleiche Seiten zusammenstellen'),
                trailing: Switch(
                  onChanged: (val) {
                    jobOptions.collate = val;
                  },
                  value: jobOptions.collate,
                ),
              ),
              Divider(indent: 10.0),
              ListTile(
                title: Text('Seitenbereich'),
                trailing: Container(
                  width: 128.0,
                  child: TextField(
                    controller: TextEditingController(text: jobOptions.range),
                    autocorrect: false,
                    keyboardType: TextInputType.numberWithOptions(),
                    onChanged: (String input) => jobOptions.range = input,
                  ),
                ),
              ),
              Divider(indent: 10.0),
              ListTile(
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
                  value: jobOptions.nup,
                  onChanged: (val) {
                    setState(() => jobOptions.nup = val);
                  },
                ),
              ),
              ListTile(
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
                  value: jobOptions.nupPageOrder,
                  onChanged: (val) {
                    setState(() => jobOptions.nupPageOrder = val);
                  },
                ),
              ),
              Row(
                children: <Widget>[
                  RaisedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Abbrechen'),
                  ),
                  Spacer(),
                  RaisedButton(
                    onPressed: _onSubmit,
                    child: Text('Speichern'),
                  ),
                ],
              ),
            ],
          );
        } else
          return Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  void initState() {
    widget.userBloc.onGetOptions();
    super.initState();
  }

  void _onSubmit() {
    widget.userBloc.onChangeOptions(jobOptions);

    Navigator.of(context).pop();
  }
}
