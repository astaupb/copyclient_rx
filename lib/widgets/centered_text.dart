import 'package:flutter/widgets.dart';

class CenteredText extends StatelessWidget {
  final String text;

  CenteredText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(left: 40.0, right: 40.0),
        child: Text(text),
      ),
    );
  }
}
