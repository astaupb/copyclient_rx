import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs_copyclient/journal.dart';

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
      body: BlocBuilder<JournalEvent, JournalState>(
        bloc: BlocProvider.of<JournalBloc>(context),
        builder: (BuildContext context, JournalState state) => (state.isResult)
            ? ListView.builder(
                itemCount: state.value.transactions.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = state.value.transactions[index];
                  return ListTile(
                    title: Text(item.description),
                    trailing: Text(
                      item.value.toString(),
                    ),
                  );
                },
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
