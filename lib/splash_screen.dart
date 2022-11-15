import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:googledrive/home_screen.dart';
import 'package:googledrive/login.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isLogin = false;
  bool isLoading = false;
  void checkLogin() async {
    setState(() {
      isLoading = !isLoading;
    });
    FirebaseAuth.instance.userChanges().listen((User? user) {
      if (user == null) {
        isLogin = false;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            ModalRoute.withName("/Login"));
      } else {
        isLogin = true;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            ModalRoute.withName("/Home"));
      }
    });
    setState(() {
      isLoading = !isLoading;
    });
  }

  @override
  void initState() {
    checkLogin();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
