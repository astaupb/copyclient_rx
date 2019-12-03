import 'package:blocs_copyclient/upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JoblistUploadQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UploadBloc, UploadState>(
      builder: (BuildContext context, UploadState state) {
        if (state.isResult) {
          if (state.value.length > 0) {
            return Column(
              children: <Widget>[
                ListTile(
                  title: Text('Uploads', textScaleFactor: 1.5),
                  subtitle: Text('${state.value.length} Jobs am hochladen...'),
                ),
                Divider(indent: 16.0, endIndent: 16.0, height: 0.0),
                for (int i = state.value.length - 1; i >= 0; i--)
                  ListTile(
                    title: Text(state.value[i].filename),
                    subtitle:
                        Text(state.value[i].isUploading ? 'Am Hochladen...' : 'Am Verarbeiten...'),
                  ),
                Divider(),
              ],
            );
          } else {
            return Container();
          }
        } else if (state.isBusy) {
          return Center(child: CircularProgressIndicator());
        }
        return Container();
      },
    );
  }
}
