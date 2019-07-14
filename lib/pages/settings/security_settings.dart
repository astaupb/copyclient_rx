import 'dart:async';

import 'package:blocs_copyclient/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SecuritySettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
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
      ),
      body: BlocBuilder<TokensEvent, TokensState>(
        bloc: BlocProvider.of<TokensBloc>(context),
        builder: (BuildContext context, state) {
          if (state.isResult) {
            final List<Token> tokens = state.value.reversed.toList();
            return RefreshIndicator(
                child: ListView.builder(
                  itemCount: tokens.length,
                  itemBuilder: (BuildContext context, int i) {
                    return ListTile(
                      leading: Text(tokens[i].clientType.toString().split('.').last),
                      title: Text(tokens[i].ip),
                      subtitle: Text(tokens[i].created.toString().split('.').first),
                      trailing: Text(tokens[i].location),
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
}
