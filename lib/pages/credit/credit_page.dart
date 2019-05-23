import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class CreditPage extends StatefulWidget {
  @override
  _CreditPageState createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  static final List<int> dropdownValues = [5, 10, 15, 20];
  int selectedValue = dropdownValues.first;

  String actionBarTitle = 'Guthaben';

  bool showWebView = false;
  String _link;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(actionBarTitle)),
      body: (!showWebView)
          ? ListView(
              children: <Widget>[
                ListTile(
                  title: Text('Betrag zum Aufladen auswählen'),
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
                  child: Text('Kaufdialog öffnen'),
                ),
              ],
            )
          : WebView(
              initialUrl: _link,
              javascriptMode: JavascriptMode.unrestricted,
              onPageFinished: _onPageFinished,
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
    setState(() {
      showWebView = true;
      actionBarTitle = 'PayPal Bezahldialog';
    });
  }

  void _onPageFinished(String url) {
    print('webview finished loading $url');
    _link = null;
  }
}
