import 'package:attendance/utils/utils.dart';
import 'package:attendance/view/attendance.dart';
import 'package:attendance/view/components/developer_info.dart';
import 'package:attendance/view/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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
  bool isMockLocation = false;
  bool isRealDevice = false;
  bool isOnExternalStorage = false;
  bool isSafeDevice = false;
  bool isDevelopmentModeEnable = false;
  bool _isInitInProgress = false; // Declare the variable here

  Utils utils = Utils();

  late ProgressDialog pr;

  bool isLoading = true;

  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarAlt,
    FontAwesomeIcons.check,
    FontAwesomeIcons.user,
  ];

  @override
  void initState() {
    super.initState();

    initPlatformState();
    crossFadeState = CrossFadeState.showFirst;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initPlatformState() async {
    if (_isInitInProgress) return;

    setState(() {
      _isInitInProgress = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled');
      }

      bool ml = await SafeDevice.isMockLocation;
      bool rd = await SafeDevice.isRealDevice;
      bool oes = await SafeDevice.isOnExternalStorage;
      bool sd = await SafeDevice.isSafeDevice;
      bool dme = await SafeDevice.isDevelopmentModeEnable;

      setState(() {
        isMockLocation = ml;
        isRealDevice = rd;
        isOnExternalStorage = oes;
        isSafeDevice = sd;
        isDevelopmentModeEnable = dme;
        if (kDebugMode) {
          print('Ini Home : \nisMockLocation: $isMockLocation'
              '\nisRealDevice: $isRealDevice'
              '\nisOnExternalStorage: $isOnExternalStorage'
              '\nisSafeDevice: $isSafeDevice'
              '\nisDevelopmentModeEnable: $isDevelopmentModeEnable');
        }
      });
    } catch (error) {
      if (kDebugMode) {
        print('Error initializing platform state: $error');
      }
    } finally {
      setState(() {
        isLoading = false;
        _isInitInProgress = false;
      });
    }
  }

  void checkServiceStatus(
      BuildContext context, PermissionWithService permission) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text((await permission.serviceStatus).toString()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: isLoading ? Center(
        child: LoadingAnimationWidget.discreteCircle(
          color: ThemeColor.primary,
          size: 50,
        ),
      ) : !isDevelopmentModeEnable
          ? DeveloperInfo(nama: nama ?? "User")
          : FadeIndexedStack(
        index: _currentIndex,
        children: [
          Center(
            child: Text("Event Screen"),
          ),
          AttendanceScreen(),
          ProfileScreen(),
        ],
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