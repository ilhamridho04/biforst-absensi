import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import '../database/db_helper.dart';
import '../loginscreen.dart';
import '../model/colors.dart';
import '../model/settings.dart';
import '../model/user.dart';
import '../utils/strings.dart';
import '../utils/utils.dart';

class SplasScreen extends StatefulWidget {
  const SplasScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SplasScreenState();
  }
}

class _SplasScreenState extends State<SplasScreen> {
  DbHelper dbHelper = DbHelper();
  Utils utils = Utils();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  double screenHeight = 0;
  double screenWidth = 0;

  String base_url = "https://biforst.id/";
  Settings? settings;
  String _isAlreadyDoSettings = 'no';

  Future selanjutnya() async {
    settings = Settings(id: 1, url: base_url, key: key_app);
    // Insert the settings
    insertSettings(settings!);

    //inser User
    User user = User(
      id: 1,
      uid: 1,
      nik: "12345678910",
      nama: "BIFORST INDONESIA",
      email: "it@biforst.id",
      role: 1,
      status: 0,
    );

    insertUser(user);
  }

  // Insert the URL and KEY
  insertSettings(Settings object) async {
    await dbHelper.newSettings(object);
    setState(() {
      _isAlreadyDoSettings = 'yes';
      goToLoginPage();
    });
  }

  insertUser(User object) async {
    await dbHelper.newUser(object);
    setState(() {
      splashScreen();
    });
  }

  getSettings() async {
    var checking = await dbHelper.countSettings();
    setState(() {
      checking > 0 ? _isAlreadyDoSettings = 'yes' : _isAlreadyDoSettings = 'no';
      goToLoginPage();
    });
  }

  // Init for the first time
  @override
  void initState() {
    super.initState();
    splashScreen();
  }

  // Show splash scree with time duration
  splashScreen() async {
    var duration = const Duration(seconds: 5);
    return Timer(duration, () {
      getSettings();
    });
  }

  // Got to main menu after scanning the QR or if user scanned the QR.
  goToLoginPage() {
    if (_isAlreadyDoSettings == 'yes') {
      Navigator.of(context).push(_createRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    if (_isAlreadyDoSettings == 'no') {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          key: _scaffoldKey,
          body: Container(
            width: double.infinity,
            margin: EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(
                  image: AssetImage('assets/images/logo.png'),
                ),
                SizedBox(
                  height: 10.0,
                ),
                SizedBox(
                  height: 120,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DefaultTextStyle(
                        style: TextStyle(
                          color: Colors.black54,
                          fontFamily: "MontserratBold",
                          fontSize: screenWidth / 16,
                        ),
                        child: AnimatedTextKit(
                          animatedTexts: [
                            RotateAnimatedText('Brave'),
                            RotateAnimatedText('Innovative'),
                            RotateAnimatedText('Futuristic'),
                            RotateAnimatedText('Original'),
                            RotateAnimatedText('Reciprocative'),
                            RotateAnimatedText('Service Excellent'),
                            RotateAnimatedText('Transformative'),
                          ],
                          onTap: () {
                            print("Tap Event");
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(
                    top: screenHeight / 26,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            selanjutnya();
                          },
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all<Color>(
                              Colors.white,
                            ),
                            backgroundColor: WidgetStateProperty.all<Color>(
                              ThemeColor.primary,
                            ),
                            shape: WidgetStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(40)),
                                side: BorderSide(
                                  color: ThemeColor.primary,
                                ),
                              ),
                            ),
                          ),
                          child: Text(
                            "Selanjutnya",
                            style: TextStyle(
                              fontSize: screenWidth / 24,
                              fontFamily: "MontserratRegular",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      color: ThemeColor.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image(
            image: AssetImage('assets/images/logo.png'),
          ),
          SizedBox(
            height: 10.0,
          ),
          SizedBox(
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DefaultTextStyle(
                  style: TextStyle(
                    color: Colors.black54,
                    fontFamily: "MontserratBold",
                    fontSize: screenWidth / 16,
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      RotateAnimatedText('Brave'),
                      RotateAnimatedText('Innovative'),
                      RotateAnimatedText('Futuristic'),
                      RotateAnimatedText('Original'),
                      RotateAnimatedText('Reciprocative'),
                      RotateAnimatedText('Service Excellent'),
                      RotateAnimatedText('Transformative'),
                    ],
                    onTap: () {
                      print("Tap Event");
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Route _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        KeyboardVisibilityProvider(
          child: LoginScreen(),
        ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}
