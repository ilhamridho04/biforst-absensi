import 'package:attendance/utils/utils.dart';
import 'package:attendance/view/attendance.dart';
import 'package:attendance/view/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:safe_device/safe_device.dart';

import 'database/db_helper.dart';
import 'model/colors.dart';
import 'model/fade_index_stack.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String? nik, nama, email, pass, isLogged, getUrl, getKey;

  // Global key scaffold
  late final CrossFadeState crossFadeState;

  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();
  double screenHeight = 0;
  double screenWidth = 0;

  DbHelper dbHelper = DbHelper();

  Color primary = Colors.blue;

  int _currentIndex = 1;
  bool isJailBroken = false;
  bool isMockLocation = false;
  bool isRealDevice = false;
  bool isOnExternalStorage = false;
  bool isSafeDevice = false;
  bool isDevelopmentModeEnable = false;

  Utils utils = Utils();

  late ProgressDialog pr;

  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarAlt,
    FontAwesomeIcons.check,
    FontAwesomeIcons.user,
  ];

  @override
  void initState() {

    initPlatformState();
    getSetting();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> initPlatformState() async {
    try {
      LocationPermission permission;
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }
      isJailBroken = await SafeDevice.isJailBroken;
      isMockLocation = await SafeDevice.isMockLocation;
      isRealDevice = await SafeDevice.isRealDevice;
      isOnExternalStorage = await SafeDevice.isOnExternalStorage;
      isSafeDevice = await SafeDevice.isSafeDevice;
      isDevelopmentModeEnable = await SafeDevice.isDevelopmentModeEnable;
      if (kDebugMode) {
        print('isJailBroken: $isJailBroken'
          '\nisMockLocation: $isMockLocation'
          '\nisRealDevice: $isRealDevice'
          '\nisOnExternalStorage: $isOnExternalStorage'
          '\nisSafeDevice: $isSafeDevice'
          '\nisDevelopmentModeEnable: $isDevelopmentModeEnable');
      }
      setState(() {});
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
    }
  }

  void getPermissionAttendance() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
  }

  void getSetting() async {
    var getSettings = await dbHelper.getSettings(1);
    var getUser = await dbHelper.getUser(1);
    setState(() {
      getUrl = getSettings.url;
      getKey = getSettings.key;
      email = getUser.email;
      nama = getUser.nama;
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: isDevelopmentModeEnable != false
          ? FadeIndexedStack(
        index: _currentIndex,
        children: [
          Center(
            child: Text("Event Screen"),
          ),
          AttendanceScreen(),
          ProfileScreen(),
        ],
      )
          : Container(
        width: double.infinity,
        margin: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('assets/images/secure.png'),
            ),
            SizedBox(
              height: 10.0,
            ),
            Text(
              "Oops ada yang salah.",
              style: TextStyle(
                color: ThemeColor.red,
                fontFamily: "MontserratBold",
                fontSize: screenWidth / 20,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 20.0,
            ),
            Text(
              "Hi $nama",
              style: TextStyle(
                color: ThemeColor.black,
                fontFamily: "MontserratBold",
                fontSize: screenWidth / 24,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 20.0,
            ),
            Container(
              child: Html(
                data:
                "<p>Kami mendeteksi bahwa perangkat anda mengaktifkan <b style='color: red;'>opsi pengembang</b>.</p></p>Silahkan matikan <b style='color: red;'>opsi pengembang</b> pada perangkat anda untuk menggunakan aplikasi kami.</p>",
                style: {
                  "body": Style(
                    color: ThemeColor.grey,
                    fontFamily: "MontserratLight",
                    fontSize: FontSize(16.0),
                  ),
                },
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    child: Container(
                      height: 45,
                      width: 95,
                      margin: EdgeInsets.only(top: screenHeight / 18),
                      decoration: BoxDecoration(
                        color: ThemeColor.red,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(30),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Lanjutkan",
                          style: TextStyle(
                            fontFamily: "MontserratBold",
                            fontSize: screenWidth / 26,
                            color: Colors.white,
                          ),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 70,
          margin: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 24,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(40)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // perulangan Expanded
                for (int i = 0; i < navigationIcons.length; i++) ...<Expanded>{
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = i;
                        });
                      },
                      child: Container(
                        height: screenHeight,
                        width: screenWidth,
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                navigationIcons[i],
                                color: i == _currentIndex
                                    ? ThemeColor.primary
                                    : Colors.black54,
                                size: i == _currentIndex ? 32 : 26,
                              ),
                              i == _currentIndex
                                  ? Container(
                                margin: EdgeInsets.only(top: 6),
                                height: 3,
                                width: 24,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(40)),
                                  color: ThemeColor.primary,
                                ),
                              )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                }
              ],
            ),
          ),
        ),
      ),
    );
  }
}
