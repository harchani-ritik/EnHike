import 'package:beacon_share/welcome_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Enhike',
        theme: ThemeData(
          fontFamily: 'FuturaBold'
        ),
        home: WelcomeScreen(),
  ));
}


