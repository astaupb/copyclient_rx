import 'dart:async';

import 'package:blocs_copyclient/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SecuritySettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  List<Token> lastTokens = [];

  @override
  void initState() {
    BlocProvider.of<TokensBloc>(context).onGetTokens();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Angemeldete Geräte'),
        actions: <Widget>[
          PopupMenuButton<int>(
            onSelected: _onSelectActionMenu,
            itemBuilder: (BuildContext context) =>
                [PopupMenuItem<int>(value: 0, child: Text('Alle anderen Geräte ausloggen'))],
          ),
        ],
      ),
      body: BlocBuilder<TokensEvent, TokensState>(
        bloc: BlocProvider.of<TokensBloc>(context),
        builder: (BuildContext context, state) {
          if (state.isResult) {
            final List<Token> tokens = state.value.reversed.toList();
            lastTokens = tokens;
            return RefreshIndicator(
                child: ListView.builder(
                  itemCount: tokens.length,
                  itemBuilder: (BuildContext context, int i) {
                    return ListTile(
                      leading: Text(tokens[i].clientType.toString().split('.').last),
                      title: Text('Ort: ${tokens[i].location}, IP: ${tokens[i].ip}'),
                      subtitle: Text('Erstellt: ${tokens[i].created.toString().split('.').first}'),
                      trailing: IconButton(
                        icon: Icon(Icons.cancel),
                        onPressed: () => _onPressedDelete(tokens[i].id),
                      ),
                    );
                  },
                ),
                onRefresh: () => onRefresh());
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<void> onRefresh() async {
    TokensBloc bloc = BlocProvider.of<TokensBloc>(context);
    StreamSubscription listener;
    listener = bloc.state.listen((TokensState state) {
      if (state.isResult) {
        listener.cancel();
        return;
      }
    });
    bloc.onGetTokens();
  }

  void _onPressedDelete(int id) {
    BlocProvider.of<TokensBloc>(context).onDeleteToken(id);
  }

  void _onSelectActionMenu(int value) {
    if (value == 0) {
      lastTokens.removeAt(0);
      for (Token token in lastTokens) {
        BlocProvider.of<TokensBloc>(context).onDeleteToken(token.id);
      }
    }
  }
}
