import 'dart:ui' as dui;

import 'package:blocs_copyclient/joblist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:blocs_copyclient/preview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///
/// A grid of 1 to 4 pages made of the first 4 pages of the document.
/// Grid is created to visualize the nup option from [JobOptions]
///
class PreviewGrid extends StatefulWidget {
  final Job job;

  PreviewGrid(this.job);

  @override
  State<PreviewGrid> createState() => _PreviewGridState(job);
}

class _PreviewGridState extends State<PreviewGrid> {
  Job job;

  _PreviewGridState(this.job);

  double currentScale = 1.0;
  Offset currentFocalPoint;

  Map<String, int> getImageDimensions(List<int> imageBytes) {
    Map<String, int> _dim = {'width': 0, 'height': 0};
    int i;

    String header = '';
    for (i = 0; i < 8; i++) {
      header = header +
          ((imageBytes[i].toRadixString(16).length < 2) ? '0' : '') +
          imageBytes[i].toRadixString(16);
    }

    if (header == '89504e470d0a1a0a') {
      String width = '';
      for (i = 16; i < 20; i++) {
        width = width +
            ((imageBytes[i].toRadixString(16).length < 2) ? '0' : '') +
            imageBytes[i].toRadixString(16);
      }
      _dim['width'] = int.parse(width, radix: 16);

      String height = '';
      for (i = i; i < 24; i++) {
        height = height +
            ((imageBytes[i].toRadixString(16).length < 2) ? '0' : '') +
            imageBytes[i].toRadixString(16);
      }
      _dim['height'] = int.parse(height, radix: 16);
    } else {
      print('$scope header ($header) of preview does not match png header');
    }
    return _dim;
  }

  @override
  Widget build(BuildContext context) {
    final PreviewBloc previewBloc = BlocProvider.of<PreviewBloc>(context);
    final JoblistBloc joblistBloc = BlocProvider.of<JoblistBloc>(context);

    previewBloc.getPreview(job);

    bool setsMatch(PreviewSet previewSet) => previewSet.jobId == job.id;

    return BlocBuilder(
      bloc: joblistBloc,
      builder: (BuildContext context, JoblistState state) {
        if (state.isResult) {
          job = state.value.singleWhere((Job job) => job.id == this.job.id);
          return GestureDetector(
            onScaleStart: (ScaleStartDetails scale) {
              print(scale);
              currentFocalPoint = scale.focalPoint;
            },
            onScaleUpdate: (ScaleUpdateDetails scale) {
              print(scale);
              currentScale = scale.scale;
            },
            onScaleEnd: (ScaleEndDetails scale) {
              print(scale);
              //currentScale = 1.0;
            },
            child: Transform.scale(
              scale: currentScale,
              child: BlocBuilder(
                bloc: previewBloc,
                builder: (BuildContext context, PreviewState state) {
                  if (state.isResult && state.value.any(setsMatch)) {
                    PreviewSet previewSet = state.value.singleWhere(setsMatch);
                    Map<String, int> size = getImageDimensions(previewSet.previews[0]);
                    bool _portrait = (size['width'] < size['height']);

                    if (job.jobInfo.pagecount > 1 && job.jobOptions.nup > 1) {
                      if ((_portrait && job.jobOptions.nup == 4) ||
                          (!_portrait && job.jobOptions.nup == 2)) {
                        /// for portrait nup4 pages or landscape nup2 pages
                        return Stack(
                          fit: StackFit.passthrough,
                          children: <Widget>[
                            Container(
                              height: ((_portrait && job.jobOptions.nup == 4) ||
                                      (!_portrait && job.jobOptions.nup == 2))
                                  ? 450.0
                                  : 250.0,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: MemoryImage(
                                    previewSet.previews[0],
                                    scale: 1.4,
                                  ),
                                  fit: BoxFit.none,
                                ),
                              ),
                              child: BackdropFilter(
                                filter: dui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
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
                                      Image.memory(
                                        previewSet.previews[0],
                                        width: (job.jobOptions.nup > 2) ? 150.0 : 300,
                                      ),
                                      Image.memory(
                                        previewSet.previews[(_portrait &&
                                                job.jobOptions.nup == 4 &&
                                                job.jobInfo.pagecount > 2)
                                            ? 2
                                            : 1],
                                        width: (job.jobOptions.nup > 2) ? 150.0 : 300,
                                      ),
                                    ],
                                  ),
                                ),
                                if (job.jobInfo.pagecount > 2 && job.jobOptions.nup > 2)
                                  Container(
                                    margin: EdgeInsets.only(top: 5.0, bottom: 5.0),
                                    padding: EdgeInsets.all(5.0),
                                    alignment: Alignment.center,
                                    color: Colors.white,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Image.memory(
                                          previewSet.previews[
                                              (_portrait && job.jobOptions.nup == 4) ? 1 : 2],
                                          width: 150.0,
                                        ),
                                        (job.jobInfo.pagecount == 3)
                                            ? Container(
                                                width: 150,
                                                height: 211.5,
                                              )
                                            : Image.memory(
                                                previewSet.previews[3],
                                                width: 150.0,
                                              ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      } else if ((!_portrait && job.jobOptions.nup == 4) ||
                          (_portrait && job.jobOptions.nup == 2)) {
                        /// for landscape nup4 pages or portrait nup2 pages
                        return Stack(
                          fit: StackFit.passthrough,
                          children: <Widget>[
                            Container(
                              height: (!_portrait && job.jobOptions.nup == 2) ? 450.0 : 250.0,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: MemoryImage(
                                    previewSet.previews[0],
                                    scale: 1.4,
                                  ),
                                  fit: BoxFit.none,
                                ),
                              ),
                              child: BackdropFilter(
                                filter: dui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
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
                                      Image.memory(
                                        previewSet.previews[0],
                                        width: 150.0,
                                      ),
                                      Image.memory(
                                        previewSet.previews[1],
                                        width: 150.0,
                                      ),
                                    ],
                                  ),
                                ),
                                if (job.jobInfo.pagecount > 2 && job.jobOptions.nup > 2)
                                  Container(
                                    margin: EdgeInsets.only(bottom: 5.0),
                                    padding: EdgeInsets.all(5.0),
                                    alignment: Alignment.center,
                                    color: Colors.white,
                                    width: 310.0,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Image.memory(
                                          previewSet.previews[2],
                                          width: 150.0,
                                        ),
                                        if (job.jobInfo.pagecount > 3)
                                          Image.memory(
                                            previewSet.previews[3],
                                            width: 150.0,
                                          )
                                        else
                                          Container(
                                            width: 150.0,
                                          )
                                      ],
                                    ),
                                  ),
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
                        child: Image.memory(
                          previewSet.previews[0],
                        ),
                      );
                    }
                  }
                  return Center(child: CircularProgressIndicator());
                },
              ),
            ),
          );
        } else
          return Center(child: CircularProgressIndicator());
      },
    );
  }
}
