import 'package:flutter/material.dart';
import 'package:esi_flutter_chat/utilities/constants.dart';
import 'package:esi_flutter_chat/screens/login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Demo',
      theme:ThemeData(
      primarySwatch: themeColor,
        textTheme: TextTheme(
          display4: TextStyle(
            fontFamily: 'Corben',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
      ),
      home: LoginScreen(title: 'Flutter Chat'),
      debugShowCheckedModeBanner: false,
    );
  }
}