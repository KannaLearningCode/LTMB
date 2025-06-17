import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Sau 3 giây chuyển sang màn hình login
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.all(Radius.circular(32)),
          ),
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Image(
              image: AssetImage('assets/images/logo1.png'),
              width: 160, // <-- Tăng kích thước hình
              height: 160,
            ),
          ),
        ),
      ),
    );
  }
}
