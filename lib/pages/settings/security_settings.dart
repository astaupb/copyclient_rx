import 'dart:async';

import 'package:blocs_copyclient/tokens.dart';
import 'package:copyclient_rx/user_agent_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ActionButton { deleteAll }

class AppIcon extends Column {
  final String iconText;

  AppIcon({this.iconText = ''});

  @override
  List<Widget> get children => [
        Image.asset('images/icon_hires.png', height: 30),
        Text(iconText),
      ];

  @override
  MainAxisAlignment get mainAxisAlignment => MainAxisAlignment.center;

  @override
  MainAxisSize get mainAxisSize => MainAxisSize.min;
}

class SecuritySettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  TokensBloc tokensBloc;
  List<Token> lastTokens = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Angemeldete Geräte'),
        actions: <Widget>[
          PopupMenuButton<ActionButton>(
            onSelected: _onSelectActionMenu,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<ActionButton>(
                  value: ActionButton.deleteAll, child: Text('Alle anderen Geräte ausloggen'))
            ],
          ),
        ],
      ),
      body: BlocBuilder<TokensBloc, TokensState>(
        builder: (BuildContext context, state) {
          if (state.isResult) {
            lastTokens = state.value.reversed.toList();
          }
          return RefreshIndicator(
            onRefresh: () => onRefresh(),
            child: ListView.builder(
              itemCount: lastTokens.length,
              itemBuilder: (BuildContext context, int i) {
                return ListTile(
                  leading: clientTypeIcon(lastTokens[i].clientType),
                  title: Text('Ort: ${lastTokens[i].location}, IP: ${lastTokens[i].ip}'),
                  subtitle: Text(
                      'Erstellt: ${lastTokens[i].created.toLocal().toString().split('.').first}'),
                  trailing: IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () => _onPressedDelete(lastTokens[i].id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget clientTypeIcon(ClientType type) {
    switch (type) {
      case ClientType.chrome:
        return Icon(UserAgentIcons.chrome);
      case ClientType.firefox:
        return Icon(UserAgentIcons.firefox);
      case ClientType.safari:
        return Icon(UserAgentIcons.safari);
      case ClientType.curl:
        return Icon(UserAgentIcons.curl_symbol);
      case ClientType.dartio:
        return AppIcon(iconText: 'App');
      case ClientType.electron:
        return AppIcon(iconText: 'PC');
      case ClientType.unknown:
        return Icon(Icons.device_unknown);
      default:
        return Text(type.toString().split('.').last);
    }
  }

  @override
  void initState() {
    tokensBloc = BlocProvider.of<TokensBloc>(context);
    tokensBloc.onGetTokens();
    super.initState();
  }

  Future<void> onRefresh() async {
    StreamSubscription listener;
    listener = tokensBloc.stream.listen((TokensState state) {
      if (state.isResult) {
        listener.cancel();
        return;
      }
    });
    tokensBloc.onGetTokens();
  }

  void _onPressedDelete(int id) {
    tokensBloc.onDeleteToken(id);
  }

  void _onSelectActionMenu(ActionButton action) {
    switch (action) {
      case ActionButton.deleteAll:
        tokensBloc.onDeleteTokens();
        break;
      default:
        return;
    }
  }
}
