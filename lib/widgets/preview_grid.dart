import 'package:flutter/widgets.dart';

///
/// A grid of 1 to 4 pages made of the first 4 pages of the document.
/// Grid is created to visualize the nup option from [JobOptions]
///
class PreviewGrid extends StatefulWidget {
  @override
  State<PreviewGrid> createState() => _PreviewGridState();
}

class _PreviewGridState extends State<PreviewGrid> {
  @override
  Widget build(BuildContext context) {
   /* bool _portrait =
                  (snapshot.data[0]['width'] < snapshot.data[0]['height']);
              if (_job.jobInfo.pagecount > 1 && _job.jobOptions.nup > 1) {
                if ((_portrait && _job.jobOptions.nup == 4) ||
                    (!_portrait && _job.jobOptions.nup == 2)) {
                  /// for portrait nup4 pages or landscape nup2 pages
                  return Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      Container(
                        height: ((_portrait && _job.jobOptions.nup == 4) ||
                                (!_portrait && _job.jobOptions.nup == 2))
                            ? 450.0
                            : 250.0,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(
                              File(snapshot.data[0]['path']),
                              scale: 1.4,
                            ),
                            fit: BoxFit.none,
                          ),
                        ),
                        child: BackdropFilter(
                          filter:
                              dui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3)),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(top: 5.0, bottom: 5.0),
                            padding: EdgeInsets.all(5.0),
                            alignment: Alignment.center,
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Image.file(
                                  File(snapshot.data[0]['path']),
                                  width:
                                      (_job.jobOptions.nup > 2) ? 150.0 : 300,
                                ),
                                Image.file(
                                  File(snapshot.data[
                                      (_portrait && _job.jobOptions.nup == 4)
                                          ? 2
                                          : 1]['path']),
                                  width:
                                      (_job.jobOptions.nup > 2) ? 150.0 : 300,
                                ),
                              ],
                            ),
                          ),
                          (_job.jobInfo.pagecount > 2 &&
                                  _job.jobOptions.nup > 2)
                              ? Container(
                                  margin:
                                      EdgeInsets.only(top: 5.0, bottom: 5.0),
                                  padding: EdgeInsets.all(5.0),
                                  alignment: Alignment.center,
                                  color: Colors.white,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Image.file(
                                        File(snapshot.data[(_portrait &&
                                                _job.jobOptions.nup == 4)
                                            ? 1
                                            : 2]['path']),
                                        width: 150.0,
                                      ),
                                      Image.file(
                                        File(snapshot.data[3]['path']),
                                        width: 150.0,
                                      ),
                                    ],
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ],
                  );
                } else if ((!_portrait && _job.jobOptions.nup == 4) ||
                    (_portrait && _job.jobOptions.nup == 2)) {
                  /// for landscape nup4 pages or portrait nup2 pages
                  return Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      Container(
                        height: (!_portrait && _job.jobOptions.nup == 2)
                            ? 450.0
                            : 250.0,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(
                              File(snapshot.data[0]['path']),
                              scale: 1.4,
                            ),
                            fit: BoxFit.none,
                          ),
                        ),
                        child: BackdropFilter(
                          filter:
                              dui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3)),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(top: 5.0),
                            padding: EdgeInsets.all(5.0),
                            alignment: Alignment.center,
                            color: Colors.white,
                            width: 310.0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Image.file(
                                  File(snapshot.data[0]['path']),
                                  width: 150.0,
                                ),
                                Image.file(
                                  File(snapshot.data[1]['path']),
                                  width: 150.0,
                                ),
                              ],
                            ),
                          ),
                          (_job.jobInfo.pagecount > 2 &&
                                  _job.jobOptions.nup > 2)
                              ? Container(
                                  margin: EdgeInsets.only(bottom: 5.0),
                                  padding: EdgeInsets.all(5.0),
                                  alignment: Alignment.center,
                                  color: Colors.white,
                                  width: 310.0,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Image.file(
                                        File(snapshot.data[2]['path']),
                                        width: 150.0,
                                      ),
                                      Image.file(
                                        File(snapshot.data[3]['path']),
                                        width: 150.0,
                                      ),
                                    ],
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ],
                  );
                }
              } else {
                return Container(
                  margin: EdgeInsets.all(10.0),
                  alignment: Alignment.center,
                  color: Colors.white,
                  child: Image.file(
                    File(snapshot.data[0]['path']),
                  ),
                );
              }
            } else*/
              return Placeholder();
  }
}
