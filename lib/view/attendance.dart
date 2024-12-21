import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:safe_device/safe_device.dart';
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

  bool isMockLocation = false;
  bool isRealDevice = false;
  bool isOnExternalStorage = false;
  bool isSafeDevice = false;
  bool isDevelopmentModeEnable = false;
  bool _isInitInProgress = false;

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
  bool isUpdate = false;
  var subscription, getId, _value;
  double setAccuracy = 200.0;
  File? _image, newImage;

  List dataArea = [];

  late Timer _timer;
  Settings? settings;

  @override
  void initState() {
    super.initState();

    getSetting();
    initPlatformState();
  }

  @override
  void dispose() {
    if(_timer.isActive) {
      _timer.cancel();
    }
    super.dispose();
  }

  Future<void> getImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxHeight: 1280,
        maxWidth: 720,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null) return;
      final File imageTemp = File(image.path);
      _image = imageTemp;
      setState(() {
        sendData();
      });
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to pick image: $e');
      }
    }
  }

// Send data post via http
  Future<void> sendData() async {
    if (_value == null) {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(
            select_area, "warning", AlertType.warning, context, true);
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
      msg: 'Sedang upload gambar...',
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
    pd.close();

    var data = response.data;
    // Show response from server via snackBar
    if (data['message'] == 'Success!') {
      String urlCekhadir =
      utils.getRealUrl(getUrl!, "/api/auth/kehadiran/" + "$uid");
      await cekKehadiran(urlCekhadir);

      setState(() {
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
        utils.showAlertDialog(
            attendance_success_ms, "success", AlertType.success, context, true);
      });
    } else if (data['message'] == 'key_not_valid') {
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
                  setState(() {
                    isUpdate = true;
                  });
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => DownloadsPage())
                  );
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
          }
      );
    } else if (data['message'] == 'cannot_attend') {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(
            outside_area, "warning", AlertType.warning, context, true);
      });
    } else if (data['message'] == 'location_not_found') {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(location_not_found, "warning",
            AlertType.warning, context, true);
      });
    } else if (data['message'] == 'sudah_cek_in') {
      setState(() {
        subscription.cancel();
        Alert(
          context: context,
          type: AlertType.info,
          title: "Berhasil",
          desc: already_check_in,
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
    } else if (data['message'] == 'check_in_first') {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(
            check_in_first, "warning", AlertType.warning, context, true);
      });
    } else if (data['message'] == 'error_something_went_wrong') {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(attendance_error_server, "Error",
            AlertType.error, context, true);
      });
    } else {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(response.data.toString(), "Error",
            AlertType.error, context, true);
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
      String urlCekhadir =
      utils.getRealUrl(getUrl!, "/api/auth/kehadiran/" + "$uid");
      await cekKehadiran(urlCekhadir);
      subscription.cancel();
      setState(() {
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
    } else if (data['message'] == 'cannot_attend') {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(
            outside_area, "warning", AlertType.warning, context, true);
      });
    } else if (data['message'] == 'location_not_found') {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(
            location_not_found, "warning", AlertType.warning, context, true);
      });
    } else if (data['message'] == 'sudah_cek_in') {
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
    } else if (data['message'] == 'check_in_first') {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(
            check_in_first, "warning", AlertType.warning, context, true);
      });
    } else if (data['message'] == 'error_something_went_wrong') {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(
            attendance_error_server, "Error", AlertType.error, context, true);
      });
    } else {
      setState(() {
        // Alert Dialog
        utils.showAlertDialog(response.data.toString(), "Error",
            AlertType.error, context, true);
      });
    }
    pd.close();
  }

  insertAttendance(Attendance object) async {
    final insert = await dbHelper.newAttendances(object);
    debugPrint("Insert ASBEN :$insert");
  }

  void getSetting() async {
    var getSettings = await dbHelper.getSettings(1);
    var getUser = await dbHelper.getUser(1);
    await getAreaApi();
    setState(() {
      isLoading = true;
      getUrl = getSettings.url;
      getKey = getSettings.key;
      email = getUser.email;
      nama = getUser.nama;
      uid = getUser.uid;
      statusLogin = getUser.status;
    });
  }

  Future<void> getAreaApi() async {
    final uri = utils.getRealUrl(getUrl!, getPathArea!);
    Dio dio = Dio();
    try {
      final response = await dio.get(uri);
      var data = response.data;

      if (data['message'] == 'success') {
        final uri = utils.getRealUrl(getUrl!, "/api/auth/kehadiran/" + "$uid");
        await cekKehadiran(uri);
        setState(() {
          dataArea = data['area'];
        });
      } else {
        final uri = utils.getRealUrl(getUrl!, "/api/auth/kehadiran/" + "$uid");
        await cekKehadiran(uri);
        setState(() {
          dataArea = [
            {"id": 0, "name": "No Data Area"}
          ];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching area data: $e');
      }
      setState(() {
        dataArea = [
          {"id": 0, "name": "Error fetching data"}
        ];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> cekKehadiran(url) async {
    Dio dio = Dio();
    final response = await dio.get(url);
    var data = response.data;
    setState(() {
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
          print('Ini Attendance : \nisMockLocation: $isMockLocation'
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
      await fetchCurrentPosition();
      setState(() {
        _isInitInProgress = false;
      });
    }
  }

  Future<void> fetchCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      await _getAddressFromLatLng(position);
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching current position: $error');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude
      );
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress = '${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
      });
    } catch (e) {
      debugPrint(e.toString());
    }
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
        email: "it@biforst.cbnet.my.id",
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
      body: isLoading || _isInitInProgress || dataArea.isEmpty
          ? Center(
        child: LoadingAnimationWidget.discreteCircle(
          color: ThemeColor.primary,
          size: 50,
        ),
      ) : SingleChildScrollView(
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
                      onSubmit: () async {
                        await _cekOut();
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
      ,
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
                color: ThemeColor.primary,
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
                    color: ThemeColor.primary,
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
                  color: ThemeColor.primary,
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
          buttonStyleData: ButtonStyleData(
            height: screenHeight / 16,
            width: screenWidth / 1.3,
            padding: const EdgeInsets.only(left: 14, right: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ThemeColor.shadow,
              ),
              color: ThemeColor.white,
            ),
            elevation: 2,
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(
              Icons.arrow_forward_ios_outlined,
            ),
            iconSize: 14,
            iconEnabledColor: ThemeColor.primary,
            iconDisabledColor: Colors.grey,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: screenHeight / 4,
            width: screenWidth / 1.3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: ThemeColor.white,
            ),
            offset: const Offset(0, 0),
            scrollbarTheme: ScrollbarThemeData(
              radius: const Radius.circular(40),
              thickness: WidgetStateProperty.all<double>(6),
              thumbVisibility: WidgetStateProperty.all<bool>(true),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 40,
            padding: EdgeInsets.only(left: 14, right: 14),
          ),
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
