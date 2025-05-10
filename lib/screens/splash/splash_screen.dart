import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2),
        () => Navigator.pushReplacementNamed(context, '/login'));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment(0, -0.3),
            child: Text(
              'Planary',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: kPrimary,
                fontFamily: 'GmarketSans',
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Image(
                image: AssetImage('assets/images/doitmoney_logo.png'),
                width: 160,
              ),
            ),
          )
        ],
      ),
    );
  }
}