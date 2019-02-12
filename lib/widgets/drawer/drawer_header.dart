import 'dart:math' as math;

import 'package:blocs_copyclient/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const List<String> _headerImages = [
  'images/drawer/screen.jpeg',
];

class DrawerHeader extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DrawerHeaderState();
}

class _DrawerHeaderState extends State<DrawerHeader> {
  @override
  Widget build(BuildContext context) {
    return UserAccountsDrawerHeader(
      accountName: BlocBuilder<UserEvent, UserState>(
        bloc: BlocProvider.of<UserBloc>(context),
        builder: (BuildContext context, state) {
          if (state.isResult) {
            return Text(state.value?.name, style: TextStyle(fontSize: 27.0));
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      accountEmail: BlocBuilder<UserEvent, UserState>(
        bloc: BlocProvider.of<UserBloc>(context),
        builder: (BuildContext context, state) {
          if (state.isResult) {
            return Text(
              'Restliches Guthaben: ${((state.value?.credit ?? 0) / 100.0).toStringAsFixed(2)}€',
            );
          } else {
            return Container(width: 0.0, height: 0.0);
          }
        },
      ),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            _headerImages[math.Random().nextInt(_headerImages.length)],
          ),
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
