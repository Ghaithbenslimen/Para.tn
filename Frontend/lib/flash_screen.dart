import 'package:flutter/material.dart';
import 'dart:async';
import 'package:project/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 221, 245, 229),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/—Pngtree—women nature logo_7598961.png',
              height: 300,
            ),
            const SizedBox(height: 10),
            Text(
              'Para.tn',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Poppins',
                color: Color.fromARGB(255, 5, 175, 5),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
