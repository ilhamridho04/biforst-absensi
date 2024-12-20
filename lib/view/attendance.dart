import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:dio/dio.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../controller/custom_dialog_box.dart';
import '../database/db_helper.dart';
import '../loginscreen.dart';
import '../model/attendance.dart';
import '../model/colors.dart';
import '../model/settings.dart';
import '../model/user.dart';
import '../utils/strings.dart';
import '../utils/utils.dart';
import 'downloads.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late TargetPlatform? platform;
  bool? _isMock;
  String? nik = "",
      nama = "",
      email = "",
      pass = "",
      isLogged = "",
      getUrl = "",
      getKey = "",
      _tanggalMasuk = "",
      _jamMasuk = "",
      _jamPulang = "",
      jamMasuk = "",
      _timeForCountUp = "",
      _elapsedTime = "",
      stringImage = "",
      getPathArea = '/api/auth/area',
      getPath = '/api/auth/hadir';
  String jamNull = "--:--:--";
  int? statusLogin, uid, role, absen_id;
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = Colors.blue;

  DbHelper dbHelper = DbHelper();
  Utils utils = Utils();

  // Geolocation
  Position? _currentPosition;
  String? _currentAddress;
  final Geolocator geoLocator = Geolocator();

  late ProgressDialog pd;
  late bool clickButton = false, isLoading = true;
  var subscription, getId, _value;
  double setAccuracy = 200.0;
  File? _image, newImage;

  List dataArea = [];

  late Timer _timer;
  Settings? settings;

  @override
  void initState() {
    getSetting();
    _getCurrentPosition();
    _getPermission();
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _getPermission() async {
    getPermissionAttendance();
    _checkGps();
  }

  void getPermissionAttendance() async {
    await [
      Permission.storage,
      Permission.camera,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> getImage() async {
    try {
      final _image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxHeight: 1280,
        maxWidth: 720,
        preferredCameraDevice: CameraDevice.front,
      );
      if (_image == null) return;
      final File imageTemp = File(_image.path);
      this._image = imageTemp;
      setState(() {
        sendData();
      });
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

// Send data post via http
  Future<void> sendData() async {
    if (_value == null) {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          // Alert Dialog
          utils.showAlertDialog(
              select_area, "warning", AlertType.warning, context, true);
        });
      });
      return;
    }
    // Get info for attendance
    var dataKey = getKey;
    String? fileName = _image!.path.split('/').last;
    // Add data to map
    Map<String, dynamic> body = {
      'key': dataKey,
      'worker_id': uid,
      'q': 'in',
      'lat': _currentPosition!.latitude,
      'longt': _currentPosition!.longitude,
      'area_id': _value,
      'absen_area': _currentAddress,
      'file': await MultipartFile.fromFile(_image!.path, filename: fileName),
    };
    // Sending the data to server
    String url = utils.getRealUrl(getUrl!, getPath!);
    Dio dio = Dio();
    FormData formData = FormData.fromMap(body);

    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(
      max: 100,
      msg: 'Hampir selesai...',
      progressType: ProgressType.valuable,
      backgroundColor: ThemeColor.white,
      progressValueColor: ThemeColor.primary,
      progressBgColor: Colors.white70,
      msgColor: ThemeColor.black,
      valueColor: ThemeColor.primary,
      completed: Completed(completedMsg: "Upload selesai !"),
    );

    final response = await dio.post(
      url,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: (rec, total) {
        int progress = (((rec / total) * 100).toInt());
        pd.update(
          value: progress,
          msg: 'Mengirim file...',
        );
      },
    );

    var data = response.data;
    // Show response from server via snackBar
    if (data['message'] == 'Success!') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          String urlCekhadir =
          utils.getRealUrl(getUrl!, "/api/auth/kehadiran/" + "$uid");
          CekKehadiran(urlCekhadir);
          Attendance attendance = Attendance(
            id: data['id'],
            date: data['date'],
            time: data['time'],
            location: data['location'],
            type: "Check-In",
          );

          // Insert the attendance
          insertAttendance(attendance);
          subscription.cancel();

          Alert(
            context: context,
            type: AlertType.success,
            title: "Success",
            desc: "$attendance_show_alert-in $attendance_success_ms",
            buttons: [
              DialogButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                width: 120,
                child: Text(
                  ok_text,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              )
            ],
          ).show();
        });
      });
    } else if (data['message'] == 'key_not_valid') {
      if (pd.isOpen()) {
        pd.close();
      }
      // Alert Dialog
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialogBox(
              title: "Pembaruan tersedia !",
              descriptions: key_not_valid,
              img: Image.asset('assets/images/logo.png'),
              btn: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => DownloadsPage()));
                },
                child: Text(
                  "Download",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: "MontserratRegular",
                  ),
                ),
              ),
            );
          });
    } else if (data['message'] == 'cannot_attend') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          // Alert Dialog
          utils.showAlertDialog(
              '$outside_area', "warning", AlertType.warning, context, true);
        });
      });
    } else if (data['message'] == 'location_not_found') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          pd.close();
          // Alert Dialog
          utils.showAlertDialog('$location_not_found', "warning",
              AlertType.warning, context, true);
        });
      });
    } else if (data['message'] == 'sudah_cek_in') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          subscription.cancel();
          Alert(
            context: context,
            type: AlertType.info,
            title: "Berhasil",
            desc: "$already_check_in",
            buttons: [
              DialogButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                width: 120,
                child: Text(
                  ok_text,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              )
            ],
          ).show();
        });
      });
    } else if (data['message'] == 'check_in_first') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          // Alert Dialog
          utils.showAlertDialog(
              '$check_in_first', "warning", AlertType.warning, context, true);
        });
      });
    } else if (data['message'] == 'error_something_went_wrong') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          // Alert Dialog
          utils.showAlertDialog('$attendance_error_server', "Error",
              AlertType.error, context, true);
        });
      });
    } else {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          // Alert Dialog
          utils.showAlertDialog(response.data.toString(), "Error",
              AlertType.error, context, true);
        });
      });
    }
  }

  Future<void> _cekOut() async {
    // pr.show();
    // Get info for attendance
    var dataKey = getKey;
    // Add data to map
    Map<String, dynamic> body = {
      'key': dataKey,
      'worker_id': uid,
      'q': 'out',
      'lat': _currentPosition!.latitude,
      'longt': _currentPosition!.longitude,
      'absen_area': _currentAddress,
    };
    // Sending the data to server
    final uri = utils.getRealUrl(getUrl!, getPath!);
    Dio dio = Dio();
    FormData formData = FormData.fromMap(body);

    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(
      max: 100,
      msg: 'Hampir selesai...',
      progressType: ProgressType.valuable,
      completed: Completed(
        completedMsg: "Absen selesai !",
        // completedImage: AssetImage(
        //   widget.future,
        // ),
      ),
    );

    final response = await dio.post(
      uri,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: (rec, total) {
        int progress = (((rec / total) * 100).toInt());
        pd.update(
          value: progress,
          msg: 'Mengirim file...',
        );
      },
    );

    var data = response.data;
    // Show response from server via snackBar
    if (data['message'] == 'Success!') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          String urlCekhadir =
          utils.getRealUrl(getUrl!, "/api/auth/kehadiran/" + "$uid");
          CekKehadiran(urlCekhadir);
          subscription.cancel();
          Alert(
            context: context,
            type: AlertType.success,
            title: "Success",
            desc: "$attendance_show_alert-in $attendance_success_ms",
            buttons: [
              DialogButton(
                child: Text(
                  ok_text,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                width: 120,
              )
            ],
          ).show();
        });
      });
    } else if (data['message'] == 'cannot_attend') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          // Alert Dialog
          utils.showAlertDialog(
              outside_area, "warning", AlertType.warning, context, true);
        });
      });
    } else if (data['message'] == 'location_not_found') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          // Alert Dialog
          utils.showAlertDialog(
              location_not_found, "warning", AlertType.warning, context, true);
        });
      });
    } else if (data['message'] == 'sudah_cek_in') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          subscription.cancel();
          Alert(
            context: context,
            type: AlertType.info,
            title: "Berhasil",
            desc: "$already_check_in",
            buttons: [
              DialogButton(
                child: Text(
                  ok_text,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                width: 120,
              )
            ],
          ).show();
        });
      });
    } else if (data['message'] == 'check_in_first') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          // Alert Dialog
          utils.showAlertDialog(
              check_in_first, "warning", AlertType.warning, context, true);
        });
      });
    } else if (data['message'] == 'error_something_went_wrong') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          // Alert Dialog
          utils.showAlertDialog(
              attendance_error_server, "Error", AlertType.error, context, true);
        });
      });
    } else {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          // Alert Dialog
          utils.showAlertDialog(response.data.toString(), "Error",
              AlertType.error, context, true);
        });
      });
    }
  }

  insertAttendance(Attendance object) async {
    final insert = await dbHelper.newAttendances(object);
    debugPrint("Insert ASBEN :" + insert.toString());
  }

  // Check the GPS is on
  Future<void> _checkGps() async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialogBox(
              title: cant_get_current_location,
              descriptions: please_make_sure_enable_gps,
              img: Image.asset('assets/images/logo.png'),
              btn: ElevatedButton(
                onPressed: () async {
                  final AndroidIntent intent = AndroidIntent(
                      action: 'android.settings.LOCATION_SOURCE_SETTINGS');

                  await intent.launch();
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: Text(
                  "Ok",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: "MontserratRegular",
                  ),
                ),
              ),
            );
          },
        );
      }
    }
  }

  void getSetting() async {
    var getSettings = await dbHelper.getSettings(1);
    var getUser = await dbHelper.getUser(1);
    setState(() {
      getUrl = getSettings.url;
      getKey = getSettings.key;
      email = getUser.email;
      nama = getUser.nama;
      uid = getUser.uid;
      statusLogin = getUser.status;
      getAreaApi();
    });
  }

  void getAreaApi() async {
    final uri = utils.getRealUrl(getUrl!, getPathArea!);
    Dio dio = Dio();
    final response = await dio.get(uri);

    var data = response.data;

    if (data['message'] == 'success') {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          final uri =
          utils.getRealUrl(getUrl!, "/api/auth/kehadiran/$uid");
          CekKehadiran(uri);
          dataArea = data['area'];
        });
      });
    } else {
      Future.delayed(Duration(seconds: 0)).then((value) {
        setState(() {
          final uri =
          utils.getRealUrl(getUrl!, "/api/auth/kehadiran/" + "$uid");
          CekKehadiran(uri);
          dataArea = [
            {"id": 0, "name": "No Data Area"}
          ];
        });
      });
    }
  }

  void CekKehadiran(_url) async {
    Dio dio = Dio();
    final response = await dio.get(_url);
    Future.delayed(Duration(seconds: 0)).then((value) {
      setState(() {
        var data = response.data;
        if (data['message'] == "sudah_cek_in") {
          _tanggalMasuk = data['user']['tanggal'];
          _jamMasuk = data['user']['jam'];
          jamMasuk = data['user']['in'];
          _jamPulang = data['user']['out'];
        } else {
          _tanggalMasuk = data['user']['tanggal'];
          _jamMasuk = data['user']['jam'];
          jamMasuk = data['user']['in'];
          _jamPulang = data['user']['out'];
        }
        isLoading = false;
      });
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    Future.delayed(Duration(seconds: 3)).then((value) {
      setState(() {
        if (_currentAddress == null) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return CustomDialogBox(
                  title: "Lokasi perangkat",
                  descriptions: please_make_sure_enable_gps,
                  img: Image.asset('assets/images/logo.png'),
                  btn: ElevatedButton(
                    onPressed: () async {
                      exit(0);
                    },
                    child: Text(
                      "Ok",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: "MontserratRegular",
                      ),
                    ),
                  ),
                );
              });
        }
      });
    });

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Layanan lokasi dinonaktifkan. Harap aktifkan layanan lokasi')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomDialogBox(
                title: "Lokasi perangkat",
                descriptions: please_make_sure_enable_gps,
                img: Image.asset('assets/images/logo.png'),
                btn: ElevatedButton(
                  onPressed: () async {
                    final AndroidIntent intent = AndroidIntent(
                        action: 'android.settings.LOCATION_SOURCE_SETTINGS');
                    await intent.launch();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: Text(
                    "Ok",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "MontserratRegular",
                    ),
                  ),
                ),
              );
            });
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return CustomDialogBox(
              title: "Lokasi perangkat",
              descriptions:
              "Izin lokasi ditolak secara permanen, kami tidak dapat meminta izin.",
              img: Image.asset('assets/images/logo.png'),
              btn: ElevatedButton(
                onPressed: () async {
                  final AndroidIntent intent = AndroidIntent(
                      action: 'android.settings.LOCATION_SOURCE_SETTINGS');

                  await intent.launch();
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: Text(
                  "Ok",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: "MontserratRegular",
                  ),
                ),
              ),
            );
          });
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
      _isMock = position.isMocked;
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        Future.delayed(Duration(seconds: 0)).then((value) {
          _currentAddress =
          '${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
        });
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    _timeForCountUp = "$_tanggalMasuk $_jamMasuk";
    final Duration diff = DateTime.parse(_timeForCountUp!).difference(now);
    _elapsedTime =
    "${diff.inHours.abs()} jam, ${(diff.inMinutes.abs() % 60)} menit, ${(diff.inSeconds.abs() % 60)} detik";
  }

  void _signOut() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      preferences.remove("status");
      preferences.remove("email");
      preferences.remove("password");
      preferences.remove("id");
      preferences.remove("key");

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
      dbHelper.updateUser(user);
    });
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => KeyboardVisibilityProvider(
          child: LoginScreen(),
        )));
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: isLoading
          ? Center(
        child: LoadingAnimationWidget.discreteCircle(
          color: ThemeColor.primary,
          size: 50,
        ),
      )
          : _isMock != true
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(
                          top: 45,
                        ),
                        child: Text(
                          "Selamat datang",
                          style: TextStyle(
                            color: Colors.black54,
                            fontFamily: "MontserratBold",
                            fontSize: screenWidth / 20,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        nama != null && nama!.isNotEmpty ? nama! : "Demo Biforst",
                        style: TextStyle(
                          color: Colors.black54,
                          fontFamily: "MontserratRegular",
                          fontSize: screenWidth / 26,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return CustomDialogBox(
                              title: "Keluar aplikasi",
                              descriptions:
                              "Anda yakin ingin keluar dari aplikasi ?",
                              img: Image.asset(
                                  'assets/images/logo.png'),
                              btn: ElevatedButton(
                                onPressed: () {
                                  _signOut();
                                },
                                child: Text(
                                  "Ok",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: "MontserratRegular",
                                  ),
                                ),
                              ),
                            );
                          });
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(
                        top: 32,
                      ),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: ThemeColor.red.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Icon(
                          Icons.logout_outlined,
                          color: ThemeColor.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 18,
              ),
              Container(
                margin: EdgeInsets.only(
                  bottom: screenHeight / 50,
                ),
                child: _dashLine(),
              ),
              Row(
                children: [
                  Icon(
                    Icons.place,
                    size: 24,
                    color: ThemeColor.red,
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    child: Text(
                      "$_currentAddress",
                      style: TextStyle(
                        color: ThemeColor.primary,
                        fontSize: screenWidth / 26,
                        fontFamily: "MontserratRegular",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(top: 10),
                child: Text(
                  "Status hari ini",
                  style: TextStyle(
                    color: Colors.black54,
                    fontFamily: "MontserratBold",
                    fontSize: screenWidth / 18,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  top: 12,
                  bottom: 32,
                ),
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(2, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Jam Masuk",
                            style: TextStyle(
                              color: Colors.black54,
                              fontFamily: "MontserratRegular",
                              fontSize: screenWidth / 20,
                            ),
                          ),
                          Text(
                            "$jamMasuk",
                            style: TextStyle(
                              fontFamily: "MontserratRegular",
                              fontSize: screenWidth / 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Jam Pulang",
                            style: TextStyle(
                              color: Colors.black54,
                              fontFamily: "MontserratRegular",
                              fontSize: screenWidth / 20,
                            ),
                          ),
                          Text(
                            "$_jamPulang",
                            style: TextStyle(
                              fontFamily: "MontserratRegular",
                              fontSize: screenWidth / 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    text: DateTime.now().day.toString(),
                    style: TextStyle(
                      color: ThemeColor.primary,
                      fontFamily: "MontserratRegular",
                      fontSize: screenWidth / 18,
                    ),
                    children: [
                      TextSpan(
                        text: DateFormat(' MMMM yyyy', 'id_ID')
                            .format(DateTime.now()),
                        style: TextStyle(
                          color: ThemeColor.grey,
                          fontFamily: "MontserratRegular",
                          fontSize: screenWidth / 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              StreamBuilder(
                  stream: Stream.periodic(Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('HH:mm:ss').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.black54,
                          fontFamily: "MontserratRegular",
                          fontSize: screenWidth / 20,
                        ),
                      ),
                    );
                  }),
              Container(
                margin: EdgeInsets.only(
                  top: screenHeight / 40,
                ),
                child: _dashLine(),
              ),
              jamMasuk == jamNull
                  ? _pilihArea()
                  : _jamPulang == jamNull
                  ? Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.only(
                      top: screenHeight / 26,
                    ),
                    child: Text(
                      "Waktu kerja",
                      style: TextStyle(
                        color: Colors.black54,
                        fontFamily: "MontserratRegular",
                        fontSize: screenWidth / 20,
                      ),
                    ),
                  ),
                  StreamBuilder(
                      stream: Stream.periodic(
                          Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        _getTime();
                        return Container(
                          height: screenHeight / 16,
                          margin: EdgeInsets.only(
                            top: 8,
                            bottom: 24,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeColor.primary,
                            borderRadius: BorderRadius.all(
                                Radius.circular(15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius:
                            const BorderRadius.all(
                                Radius.circular(15)),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                // perulangan Expanded
                                Text(
                                  '$_elapsedTime',
                                  style: TextStyle(
                                    fontFamily:
                                    "MontserratRegular",
                                    fontSize:
                                    screenWidth / 18,
                                    color: ThemeColor.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                ],
              )
                  : SizedBox(),
              _jamPulang == jamNull
                  ? Container(
                margin: EdgeInsets.only(
                  top: 20,
                ),
                child: Builder(
                  builder: (context) {
                    final GlobalKey<SlideActionState> key =
                    GlobalKey();
                    return jamMasuk == jamNull
                        ? SlideAction(
                      text: "Geser untuk hadir",
                      textStyle: TextStyle(
                        color: ThemeColor.primary,
                        fontSize: screenWidth / 20,
                        fontFamily: "MontserratLight",
                      ),
                      outerColor: ThemeColor.white,
                      innerColor: ThemeColor.primary,
                      key: key,
                      onSubmit: () {
                        getImage();
                        return null;
                      },
                    )
                        : SlideAction(
                      text: "Geser untuk pulang",
                      textStyle: TextStyle(
                        color: ThemeColor.redForLoc,
                        fontSize: screenWidth / 20,
                        fontFamily: "MontserratLight",
                      ),
                      outerColor: Colors.white,
                      innerColor: ThemeColor.red,
                      key: key,
                      onSubmit: () {
                        _cekOut();
                        return null;
                      },
                    );
                  },
                ),
              )
                  : _aktivitasSelesai(),
            ],
          ),
        ),
      )
          : Container(
        width: double.infinity,
        margin: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
              child: Image(
                  image: AssetImage('assets/images/location.png'),
                  width: 150,
                  fit: BoxFit.fill),
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
              nama != null && nama!.isNotEmpty ? nama! : "Demo Biforst",
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
            Html(
              data:
              "<p>Kami mendeteksi bahwa perangkat anda mengaktifkan <b style='color: red;'>Lokasi Palsu</b>.</p></p>Silahkan matikan <b style='color: red;'>Lokasi Palsu</b> pada perangkat anda untuk menggunakan aplikasi kami.</p>",
              style: {
                "body": Style(
                  color: ThemeColor.grey,
                  fontFamily: "MontserratLight",
                  fontSize: FontSize(16.0),
                ),
              },
            ),
            Container(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      exit(0);
                    },
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
    );
  }

  Widget _aktivitasSelesai() {
    return Container(
      margin: EdgeInsets.only(top: screenHeight / 16),
      child: Text(
        "Anda telah menyelesaikan absensi hari ini.",
        style: TextStyle(
            fontSize: screenWidth / 24, fontFamily: "MontserratRegular"),
      ),
    );
  }

  Widget _dashLine() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 10.0;
        final dashHeight = screenHeight / 512;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: ThemeColor.lightGrey),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _pilihArea() {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: 40),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(
                Icons.list,
                size: 16,
                color: ThemeColor.white,
              ),
              SizedBox(
                width: 4,
              ),
              Expanded(
                child: Text(
                  'Pilih Area',
                  style: TextStyle(
                    fontFamily: "MontserratRegular",
                    fontSize: screenWidth / 24,
                    color: ThemeColor.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          items: dataArea.map((item) {
            return DropdownMenuItem(
              value: item['id'].toString(),
              child: Text(
                item['name'],
                style: TextStyle(
                  fontFamily: "MontserratRegular",
                  fontSize: screenWidth / 24,
                  color: ThemeColor.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          value: _value,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
          },
        ),
      ),
    );
  }
}

class ItemHolder {
  ItemHolder({this.name, this.task});

  final String? name;
  final TaskInfo? task;
}

class TaskInfo {
  TaskInfo({this.name, this.link});

  final String? name;
  final String? link;

  String? taskId;
  int? progress = 0;
  DownloadTaskStatus? status = DownloadTaskStatus.undefined;
}
