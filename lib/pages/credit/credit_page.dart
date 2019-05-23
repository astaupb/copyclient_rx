import 'dart:convert';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/journal.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class CreditPage extends StatefulWidget {
  @override
  _CreditPageState createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  JournalBloc journalBloc;
  UserBloc userBloc;

  static final List<int> dropdownValues = [5, 10, 15, 20];
  int selectedValue = dropdownValues.first;

  String _link;

  @override
  void initState() {
    journalBloc = BlocProvider.of<JournalBloc>(context);
    userBloc = BlocProvider.of<UserBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guthaben')),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Aktuelles Guthaben:'),
            trailing: BlocBuilder(
              bloc: journalBloc,
              builder: (BuildContext context, JournalState state) {
                if (state.isResult) {
                  return Text('${(state.value.credit / 100.0).toStringAsFixed(2)} €');
                } else {
                  return Container(height: 0.0, width: 0.0);
                }
              },
            ),
          ),
          ListTile(
            title: Text('Betrag zum Aufladen per PayPal auswählen'),
            trailing: DropdownButton(
              value: selectedValue,
              items: dropdownValues
                  .map(
                    (int value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value.00€'),
                        ),
                  )
                  .toList(),
              onChanged: _onDropdownChanged,
            ),
          ),
          RaisedButton(
            onPressed: _onSubmit,
            child: Text('PayPal Bezahlvorgang öffnen'),
          ),
          Divider(),
          RaisedButton(
            onPressed: _onScanCredit,
            child: Text('Guthabencode einscannen'),
          )
        ],
      ),
    );
  }

  void _onDropdownChanged(value) {
    setState(() => selectedValue = value);
  }

  Future<String> _getPaymentLink(int value) async {
    if (value >= 1) {
      Uri uri = Uri(scheme: 'http', host: '10.0.2.2', port: 5000, path: '/create/$value');
      return await http.get(uri).then((http.Response response) {
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

  void _onSubmit() async {
    print('requesting payment link for $selectedValue euros');
    _link = await _getPaymentLink(selectedValue);
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

  void _onScanCredit() async {
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
            duration: Duration(seconds: 3),
          );
          Scaffold.of(context).showSnackBar(snackBar);
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }
}
