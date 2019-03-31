import 'dart:async';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/print_queue.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:bubble_bottom_bar/bubble_bottom_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/drawer/drawer.dart';
import '../../widgets/exit_app_alert.dart';
import '../jobdetails/jobdetails.dart';
import 'joblist_tile.dart';

class JoblistPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _JoblistPageState();
}

class _JoblistPageState extends State<JoblistPage> {
  PrintQueueBloc printQueueBloc;

  Timer printerLockRefresher;
  Timer jobTimer;
  StreamSubscription jobListener;

  BuildContext _scaffoldContext;
  String text = '';
  bool newException = true;

  StreamSubscription copyListener;
  DateTime copyStartTime;

  List<Job> pastJobs = [];

  int lastCredit;

  int currentIndex = 0;
  int remainingLockTime = 0;
  String lockedPrinter;

  bool selectableTiles = false;
  List<int> selectedIds = [];

  @override
  Widget build(BuildContext context) {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    jobListener = joblistBloc.state.listen((JoblistState state) {
      if (state.isException) {
        joblistBloc.onRefresh();
        ApiException error = (state.error as ApiException);

        if (error.statusCode == 401) {
          BlocProvider.of<AuthBloc>(context).logout();
          Navigator.pop(context);
        } else if (error.statusCode == 423) {
          text =
              'Dieser Drucker ist gerade von jemand Anderem in Benutzung. Falls das nicht so aussieht wende dich bitte ans Personal.';
        } else if (error.statusCode >= 500) {
          text = 'Serverfehler (${error.statusCode}) - Bitte in ein paar Sekunden aktualisieren';
        } else {
          text = error.toString();
        }
        currentIndex = 0;
        if (newException)
          Scaffold.of(_scaffoldContext)
              .showSnackBar(SnackBar(duration: Duration(seconds: 3), content: Text(text)));
        newException = false;
      } else if (state.isResult) {
        newException = true;
      }
    });
    return WillPopScope(
      onWillPop: () => _onWillPop(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Jobliste'),
          actions: (selectableTiles)
              ? <Widget>[
                  Builder(
                    builder: (BuildContext context) => IconButton(
                          tooltip: 'Ausgewählte drucken',
                          icon: Icon(Icons.print),
                          onPressed: () async {
                            if (selectedIds.length > 0) {
                              String target;
                              try {
                                target = await BarcodeScanner.scan();
                                for (int id in selectedIds) {
                                  joblistBloc.onPrintById(target, id);
                                }
                                Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text('Ausgewählte Jobs wurden abgeschickt'),
                                  duration: Duration(seconds: 1),
                                ));
                                selectedIds.clear();
                                setState(() => selectableTiles = false);
                              } catch (e) {
                                Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text('Kein Drucker ausgewählt'),
                                  duration: Duration(seconds: 1),
                                ));
                              }
                            } else {
                              Scaffold.of(context).showSnackBar(SnackBar(
                                content: Text('Keine Jobs ausgewählt'),
                                duration: Duration(seconds: 1),
                              ));
                            }
                          },
                        ),
                  ),
                  BlocBuilder<JoblistEvent, JoblistState>(
                    bloc: joblistBloc,
                    builder: (BuildContext context, JoblistState state) => (state.isResult)
                        ? IconButton(
                            tooltip: 'Alle auswählen',
                            icon: Icon(Icons.select_all),
                            onPressed: () {
                              if (state.value.length == selectedIds.length) {
                                setState(() => selectedIds.clear());
                              } else {
                                List<int> allIds = [];
                                for (Job job in state.value) allIds.add(job.id);
                                selectedIds.clear();
                                setState(() => selectedIds.addAll(allIds));
                              }
                            },
                          )
                        : IconButton(
                            tooltip: 'Alle auswählen',
                            icon: Icon(Icons.select_all),
                            onPressed: () => null,
                          ),
                  ),
                  IconButton(
                    tooltip: 'Mehrfachauswahl beenden',
                    icon: Icon(Icons.clear),
                    onPressed: () => setState(
                          () {
                            selectedIds = [];
                            selectableTiles = false;
                          },
                        ),
                  ),
                ]
              : <Widget>[
                  MaterialButton(
                    child: BlocBuilder<UserEvent, UserState>(
                      bloc: BlocProvider.of<UserBloc>(context),
                      builder: (BuildContext context, UserState state) {
                        if (state.isResult) {
                          lastCredit = state.value.credit;
                          return Text('${(state.value.credit / 100).toStringAsFixed(2)} €');
                        } else
                          return Text('${((lastCredit ?? 0) / 100.0).toStringAsFixed(2)} €');
                      },
                    ),
                    onPressed: () => Navigator.of(context).pushNamed('/transactions'),
                  ),
                  IconButton(
                    tooltip: 'Mehrfachauswahl aktivieren',
                    icon: Icon(Icons.select_all),
                    onPressed: () => setState(() => selectableTiles = true),
                  ),
                  IconButton(
                    tooltip: 'Dokument hochladen',
                    icon: Icon(Icons.note_add),
                    onPressed: () => _onSelectedUpload(),
                  ),
                ],
        ),
        drawer: MainDrawer(),
        body: RefreshIndicator(
          onRefresh: () => _onRefresh(),
          child: BlocBuilder<JoblistEvent, JoblistState>(
            bloc: joblistBloc,
            builder: (BuildContext context, JoblistState state) {
              _scaffoldContext = context;
              if (state.isResult) {
                pastJobs = state.value.reversed.toList();
                if (state.value.length == 0) {
                  return ListView(
                    children: <Widget>[
                      ListTile(
                        title: Text('''
Die Jobliste ist aktuell leer. 
Oben rechts kannst du neue Dokumente hochladen.
                    '''),
                      )
                    ],
                  );
                } else {
                  final reverseList = state.value.reversed.toList();
                  return ListView.builder(
                    itemExtent: 72.0,
                    itemCount: reverseList.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (reverseList[index] != null)
                        return Column(
                          children: <Widget>[
                            Dismissible(
                              key: Key(reverseList[index].id.toString()),
                              onDismissed: (DismissDirection direction) =>
                                  _onTileDismissed(context, reverseList[index].id),
                              background: _dismissableBackground(),
                              confirmDismiss: (DismissDirection direction) =>
                                  _onConfirmDismiss(context, direction),
                              child: Container(
                                color: (selectableTiles)
                                    ? (selectedIds.contains(reverseList[index].id))
                                        ? Colors.black12
                                        : null
                                    : null,
                                child: ListTileTheme(
                                  selectedColor: Colors.black,
                                  child: JoblistTile(
                                    context,
                                    index,
                                    reverseList[index],
                                    onPress: (int index) {
                                      if (selectableTiles) {
                                        setState(() {
                                          if (selectedIds.contains(reverseList[index].id))
                                            selectedIds.remove(reverseList[index].id);
                                          else
                                            selectedIds.add(reverseList[index].id);
                                        });
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                JobdetailsPage(reverseList[index]),
                                          ),
                                        );
                                      }
                                    },
                                    onLongTap: (int index) => _onLongTapped(context,
                                        reverseList[index].id, reverseList[index].jobOptions),
                                    directPrinter: lockedPrinter,
                                    onPressPrint: () async {
                                      if (!selectableTiles) {
                                        try {
                                          String target = await BarcodeScanner.scan();
                                          BlocProvider.of<JoblistBloc>(context).onPrintById(
                                              (lockedPrinter == null) ? target : lockedPrinter,
                                              reverseList[index].id);
                                          Scaffold.of(context).showSnackBar(SnackBar(
                                            content: Text(
                                                '${reverseList[index].jobInfo.filename} wurde abgeschickt'),
                                            duration: Duration(seconds: 1),
                                          ));
                                        } catch (e) {
                                          Scaffold.of(context).showSnackBar(SnackBar(
                                            content: Text('Kein Drucker ausgewählt'),
                                            duration: Duration(seconds: 1),
                                          ));
                                        }
                                      } else {
                                        setState(() {
                                          if (selectedIds.contains(reverseList[index].id))
                                            selectedIds.remove(reverseList[index].id);
                                          else
                                            selectedIds.add(reverseList[index].id);
                                        });
                                      }
                                    },
                                    chosen: selectedIds.contains(reverseList[index].id),
                                  ),
                                ),
                              ),
                            ),
                            Divider(height: 0.0),
                          ],
                        );
                    },
                  );
                }
              } else {
                return ListView.builder(
                  itemCount: pastJobs.length,
                  itemExtent: 72.0,
                  itemBuilder: (BuildContext context, int index) {
                    return JoblistTile(context, index, pastJobs[index]);
                  },
                );
              }
            },
          ),
        ),
        bottomNavigationBar: Builder(
          builder: (BuildContext context) => BubbleBottomBar(
                opacity: .2,
                currentIndex: currentIndex,
                onTap: (int index) => _changePage(context, index),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                elevation: 8,
                items: <BubbleBottomBarItem>[
                  BubbleBottomBarItem(
                    backgroundColor: Colors.red,
                    icon: Icon(
                      Icons.cancel,
                      color: Colors.black,
                    ),
                    activeIcon: Icon(
                      Icons.list,
                      color: Colors.red,
                    ),
                    title: Text("Liste"),
                  ),
                  BubbleBottomBarItem(
                    backgroundColor: Colors.deepPurple,
                    icon: Column(
                      children: <Widget>[
                        Icon(
                          Icons.scanner,
                          size: 16.0,
                          color: Colors.black,
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16.0,
                          color: Colors.black,
                        ),
                        Icon(
                          Icons.picture_as_pdf,
                          size: 16.0,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    activeIcon: Row(
                      children: <Widget>[
                        Icon(
                          Icons.scanner,
                          color: Colors.black,
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 16.0,
                          color: Colors.black,
                        ),
                        Icon(
                          Icons.picture_as_pdf,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    title: Text("Scanner"),
                  ),
                  BubbleBottomBarItem(
                    backgroundColor: Colors.indigo,
                    icon: Column(
                      children: <Widget>[
                        Icon(
                          Icons.scanner,
                          size: 16.0,
                          color: Colors.black,
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16.0,
                          color: Colors.black,
                        ),
                        Icon(
                          Icons.print,
                          size: 16.0,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    activeIcon: Row(
                      children: <Widget>[
                        Icon(
                          Icons.scanner,
                          color: Colors.black,
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 16.0,
                          color: Colors.black,
                        ),
                        Icon(
                          Icons.print,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    title: Text("Kopierer"),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  @override
  void deactivate() {
    _cancelTimers();
    if (lockedPrinter != null) _unlockPrinter();
    if (copyListener != null) copyListener.cancel();
    currentIndex = 0;
    super.deactivate();
  }

  @override
  void dispose() {
    _cancelTimers();
    if (lockedPrinter != null) _unlockPrinter();
    if (copyListener != null) copyListener.cancel();
    currentIndex = 0;
    super.dispose();
  }

  @override
  void initState() {
    currentIndex = 0;
    _cancelTimers();
    super.initState();
  }

  void _cancelTimers() {
    if (printerLockRefresher != null) printerLockRefresher.cancel();
    if (jobTimer != null) jobTimer.cancel();
  }

  void _changePage(BuildContext context, int index) async {
    // TODO: load dispatcher queue
    if (copyListener != null) copyListener.cancel();
    setState(() {
      currentIndex = index;
    });
    if (currentIndex == 1) {
      int dialogResult = await showDialog<int>(
        context: context,
        builder: (BuildContext context) => Dialog(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                        'Wähle als nächstes per QR Code am Druckerbildschirm das Gerät aus mit dem du scannen willst.'),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        MaterialButton(
                          textColor: Colors.black87,
                          child: Text('Abbrechen'),
                          onPressed: () => Navigator.pop<int>(context, 1),
                        ),
                        MaterialButton(
                          textColor: Colors.black87,
                          child: Text('Okay'),
                          onPressed: () => Navigator.pop<int>(context, 0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      );
      if (dialogResult == 0) {
        _lockPrinter();
      } else {
        setState(() => currentIndex = 0);
      }
    } else if (currentIndex == 2) {
      //  TODO: handle copying
      int dialogResult = await showDialog<int>(
        context: context,
        builder: (BuildContext context) => Dialog(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                        'Wähle als nächstes per QR Code am Druckerbildschirm das Gerät aus mit dem du kopieren willst.\n\nAchtung: Gescannte Dokumente werden sofort in Schwarz Weiß ausgedruckt'),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        MaterialButton(
                          textColor: Colors.black87,
                          child: Text('Abbrechen'),
                          onPressed: () => Navigator.pop<int>(context, 1),
                        ),
                        MaterialButton(
                          textColor: Colors.black87,
                          child: Text('Okay'),
                          onPressed: () => Navigator.pop<int>(context, 0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      );
      if (dialogResult == 0) {
        JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
        _lockPrinter();
        copyStartTime = DateTime.now();
        copyListener = joblistBloc.state.listen(
          (JoblistState state) {
            if (state.isResult) {
              for (Job job in state.value.where(
                  (Job job) => (job.timestamp * 1000) > copyStartTime.millisecondsSinceEpoch)) {
                joblistBloc.onPrintById(lockedPrinter, job.id);
                //joblistBloc.onDeleteById(job.id);
                copyStartTime = DateTime.now();
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    duration: Duration(seconds: 2),
                    content: Text('${job.jobInfo.filename} wird kopiert...'),
                  ),
                );
              }
            }
          },
        );
      } else {
        setState(() => currentIndex = 0);
      }
    } else {
      _cancelTimers();
      remainingLockTime = 0;
      _unlockPrinter();
    }
  }

  Container _dismissableBackground() => Container(
        color: Colors.redAccent,
        child: Row(
          children: <Widget>[
            Text('Job löschen', style: TextStyle(color: Colors.white)),
            Spacer(),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
        padding: EdgeInsets.all(20.0),
      );

  Future<String> _getFilePath() async {
    String filePath;
    try {
      filePath = await FilePicker.getFilePath(type: FileType.CUSTOM, fileExtension: 'pdf');
      if (filePath != '') return filePath;
    } catch (e) {
      print("Error while picking the file: " + e.toString());
    }
    return '';
  }

  void _lockPrinter() async {
    printQueueBloc = BlocProvider.of<PrintQueueBloc>(context);
    String target;
    if (lockedPrinter == null) {
      try {
        //target = "44332";
        target = await BarcodeScanner.scan();
      } catch (e) {
        setState(() => currentIndex = 0);
      }
    } else {
      target = lockedPrinter;
    }

    if (target != null) {
      printQueueBloc.setDeviceId(int.tryParse(target));
      printQueueBloc.onLockDevice();

      setState(() => lockedPrinter = target);

      remainingLockTime = 60;

      if (printerLockRefresher != null) printerLockRefresher.cancel();
      printerLockRefresher = Timer.periodic(
        const Duration(seconds: 50),
        (Timer t) {
          printQueueBloc.onLockDevice();
          setState(() => remainingLockTime = 60);
        },
      );

      if (jobTimer != null) jobTimer.cancel();
      jobTimer = Timer.periodic(const Duration(seconds: 3),
          (Timer t) => BlocProvider.of<JoblistBloc>(context).onRefresh());
    } else {
      setState(() => currentIndex = 0);
    }
  }

  Future<bool> _onConfirmDismiss(BuildContext context, DismissDirection diection) async {
    bool keepJob = false;
    SnackBar snack = SnackBar(
      duration: Duration(seconds: 1),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          MaterialButton(
            child: Text('Löschen rückgängig machen'),
            onPressed: () {
              keepJob = true;
            },
          )
        ],
      ),
    );

    ScaffoldFeatureController snackController = Scaffold.of(context).showSnackBar(snack);

    if (keepJob) snackController.close();

    return snackController.closed.then((val) => !keepJob);
  }

  void _onLongTapped(BuildContext context, int id, JobOptions options) {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    JobOptions newOptions = options;

    newOptions.keep = !newOptions.keep;
    joblistBloc.onUpdateOptionsById(id, newOptions);

    Scaffold.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 1),
        content: Text((newOptions.keep) ? 'Job wird behalten' : 'Job wird nicht mehr behalten'),
      ),
    );
  }

  Future<void> _onRefresh() async {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    UserBloc userBloc = BlocProvider.of<UserBloc>(context);
    var listener;
    listener = joblistBloc.state.listen((JoblistState state) {
      if (state.isResult) {
        listener.cancel();
        return;
      }
    });
    userBloc.onRefresh();
    joblistBloc.onRefresh();
  }

  void _onSelectedUpload() async {
    UploadBloc uploadBloc = BlocProvider.of<UploadBloc>(context);
    String filePath = await _getFilePath();
    uploadBloc.onUpload(File(filePath).readAsBytesSync(), filename: filePath.split('/').last);
  }

  void _onTileDismissed(BuildContext context, int id) async {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
    joblistBloc.onDeleteById(id);
  }

  Future<bool> _onWillPop() {
    return showDialog(
          context: context,
          builder: (context) => ExitAppAlert(),
        ) ??
        false;
  }

  void _unlockPrinter() async {
    printQueueBloc.onRefresh();
    String uid;
    StreamSubscription listener;
    listener = printQueueBloc.state.listen((PrintQueueState state) {
      if (state.isLocked) {
        uid = state.lockUid;
        printQueueBloc.onDelete();
        setState(
          () {
            lockedPrinter = null;
            currentIndex = 0;
          },
        );
        listener.cancel();
      }
    });
  }
}
