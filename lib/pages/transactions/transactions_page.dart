import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs_copyclient/journal.dart';

import 'transactions_tile.dart';
import '../../widgets/centered_text.dart';

class TransactionsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaktionen'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(),
        child: BlocBuilder<JournalEvent, JournalState>(
          bloc: BlocProvider.of<JournalBloc>(context),
          builder: (BuildContext context, JournalState state) {
            if (state.isResult) {
              final reverseList = state.value.transactions.reversed.toList();
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
                    child: TransactionsTile(reverseList[index - 1]),
                  );
                },
              );
            } else if (state.isException) {
              return CenteredText(state.error.toString());
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    final JournalBloc journalBloc = BlocProvider.of<JournalBloc>(context);
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
