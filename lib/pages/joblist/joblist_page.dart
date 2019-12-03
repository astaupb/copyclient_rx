import 'dart:async';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_creation.dart';
import 'package:blocs_copyclient/print_queue.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../blocs/camera_bloc.dart';
import '../../widgets/drawer/drawer.dart';
import '../../widgets/exit_app_alert.dart';
import '../../widgets/select_printer_dialog.dart';
import '../jobdetails/jobdetails.dart';
import 'joblist_bottom_bar.dart';
import 'joblist_deletion_modal.dart';
import 'joblist_tile.dart';

class JoblistPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _JoblistPageState();
}

class _JoblistPageState extends State<JoblistPage> {
  Logger _log = Logger('JoblistPage');

  PrintQueueBloc printQueueBloc;
  JoblistBloc joblistBloc;
  UploadBloc uploadBloc;
  UserBloc userBloc;

  PdfCreationBloc pdfCreation;

  StreamSubscription uploadListener;
  Timer uploadTimer;
  int uploadCount = 0;

  Timer printerLockRefresher;
  Timer jobTimer;
  StreamSubscription jobListener;

  BuildContext _scaffoldContext;
  String text = '';
  bool newException = true;

  StreamSubscription copyListener;
  DateTime copyStartTime;
  StreamSubscription printQueueListener;

  List<Job> pastJobs = [];
  List<int> copiedJobIds = [];

  int lastCredit = 0;

  int currentIndex = 0;
  int remainingLockTime = 0;
  String lockedPrinter;

  bool selectableTiles = false;
  List<int> selectedIds = [];

  StreamSubscription<List<String>> _intentDataStreamSubscription;
  StreamSubscription<List<String>> _intentImageSubscription;
  StreamSubscription<String> _intentTextSubscription;

