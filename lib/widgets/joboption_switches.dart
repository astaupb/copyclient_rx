import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  Job job;

  FocusNode rangeFocus = FocusNode();
  TextEditingController rangeController;
  String newRange = '';

  _JoboptionSwitchesState(this.job);

  @override
  Widget build(BuildContext context) {
    final JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    rangeController = TextEditingController(text: job.jobOptions.range)
      ..addListener(() => newRange = rangeController.text);
    return Column(
      children: <Widget>[
        (job.jobInfo.colored > 0)
            ? ListTile(
                onTap: () {
                  job.jobOptions.color = !job.jobOptions.color;
                  joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
                },
                leading: Icon(Icons.palette),
                title: Text('Farbe'),
                trailing: Switch(
                  onChanged: (val) {
                    job.jobOptions.color = val;
                    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
                  },
                  value: job.jobOptions.color,
                ),
              )
            : null,
        (job.jobInfo.pagecount * job.jobOptions.copies < 2)
            ? null
            : Column(
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
                          .map((Map<int, String> duplex) =>
                              DropdownMenuItem<int>(
                                value: duplex.keys.single,
                                child: Text(duplex.values.single),
                              ))
                          .toList(),
                      value: job.jobOptions.duplex,
                      onChanged: (val) {
                        job.jobOptions.duplex = val;
                        joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
                      },
                    ),
                  ),
                  Divider(indent: 10.0),
                ],
              ),
        ListTile(
          onTap: () {
            job.jobOptions.a3 = !job.jobOptions.a3;
            joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
          },
          leading: Icon(Icons.photo_size_select_large),
          title: Text('A3'),
          trailing: Switch(
            onChanged: (val) {
              job.jobOptions.a3 = val;
              joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
            },
            value: job.jobOptions.a3,
          ),
        ),
        Divider(indent: 10.0),
        ListTile(
          onTap: null,
          leading: Icon(Icons.clear_all),
          title: Text('Anzahl Kopien'),
          trailing: Container(
            width: 100.0,
            child: Row(
              children: <Widget>[
                (job.jobOptions.copies > 1)
                    ? Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(Icons.expand_more),
                          onPressed: () {
                            if (job.jobOptions.copies > 1) {
                              job.jobOptions.copies--;
                              joblistBloc.onUpdateOptionsById(
                                  job.id, job.jobOptions);
                            } else
                              Scaffold.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Nicht weniger als eine Kopie möglich'),
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
                    job.jobOptions.copies.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: IconButton(
                    icon: Icon(Icons.expand_less),
                    onPressed: () {
                      if (job.jobOptions.copies < 1000) {
                        job.jobOptions.copies++;
                        joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
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
        (job.jobOptions.copies > 1)
            ? ListTile(
                onTap: () {
                  job.jobOptions.collate = !job.jobOptions.collate;
                  joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
                },
                leading: null,
                title: Text('Gleiche Seiten zusammenstellen'),
                trailing: Switch(
                  onChanged: (val) {
                    job.jobOptions.collate = val;
                    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
                  },
                  value: job.jobOptions.collate,
                ),
              )
            : null,
        ListTile(
          onTap: () =>
              FocusScope.of(context).requestFocus(rangeFocus), //open text edit
          title: Text('Seitenbereich'),
          trailing: Container(
            width: 180.0,
            child: TextFormField(
              focusNode: rangeFocus,
              autocorrect: false,
              controller: rangeController,
              onEditingComplete: () => joblistBloc.onUpdateOptionsById(
                  job.id, job.jobOptions..range = newRange),
              onFieldSubmitted: (val) => joblistBloc.onUpdateOptionsById(
                  job.id, job.jobOptions..range = val),
            ),
          ),
        ),
        Divider(indent: 10.0),
        ((job.jobInfo.pagecount * job.jobOptions.copies) > 1)
            ? ListTile(
                onTap: null,
                title: Text('Seiten pro Blatt'),
                trailing: DropdownButton(
                  items: (((job.jobInfo.pagecount * job.jobOptions.copies) > 2)
                          ? [1, 2, 4]
                          : [1, 2])
                      .map(
                        (int value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            ),
                      )
                      .toList(),
                  value: job.jobOptions.nup,
                  onChanged: (val) {
                    job.jobOptions.nup = val;
                    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
                  },
                ),
              )
            : null,
        (job.jobOptions.nup > 2)
            ? ListTile(
                onTap: null,
                title: Text('Reihenfolge auf Blatt'),
                trailing: DropdownButton(
                  items: <Map<int, String>>[
                    _translateNupOrder(NupPageOrder.RIGHTTHENDOWN),
                    _translateNupOrder(NupPageOrder.DOWNTHENRIGHT),
                    _translateNupOrder(NupPageOrder.LEFTTHENDOWN),
                    _translateNupOrder(NupPageOrder.DOWNTHENLEFT),
                  ]
                      .map(
                        (Map<int, String> order) => DropdownMenuItem<int>(
                              value: order.keys.single,
                              child: Text(order.values.single),
                            ),
                      )
                      .toList(),
                  value: job.jobOptions.nupPageOrder,
                  onChanged: (val) {
                    job.jobOptions.nupPageOrder = val;
                    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
                  },
                ),
              )
            : null,
      ].where((widget) => widget != null).toList(),
    );
  }

  Map<int, String> _translateNupOrder(NupPageOrder order) {
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
}
