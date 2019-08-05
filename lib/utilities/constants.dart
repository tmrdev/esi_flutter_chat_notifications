import 'dart:ui';

import 'package:flutter/material.dart';

// blue
MaterialColor themeColor = Colors.blue;
//final themeColor = Color.fromRGBO(243, 241, 150, 1);

final primaryColor = new Color(0xff203152);
final greyColor = new Color(0xffaeaeae);
final greyColor2 = new Color(0xffE8E8E8);
final testColor = new Color(0xFFb74093);

// using const or constant for chat text limit int below may have been causing issues and never set the limit
// changing from const to final for now and tested that it works
final int CHAT_TEXT_LIMIT = 150;
final int GROUP_BY_TITLE_WORD_THRESHOLD = 2;