  @override
  Widget build(BuildContext context) {
    jobListener = joblistBloc.listen((JoblistState state) async {
      if (state.isException) {
        joblistBloc.onRefresh();
        ApiException error = (state.error as ApiException);

        if (error.statusCode == 404) {
          text = 'Der angeforderte Job oder Drucker existiert nicht';
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
          automaticallyImplyLeading:
              !selectableTiles, // make drawer and title disappear on  multiselect
          title: (!selectableTiles) ? Text('Jobliste') : Container(width: 0.0, height: 0.0),
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
                            if (BlocProvider.of<CameraBloc>(context).state.cameraDisabled) {
                              target = await showDialog<String>(
                                context: context,
                                builder: (BuildContext context) => selectPrinterDialog(context),
                              );
                            } else {
                              target = await BarcodeScanner.scan();
                            }
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
                  Builder(
                    builder: (BuildContext context) => IconButton(
                      tooltip: 'Ausgewählte löschen',
                      icon: Icon(Icons.delete),
                      onPressed: () => showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) => JoblistDeletionModal(selectedIds))
                          .then((val) => setState(() => selectableTiles = false)),
                    ),
                  ),
                  BlocBuilder<JoblistBloc, JoblistState>(
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
                  Spacer(),
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
                  (BlocProvider.of<CameraBloc>(context).state.cameraDisabled)
                      ? IconButton(
                          tooltip: 'Direktdrucker festlegen',
                          icon: Icon(Icons.print),
                          onPressed: () async => lockedPrinter = await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => selectPrinterDialog(context)),
                        )
                      : Container(width: 0.0, height: 0.0),
                  MaterialButton(
                    child: BlocBuilder<UserBloc, UserState>(
                      bloc: userBloc,
                      builder: (BuildContext context, UserState state) {
                        if (state.isResult) {
                          lastCredit = state.value.credit;
                        }
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('Guthaben:', textScaleFactor: 0.8),
                            (state.isResult)
                                ? Text('${((lastCredit) / 100.0).toStringAsFixed(2)} €')
                                : Text('Laden...'),
                          ],
                        );
                      },
                    ),
                    onPressed: () => Navigator.of(context).pushNamed('/credit'),
                  ),
                  IconButton(
                    tooltip: 'Mehrfachauswahl aktivieren',
                    icon: Icon(Icons.select_all),
                    onPressed: () => setState(() => selectableTiles = true),
                  ),
                  Builder(
                    builder: (BuildContext context) => IconButton(
                      tooltip: 'Dokument hochladen',
                      icon: Icon(Icons.note_add),
                      onPressed: () => _onSelectedUpload(context),
                    ),
                  ),
                ],
        ),
        drawer: MainDrawer(),
        body: RefreshIndicator(
          onRefresh: () => _onRefresh(),
          child: BlocBuilder<JoblistBloc, JoblistState>(
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
                  return BlocBuilder(
                    bloc: uploadBloc,
                    builder: (BuildContext context, UploadState state) {
                      List<DispatcherTask> uploadList = [];
                      if (state.isResult) uploadList = state.value;
                      return ListView.builder(
                        itemExtent: 72.0,
                        itemCount: reverseList.length ?? 0 + uploadList.length,
                        itemBuilder: (BuildContext context, int index) {
                          if (index < uploadList.length) {
                            return Column(
                              children: <Widget>[
                                ListTile(
                                  title: Text('${uploadList[index].filename ?? 'Neuer Druckjob'}'),
                                  subtitle: Text((uploadList[index].isUploading)
                                      ? 'Am Hochladen...'
                                      : 'Dokument am Verarbeiten...'),
                                  trailing: CircularProgressIndicator(),
                                ),
                                Divider(height: 0.0),
                              ],
                            );
                          } else {
                            index -= uploadList.length;
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
                                          onPress: (int index) =>
                                              _onPressed(context, reverseList[index]),
                                          onLongTap: (int index) => _onLongTapped(context,
                                              reverseList[index].id, reverseList[index].jobOptions),
                                          directPrinter: lockedPrinter,
                                          chosen: selectedIds.contains(reverseList[index].id),
                                          onPressPrint: () =>
                                              _onPressPrint(context, reverseList, index),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Divider(height: 0.0),
                                ],
                              );
                          }
                          return Container(width: 0.0, height: 0.0);
                        },
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
          builder: (BuildContext context) => JoblistBottomBar(
            context,
            lockedPrinter: lockedPrinter,
            current: currentIndex,
            onPressed: (int index) => _changePage(context, index),
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
    if (jobListener != null) jobListener.cancel();
    if (printQueueListener != null) printQueueListener.cancel();
    //if (uploadListener != null) uploadListener.cancel();
    currentIndex = 0;
    selectableTiles = false;
    super.deactivate();
  }

  @override
  void dispose() {
    _cancelTimers();
    if (lockedPrinter != null) _unlockPrinter();
    if (copyListener != null) copyListener.cancel();
    if (jobListener != null) jobListener.cancel();
    if (printQueueListener != null) printQueueListener.cancel();
    if (uploadListener != null) uploadListener.cancel();
    if (_intentDataStreamSubscription != null) _intentDataStreamSubscription.cancel();
    if (_intentImageSubscription != null) _intentImageSubscription.cancel();
    if (_intentTextSubscription != null) _intentTextSubscription.cancel();
    currentIndex = 0;
    selectableTiles = false;
    super.dispose();
  }

  @override
  void initState() {
    joblistBloc = BlocProvider.of<JoblistBloc>(context);
    printQueueBloc = BlocProvider.of<PrintQueueBloc>(context);
    uploadBloc = BlocProvider.of<UploadBloc>(context);
    userBloc = BlocProvider.of<UserBloc>(context);

    pdfCreation = PdfCreationBloc();

    uploadListener = uploadBloc.listen(
      (UploadState state) {
        if (state.isResult) {
          if (state.value.length < uploadCount) {
            joblistBloc.onRefresh();
          }
          uploadCount = state.value.length;
          if (state.value.length == 0) {
            if (uploadTimer != null) uploadTimer.cancel();
          }
        }
      },
    );

    uploadBloc.onRefresh();

    currentIndex = 0;
    _cancelTimers();

    _intentTextSubscription = ReceiveSharingIntent.getTextStream().listen((String text) {
      ReceiveSharingIntent.reset();
      _handleIntentText(text);
    }, onError: (err) {
      print("intentTextSubscription error: $err");
    });

    ReceiveSharingIntent.getInitialText().then((String text) {
      ReceiveSharingIntent.reset();
      _handleIntentText(text);
    });

    _intentImageSubscription = ReceiveSharingIntent.getImageStream().listen((List<String> value) {
      ReceiveSharingIntent.reset();
      _handleIntentValue(value);
    }, onError: (err) {
      print("intentImageSubscription error: $err");
    });

    ReceiveSharingIntent.getInitialImage().then((List<String> value) {
      // Call reset method if you don't want to see this callback again.
      ReceiveSharingIntent.reset();
      _handleIntentValue(value);
    });

    // For sharing images coming from outside the app while the app is in the memory
    if (Platform.isAndroid)
      _intentDataStreamSubscription =
          ReceiveSharingIntent.getPdfStream().listen((List<String> value) {
        // Call reset method if you don't want to see this callback again.
        ReceiveSharingIntent.reset();
        _handleIntentValue(value);
      }, onError: (err) {
        print("intentDataStreamSubscription error: $err");
      });

    // For sharing images coming from outside the app while the app is closed
    if (Platform.isAndroid)
      ReceiveSharingIntent.getInitialPdf().then((List<String> value) {
        // Call reset method if you don't want to see this callback again.
        ReceiveSharingIntent.reset();
        _handleIntentValue(value);
      });

    super.initState();
  }

  void _cancelTimers() {
    if (printerLockRefresher != null) printerLockRefresher.cancel();
    if (jobTimer != null) jobTimer.cancel();
    if (uploadTimer != null) uploadTimer.cancel();
  }

  void _changePage(BuildContext context, int index) async {
    if (copyListener != null) copyListener.cancel();
    if (printQueueListener != null) printQueueListener.cancel();
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
        _lockPrinter();
        copyStartTime = DateTime.now();
        copyListener = joblistBloc.listen(
          (JoblistState state) {
            if (state.isResult) {
              for (Job job in state.value.where((Job job) =>
                  ((job.timestamp * 1000) > copyStartTime.millisecondsSinceEpoch) &&
                  !copiedJobIds.contains(job.id))) {
                joblistBloc.onPrintById(lockedPrinter, job.id);
                copyStartTime = DateTime.now();
                copiedJobIds.add(job.id);
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
        setState(() {
          currentIndex = 0;
          lockedPrinter = null;
        });
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
            Icon(Icons.delete_sweep, color: Colors.white),
          ],
        ),
        padding: EdgeInsets.all(20.0),
      );

  Future<Map<String, String>> _getFilePath() async {
    Map<String, String> filePaths;
    try {
      filePaths = await FilePicker.getMultiFilePath(type: FileType.ANY);
      if (filePaths != null && filePaths.isNotEmpty) return filePaths;
    } catch (e) {
      print("Error while picking the file: " + e.toString());
    }
    return {};
  }

  void _handleIntentText(String text) {
    if (text != null) {
      StreamSubscription listener;
      listener = pdfCreation.skip(1).listen((PdfCreationState state) {
        if (state.isResult) {
          uploadBloc.onUpload(state.value,
              filename: 'text_${DateTime.now().toIso8601String()}.txt');
          listener.cancel();
        }
      });
      print('memes: $text');
      pdfCreation.onCreateFromText(text);
    }

    StreamSubscription listener;
    listener = uploadBloc.listen((UploadState state) {
      if (state.isResult &&
          state.value.where((DispatcherTask task) => task.isUploading).length > 0) {
        uploadTimer = Timer.periodic(const Duration(seconds: 1), (_) => uploadBloc.onRefresh());
        listener.cancel();
      }
    });
  }

  void _handleIntentValue(List<String> value) async {
    if (value != null) {
      await PermissionHandler().shouldShowRequestPermissionRationale(PermissionGroup.storage);
      await PermissionHandler().requestPermissions([PermissionGroup.storage]);
      for (String url in value) {
        final File file = File(url);
        final String filename = file.path.split('/').last;
        final int numericFilename = int.tryParse(filename);
        print('upload filename $filename');

        if (_isSupportedDocument(filename)) {
          uploadBloc.onUpload(await file.readAsBytes(),
              filename: (numericFilename == null) ? filename : null);
        } else if (_isSupportedImage(filename)) {
          StreamSubscription listener;
          listener = pdfCreation.skip(1).listen((PdfCreationState state) {
            if (state.isResult) {
              uploadBloc.onUpload(state.value, filename: filename);
              listener.cancel();
            }
          });

          pdfCreation.onCreateFromImage(await file.readAsBytes());
        }
      }

      StreamSubscription listener;
      listener = uploadBloc.listen((UploadState state) {
        if (state.isResult &&
            state.value.where((DispatcherTask task) => task.isUploading).length > 0) {
          uploadTimer = Timer.periodic(const Duration(seconds: 1), (_) => uploadBloc.onRefresh());
          listener.cancel();
        }
      });
    }
  }

  bool _isSupportedDocument(String filename) {
    const List<String> fileTypes = [
      'pdf',
      'ai',
    ];
    final String suffix = filename.split('.').last;
    return fileTypes.contains(suffix.toLowerCase());
  }

  bool _isSupportedImage(String filename) {
    const List<String> imageTypes = [
      'png',
      'apng',
      'jpeg',
      'jpg',
      'jif',
      'jfif',
      'jpe',
      'jfi',
      'webp',
      'tga',
      'tpic',
      'gif',
      'pvr',
      'tiff',
      'tif',
      'psd',
      'exr',
    ];
    final String suffix = filename.split('.').last;
    return imageTypes.contains(suffix.toLowerCase());
  }

  bool _isSupportedText(String filename) {
    const List<String> fileTypes = [
      'txt',
      'asc',
      'json',
      'conf',
      'cnf',
      'cfg',
      'log',
      'xml',
      'ini',
      'tsv',
      'tab',
      'yaml',
      'toml',
      'md',
      'diff',
    ];
    final String suffix = filename.split('.').last;
    return fileTypes.contains(suffix.toLowerCase());
  }

  void _lockPrinter() async {
    String target;
    if (lockedPrinter == null) {
      _log.fine('_lockPrinter: lockedPrinter is null, trying dialog or camera');
      try {
        //target = "44332";
        if (BlocProvider.of<CameraBloc>(context).state.cameraDisabled) {
          target = await showDialog<String>(
            context: context,
            builder: (BuildContext context) => selectPrinterDialog(context),
          );
        } else {
          target = await BarcodeScanner.scan();
        }
      } catch (e) {
        _log.severe(e.toString());
        setState(() => currentIndex = 0);
      }
    } else {
      _log.fine('_lockPrinter: lockedPrinter != null, setting target to $lockedPrinter');
      target = lockedPrinter;
    }

    if (target != null) {
      _log.fine('_lockPrinter: target is set to $target, try to lock that printer now');
      printQueueListener = printQueueBloc.listen((PrintQueueState state) {
        if (state.isException) {
          if ((state.error as ApiException).statusCode == 423)
            Scaffold.of(_scaffoldContext).showSnackBar(SnackBar(
                duration: Duration(seconds: 3),
                content: Text(
                    'Dieser Drucker ist gerade von jemand Anderem in Benutzung. Falls das nicht so aussieht wende dich bitte ans Personal.')));
          else if ((state.error as ApiException).statusCode == 404) {
            printQueueListener.cancel();
            printerLockRefresher.cancel();
            jobTimer.cancel();
          }
          setState(() {
            currentIndex = 0;
            lockedPrinter = null;
          });
          printQueueBloc.onRefresh();
        }
      });

      printQueueBloc.setDeviceId(int.tryParse(target));
      printQueueBloc.onLockDevice();

      setState(() => lockedPrinter = target);

      remainingLockTime = 60;

      if (printerLockRefresher != null) printerLockRefresher.cancel();
      printerLockRefresher = Timer.periodic(
        const Duration(seconds: 50),
        (Timer t) {
          if (mounted) {
            printQueueBloc.onLockDevice();
            setState(() => remainingLockTime = 60);
          } else {
            _changePage(context, 0);
            _cancelTimers();
          }
        },
      );

      if (jobTimer != null) jobTimer.cancel();
      jobTimer = Timer.periodic(const Duration(seconds: 3), (Timer t) => joblistBloc.onRefresh());
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

  void _onPressed(BuildContext context, Job job) {
    if (selectableTiles) {
      setState(() {
        if (selectedIds.contains(job.id))
          selectedIds.remove(job.id);
        else
          selectedIds.add(job.id);
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => JobdetailsPage(job),
        ),
      );
    }
  }

  _onPressPrint(BuildContext context, List<Job> jobs, int index) async {
    if (!selectableTiles) {
      String target;
      if (lockedPrinter != null) {
        target = lockedPrinter;
        joblistBloc.onPrintById((lockedPrinter == null) ? target : lockedPrinter, jobs[index].id);
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text('${jobs[index].jobInfo.filename} wurde abgeschickt'),
          duration: Duration(seconds: 1),
        ));
      } else {
        try {
          if (BlocProvider.of<CameraBloc>(context).state.cameraDisabled) {
            target = await showDialog<String>(
              context: context,
              builder: (BuildContext context) => selectPrinterDialog(context),
            );
          } else {
            target = await BarcodeScanner.scan();
          }
          joblistBloc.onPrintById((lockedPrinter == null) ? target : lockedPrinter, jobs[index].id);
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('${jobs[index].jobInfo.filename} wurde abgeschickt'),
            duration: Duration(seconds: 1),
          ));
        } catch (e) {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('Kein Drucker ausgewählt'),
            duration: Duration(seconds: 1),
          ));
        }
      }
    } else {
      setState(() {
        if (selectedIds.contains(jobs[index].id))
          selectedIds.remove(jobs[index].id);
        else
          selectedIds.add(jobs[index].id);
      });
    }
  }

  Future<void> _onRefresh() async {
    var listener;
    listener = joblistBloc.listen((JoblistState state) {
      if (state.isResult) {
        listener.cancel();
        return;
      }
    });
    userBloc.onRefresh();
    uploadBloc.onRefresh();
    joblistBloc.onRefresh();
  }

  void _onSelectedUpload(BuildContext context) async {
    await _getFilePath().then(
      (Map<String, String> paths) => paths.forEach((String filename, String path) {
        if (_isSupportedDocument(filename)) {
          uploadBloc.onUpload(File(path).readAsBytesSync(), filename: filename);
        } else if (_isSupportedImage(filename)) {
          StreamSubscription listener;
          listener = pdfCreation.skip(1).listen((PdfCreationState state) {
            if (state.isResult) {
              uploadBloc.onUpload(state.value, filename: filename);
              listener.cancel();
            }
          });

          pdfCreation.onCreateFromImage(File(path).readAsBytesSync());
        } else if (_isSupportedText(filename)) {
          StreamSubscription listener;
          listener = pdfCreation.skip(1).listen((PdfCreationState state) {
            if (state.isResult) {
              uploadBloc.onUpload(state.value, filename: filename);
              listener.cancel();
            }
          });

          pdfCreation.onCreateFromText(File(path).readAsStringSync(),
              monospace: (!path.endsWith('txt')));
        } else {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(
                'Nicht unterstütztes Dateiformat in $filename. Es werden nur PDF Dokumente, Bilder und einfacher Text unterstützt.'),
            duration: Duration(seconds: 3),
          ));
        }
      }),
    );
    uploadTimer = Timer.periodic(const Duration(seconds: 1), (_) => uploadBloc.onRefresh());
  }

  void _onTileDismissed(BuildContext context, int id) async {
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
    StreamSubscription listener;
    listener = printQueueBloc.listen((PrintQueueState state) {
      if (state.isLocked) {
        printQueueBloc.onDelete();
        setState(() {
          lockedPrinter = null;
          currentIndex = 0;
        });
        listener.cancel();
      }
    });
    printQueueBloc.onRefresh();
  }
}
