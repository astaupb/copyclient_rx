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

  Timer printerLockTimer;
  Timer printerLockRefresher;
  Timer jobTimer;

  int lastCredit;

  int currentIndex = 0;
  int remainingLockTime = 0;
  String lockedPrinter;

  bool selectableTiles = false;
  List<int> selectedIds = [];

  @override
  Widget build(BuildContext context) {
    JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);
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
              if (state.isResult) {
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
                                                '${reverseList[index].jobInfo.title} wurde abgeschickt'),
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
              } else if (state.isException) {
                ApiException error = (state.error as ApiException);
                String text = '';
                if (error.statusCode == 401) {
                  BlocProvider.of<AuthBloc>(context).logout();
                  Navigator.pop(context);
                } else if (error.statusCode == 404) {
                  joblistBloc.onRefresh();
                } else if (error.statusCode >= 500) {
                  text = 'Serverfehler (${error.statusCode}) - Bitte in ein paar Sekunden aktualisieren';
                } else {
                  text = error.toString();
                }
                return ListView(
                  children: <Widget>[
                    ListTile(
                      title: Text(text),
                    )
                  ],
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
        bottomNavigationBar: BubbleBottomBar(
          opacity: .2,
          currentIndex: currentIndex,
          onTap: (int index) => _changePage(index),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          elevation: 8,
          items: <BubbleBottomBarItem>[
            BubbleBottomBarItem(
                backgroundColor: Colors.red,
                icon: Icon(
                  Icons.list,
                  color: Colors.black,
                ),
                activeIcon: Icon(
                  Icons.list,
                  color: Colors.red,
                ),
                title: Text("Listenansicht")),
            BubbleBottomBarItem(
              backgroundColor: Colors.deepPurple,
              icon: Icon(
                Icons.scanner,
                color: Colors.black,
              ),
              activeIcon: Icon(
                Icons.scanner,
                color: Colors.deepPurple,
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text("Zur Liste Scannen"),
                  Text(
                    'Verbleibend: $remainingLockTime Sekunden',
                    textScaleFactor: 0.75,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void deactivate() {
    _cancelTimers();
    if (lockedPrinter != null) _unlockPrinter();
    currentIndex = 0;
    super.deactivate();
  }

  @override
  void dispose() {
    _cancelTimers();
    if (lockedPrinter != null) _unlockPrinter();
    super.dispose();
  }

  @override
  void initState() {
    currentIndex = 0;
    super.initState();
    _cancelTimers();
  }

  void _cancelTimers() {
    if (printerLockRefresher != null) printerLockRefresher.cancel();
    if (printerLockTimer != null) printerLockTimer.cancel();
    if (jobTimer != null) jobTimer.cancel();
  }

  void _changePage(int index) async {
    setState(() {
      currentIndex = index;
    });
    if (currentIndex == 1) {
      // TODO: load dispatcher queue
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
    try {
      //target = "44332";
      target = await BarcodeScanner.scan();
    } catch (e) {
      setState(() => currentIndex = 0);
    }

    if (target != null) {
      printQueueBloc.setDeviceId(int.tryParse(target));
      printQueueBloc.onLockDevice();

      setState(() => lockedPrinter = target);

      remainingLockTime = 60;

      if (printerLockTimer != null) printerLockTimer.cancel();
      printerLockTimer = Timer.periodic(
        const Duration(seconds: 1),
        (Timer t) => setState(() => remainingLockTime -= 1),
      );

      if (printerLockRefresher != null) printerLockRefresher.cancel();
      printerLockRefresher = Timer.periodic(
        const Duration(seconds: 50),
        (Timer t) {
          printQueueBloc.onLockDevice();
          setState(() => remainingLockTime = 60);
        },
      );

      if (jobTimer != null) jobTimer.cancel();
      jobTimer = Timer.periodic(const Duration(seconds: 5),
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
