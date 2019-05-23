import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs_copyclient/journal.dart';

import '../../widgets/transactions_tile.dart';
import '../../widgets/centered_text.dart';

class TransactionsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  JournalBloc journalBloc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaktionen')),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(),
        child: BlocBuilder<JournalEvent, JournalState>(
          bloc: BlocProvider.of<JournalBloc>(context),
          builder: (BuildContext context, JournalState state) {
            if (state.isResult) {
              return ListView.builder(
                itemCount: state.value.transactions.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Column(
                      children: <Widget>[
                        ListTile(
                          title: Text(
                            'Aktuelles Guthaben:',
                            textScaleFactor: 1.1,
                          ),
                          trailing: Text(
                            '${(state.value.credit / 100.0).toStringAsFixed(2)} €',
                            textScaleFactor: 1.3,
                          ),
                        ),
                      ],
                    );
                  }
                  return Container(
                    color: (index % 2 == 1) ? Colors.black12 : null,
                    child: TransactionsTile(state.value.transactions[index - 1]),
                  );
                },
              );
            } else if (state.isException) {
              return ListView(
                children: <Widget>[CenteredText(state.error.toString())],
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    journalBloc = BlocProvider.of<JournalBloc>(context);
    super.initState();
  }

  Future<void> _onRefresh() async {
    var listener;
    listener = journalBloc.state.listen((JournalState state) {
      if (state.isResult) {
        listener.cancel();
        return;
      }
    });
    journalBloc.dispatch(RefreshJournal());
  }
}
