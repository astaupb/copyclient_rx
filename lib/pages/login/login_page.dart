import 'package:after_layout/after_layout.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../widgets/teal_outline_button.dart';
import '../register_page.dart';
import 'login_form.dart';

class LoginPage extends StatefulWidget {
  final SnackBar startSnack;
  final AuthBloc authBloc;

  const LoginPage({Key key, this.startSnack, this.authBloc}) : super(key: key);

  @override
  LoginPageState createState() {
    return new LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> with AfterLayoutMixin<LoginPage> {
  BuildContext _context;
  @override
  void afterFirstLayout(BuildContext context) {
    if (widget.startSnack != null) Scaffold.of(_context).showSnackBar(widget.startSnack);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[300],
        child: ListView(
          children: <Widget>[
            Image.asset(
              'images/icon_hires.png',
              height: 175,
            ),
            LoginForm(),
            Builder(builder: (BuildContext context) {
              _context = context;
              return Container(height: 0.0, width: 0.0);
            })
          ],
        ),
      ),
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom == 0.0
          ? TealOutlineButton(
              child: Text(
                'Registrieren',
                textAlign: TextAlign.center,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => RegisterPage(authBloc: widget.authBloc),
                  ),
                );
              },
            )
          : null,
    );
  }
}
