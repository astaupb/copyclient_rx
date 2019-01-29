import 'package:flutter/material.dart';

class SecuritySettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Angemeldete Geräte'),
      ),
      body: ListView(
        children: <Widget>[],
      ),
    );
  }
}
