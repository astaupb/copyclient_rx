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
    return BlocBuilder<UserEvent, UserState>(
      bloc: BlocProvider.of<UserBloc>(context),
      builder: (BuildContext context, state) {
        if (state.isResult) {
          return UserAccountsDrawerHeader(
            accountName: Text(
              state.value?.username,
              style: TextStyle(fontSize: 27.0),
            ),
            accountEmail: Text(
              'Restliches Guthaben: ${state.value?.credit?.toStringAsFixed(2)}€',
            ),
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(
                    _headerImages[math.Random().nextInt(_headerImages.length)],
                  ),
                  fit: BoxFit.fill),
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
