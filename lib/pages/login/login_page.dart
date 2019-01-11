import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../widgets/teal_outline_button.dart';
import '../register_page.dart';
import 'login_form.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[300],
        child: ListView(
          children: <Widget>[
            Image.asset(
              'images/icon_hires.png',
              height: 200.0,
            ),
            LoginForm(),
          ],
        ),
      ),
      floatingActionButton: TealOutlineButton(
        child: Text(
          'Registrieren',
          textAlign: TextAlign.center,
        ),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => RegisterPage()));
        },
      ),
    );
  }
}
