import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/camera_bloc.dart';

class AdvancedSettingsPage extends StatefulWidget {
  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  CameraBloc cameraBloc;

  bool _cameraDisabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Erweitert'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Eingabefelder statt Kamera nutzen'),
            subtitle: Text('Zur Zuweisung eines Druckers ohne Kamera/mit defekter Kamera'),
            trailing: BlocBuilder<CameraEvent, CameraState>(
              bloc: cameraBloc,
              builder: (BuildContext context, CameraState state) {
                _cameraDisabled = state.cameraDisabled;
                return Switch(
                  onChanged: (bool value) =>
                      (value) ? cameraBloc.onDisable() : cameraBloc.onEnable(),
                  value: state.cameraDisabled,
                );
              },
            ),
            onTap: () => (!_cameraDisabled) ? cameraBloc.onDisable() : cameraBloc.onEnable(),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    cameraBloc = BlocProvider.of<CameraBloc>(context);
    super.initState();
  }
}
