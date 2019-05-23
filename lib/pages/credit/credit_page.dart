import 'dart:convert';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/journal.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;

class CreditPage extends StatefulWidget {
  @override
  _CreditPageState createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  static final List<int> dropdownValues = [5, 10, 15, 20];
  JournalBloc journalBloc;

  UserBloc userBloc;
  int selectedValue = dropdownValues.first;
  int customValue;

  String _link;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guthaben')),
      body: ListView(
        children: <Widget>[
          Divider(height: 24.0),
          ListTile(
            title: Text('Aktuelles Guthaben:'),
            trailing: BlocBuilder(
              bloc: journalBloc,
              builder: _creditBuilder,
            ),
          ),
          Divider(height: 24.0),
          ListTile(
            title: Text('Betrag zum Aufladen per PayPal auswählen'),
            trailing: DropdownButton(
              value: selectedValue,
              items: _getDropdownItems(),
              onChanged: _onDropdownChanged,
            ),
          ),
          if (selectedValue == -1)
            ListTile(
                title: Text('Benutzerdefinierter Betrag:'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 100.0,
                      child: TextField(
                        controller: TextEditingController(
                            text: (customValue != null) ? customValue.toString() : '5'),
                        keyboardType: TextInputType.numberWithOptions(),
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        autofocus: true,
                        textAlign: TextAlign.end,
                        maxLength: 3,
                        maxLengthEnforced: true,
                        buildCounter: _counterBuilder,
                        onChanged: (String value) => customValue = int.tryParse(value),
                      ),
                    ),
                    Text('€', textScaleFactor: 1.3),
                  ],
                )),
          RaisedButton(
            onPressed: _onSubmit,
            child: Text('PayPal Bezahlvorgang öffnen'),
          ),
          Divider(height: 24.0),
          Builder(
            builder: (BuildContext context) => RaisedButton(
                  onPressed: () => _onScanCredit(context),
                  child: Text('Guthabencode einscannen'),
                ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    journalBloc = BlocProvider.of<JournalBloc>(context);
    userBloc = BlocProvider.of<UserBloc>(context);
    super.initState();
  }

  Widget _counterBuilder(
    BuildContext context, {
    int currentLength,
    int maxLength,
    bool isFocused,
  }) {
    return Container(width: 0.0, height: 0.0);
  }

  Widget _creditBuilder(BuildContext context, JournalState state) {
    if (state.isResult) {
      return Text('${(state.value.credit / 100.0).toStringAsFixed(2)} €');
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }

  List<DropdownMenuItem<int>> _getDropdownItems() => dropdownValues
      .map(
        (int value) => DropdownMenuItem<int>(
              value: value,
              child: Text('$value.00€'),
            ),
      )
      .toList()
        ..add(DropdownMenuItem(
          value: -1,
          child: Text('Benutzerdefiniert'),
        ));

  Future<String> _getPaymentLink(int value) async {
    if (value >= 1) {
      return await http
          .get('https://astaprint.uni-paderborn.de/aufwerter/create/$value')
          .then((http.Response response) {
        if (response.statusCode == 200) {
          print(response.body);
          return json.decode(utf8.decode(response.bodyBytes))['link'];
        } else if (response.statusCode == 400) {
          return '';
        }
      });
    }
    return '';
  }

  void _onDropdownChanged(value) {
    setState(() => selectedValue = value);
  }

  void _onScanCredit(BuildContext context) async {
    try {
      String token = await BarcodeScanner.scan();
      journalBloc.onAddTransaction(token);
      var listener;
      listener = journalBloc.state.listen((JournalState state) async {
        if (state.isResult) {
          Future.delayed(Duration(seconds: 2)).then((val) => userBloc.onRefresh());
          listener.cancel();
        } else if (state.isException) {
          ApiException error = state.error;
          String snackText = 'Fehler: $error';
          if (error.statusCode == 472) {
            snackText = 'Fehler: Dieser Token wurde bereits verbraucht';
          } else if (error.statusCode == 401) {
            snackText = 'Du hast keine Berechtigung dies zu tun oder falsche Anmeldedaten';
          } else if (error.statusCode == 400) {
            snackText = 'Der gescannte Code hat das falsche Format oder enthält falsche Daten';
          }
          SnackBar snackBar = SnackBar(
            content: Text(snackText),
            duration: const Duration(seconds: 3),
          );
          Scaffold.of(context).showSnackBar(snackBar);
        }
      });
    } catch (e) {
      const SnackBar snackBar = SnackBar(
        content: Text('Es wurde kein Code gescannt'),
        duration: Duration(seconds: 3),
      );
      Scaffold.of(context).showSnackBar(snackBar);
      print(e.toString());
    }
  }

  void _onSubmit() async {
    final int valueToUse = (customValue != null) ? customValue : selectedValue;
    print('requesting payment link for $valueToUse euros');
    _link = await _getPaymentLink(valueToUse);
    customValue = null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => WebviewScaffold(
              url: _link,
              appBar: AppBar(title: Text('PayPal Bezahlvorgang')),
              withJavascript: true,
              clearCache: true,
              clearCookies: true,
              withLocalStorage: false,
              withZoom: true,
              allowFileURLs: false,
              supportMultipleWindows: false,
            ),
      ),
    );
  }
}
