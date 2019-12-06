import 'dart:async';
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

import '../../widgets/transactions_tile.dart';

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

  StreamSubscription webviewListener;
  String _link;

  StreamSubscription journalListener;
  List<Transaction> transactionsExcerpt = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guthaben')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
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
            Padding(
              padding: EdgeInsets.only(left: 24.0, right: 24.0),
              child: RaisedButton(
                onPressed: _onSubmit,
                child: Text('PayPal Bezahlvorgang öffnen'),
              ),
            ),
            Divider(height: 24.0),
            Builder(
              builder: (BuildContext context) => Padding(
                padding: EdgeInsets.only(left: 24.0, right: 24.0),
                child: RaisedButton(
                  onPressed: () => _onScanCredit(context),
                  child: Text('Guthabencode einscannen'),
                ),
              ),
            ),
            Divider(height: 24.0),
            ListTile(title: Text('Letzte Transaktionen')),
            ...List.from(
                transactionsExcerpt.map<TransactionsTile>((Transaction t) => TransactionsTile(t))),
            MaterialButton(
              child: Text('Alle ansehen...'),
              textColor: Colors.black87,
              minWidth: 180.0,
              onPressed: () => Navigator.of(context).pushNamed('/credit/transactions'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (journalListener != null) journalListener.cancel();
    if (webviewListener != null) webviewListener.cancel();
    super.dispose();
  }

  @override
  void initState() {
    journalBloc = BlocProvider.of<JournalBloc>(context);
    userBloc = BlocProvider.of<UserBloc>(context);

    journalBloc.onRefresh();

    journalListener = journalBloc.listen((JournalState state) {
      if (state.isResult) {
        setState(() => transactionsExcerpt = state.value.transactions.take(5).toList());
      }
    });

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
      return Text(
        '${(state.value.credit / 100.0).toStringAsFixed(2)} €',
        textScaleFactor: 1.4,
      );
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
    int userId;
    await userBloc
        .takeWhile((UserState state) => state.isResult)
        .first
        .then((UserState state) => userId = state.value.userId);
    if (value >= 1) {
      return await http
          .post('https://astaprint.uni-paderborn.de/aufwerter/create/$value?user_id=$userId')
          .then((http.Response response) {
        if (response.statusCode == 200) {
          print(response.body);
          return json.decode(utf8.decode(response.bodyBytes))['link'] as String;
        } else if (response.statusCode == 400) {
          print('error getting payment link: ${response.body}');
        }
        return '';
      });
    }
    return '';
  }

  void _onDropdownChanged(int value) {
    setState(() => selectedValue = value);
  }

  Future<void> _onRefresh() async {
    journalBloc.onRefresh();
    await journalBloc.take(1).first.then((JournalState state) {
      return;
    });
  }

  void _onScanCredit(BuildContext context) async {
    try {
      var token = await BarcodeScanner.scan();
      journalBloc.onAddTransaction(token);
      StreamSubscription listener;
      listener = journalBloc.listen((JournalState state) async {
        if (state.isResult) {
          await Future<dynamic>.delayed(Duration(seconds: 2))
              .then((dynamic val) => userBloc.onRefresh());
          await listener.cancel();
        } else if (state.isException) {
          var error = state.error as ApiException;
          var snackText = 'Fehler: $error';
          if (error.statusCode == 472) {
            snackText = 'Fehler: Dieser Token wurde bereits verbraucht';
          } else if (error.statusCode == 401) {
            snackText = 'Du hast keine Berechtigung dies zu tun oder falsche Anmeldedaten';
          } else if (error.statusCode == 400) {
            snackText = 'Der gescannte Code hat das falsche Format oder enthält falsche Daten';
          }
          var snackBar = SnackBar(
            content: Text(snackText),
            duration: const Duration(seconds: 3),
          );
          Scaffold.of(context).showSnackBar(snackBar);
        }
      });
    } catch (e) {
      const snackBar = SnackBar(
        content: Text('Es wurde kein Code gescannt'),
        duration: Duration(seconds: 3),
      );
      Scaffold.of(context).showSnackBar(snackBar);
      print(e.toString());
    }
  }

  void _onSubmit() async {
    final valueToUse = (customValue != null) ? customValue : selectedValue;
    print('requesting payment link for $valueToUse euros');
    _link = await _getPaymentLink(valueToUse);
    customValue = null;
    if (_link != '') {
      await Navigator.of(context).push<WebviewScaffold>(
        MaterialPageRoute(
          builder: (BuildContext context) => WebviewScaffold(
            url: _link,
            appBar: AppBar(title: Text('PayPal Bezahlvorgang')),
            withJavascript: true,
            clearCache: true,
            clearCookies: true,
            withLocalStorage: false,
            withZoom: false,
            allowFileURLs: false,
            supportMultipleWindows: false,
          ),
        ),
      );

      final flutterWebviewPlugin = FlutterWebviewPlugin();

      void waitAndClose() async {
        await Future<dynamic>.delayed(const Duration(seconds: 3));
        Navigator.of(context).pop();
        await flutterWebviewPlugin.close();
        await Future<dynamic>.delayed(const Duration(seconds: 2));
        journalBloc.onRefresh();
      }

      webviewListener = flutterWebviewPlugin.onUrlChanged.listen((String url) async {
        if (url.contains('/aufwerter/cancel')) {
          print('payment got cancelled');
          waitAndClose();
        } else if (url.contains('/aufwerter/success')) {
          print('payment was success');
          waitAndClose();
        }
      });
    }
  }
}
