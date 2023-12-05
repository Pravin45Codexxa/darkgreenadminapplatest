import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Helper/Color.dart';
import '../../Helper/Session.dart';
import '../../Helper/String.dart';
import '../Home.dart';
import '../Authentication/Login.dart';

//splash screen of app
class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashScreen createState() => _SplashScreen();
}

class _SplashScreen extends State<Splash> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    super.initState();
    startTime();
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            color: Colors.white,
            child: Center(
              child: Image(image: AssetImage("assets/images/screensplash.png"),
                height: 300,
                width: 350,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Image.asset(
            'assets/images/doodle.png',
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      ),
    );
  }
  startTime() async {
    var duration = const Duration(seconds: 2);
    return Timer(duration, navigationPage);
  }

  Future<void> navigationPage() async {
    bool isFirstTime = await getPrefrenceBool(isLogin);
    if (isFirstTime) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => const Home(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => const Login(),
        ),
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }
}
