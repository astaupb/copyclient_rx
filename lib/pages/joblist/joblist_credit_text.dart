import 'package:blocs_copyclient/user.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreditText extends StatefulWidget {
  @override
  _CreditTextState createState() => _CreditTextState();
}

class _CreditTextState extends State<CreditText> {
  int _lastCredit = 0;

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
                _lastCredit = state.value.credit;
              }
              return Text('${(_lastCredit / 100.0).toStringAsFixed(2)}€', textScaleFactor: 1.5);
            },
          ),
        ],
      ),
    );
  }
}
