import 'package:blocs_copyclient/user.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreditText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/credit'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text('Guthaben'),
          BlocBuilder<UserBloc, UserState>(
            builder: (BuildContext context, UserState state) {
              if (state.isResult) {
                return Text('${(state.value.credit / 100.0).toStringAsFixed(2)}€',
                    textScaleFactor: 1.5);
              } else {
                return Container(width: 0.0, height: 0.0);
              }
            },
          ),
        ],
      ),
    );
  }
}
