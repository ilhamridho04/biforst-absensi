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

class _AttendanceScreenState extends State<AttendanceScreen> with WidgetsBindingObserver {
  late TargetPlatform? platform;

  bool isMockLocation = false;
  bool isRealDevice = false;
  bool isOnExternalStorage = false;
  bool isSafeDevice = false;
  bool isDevelopmentModeEnable = false;
  bool _isInitInProgress = false;

  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  bool positionStreamStarted = false;


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
  int? statusLogin, uid, role;
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = Colors.blue;

  DbHelper dbHelper = DbHelper();
  Utils utils = Utils();

  // Geolocation
  Position? _currentPosition;
  String? _currentAddress;
  final Geolocator geoLocator = Geolocator();

  late bool clickButton = false, isLoading = true;
  bool isUpdate = false;
  String? areaValue;
  double setAccuracy = 200.0;
  File? _image, newImage;

  List dataArea = [];
  Settings? settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getSetting();
    initPlatformState();
    _toggleServiceStatusStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _positionStreamSubscription?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _positionStreamSubscription?.resume();
    }
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
        sendData(context);
      });
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to pick image: $e');
      }
    }
  }

  // Send data post via http
  void sendData(context) async {
    if (areaValue == null) {
      utils.showAlertDialog(
          "Pilih area terlebih dahulu !", "warning", AlertType.warning, context, true);
    }
    var dataKey = getKey;
    String? fileName = _image!.path.split('/').last;
    Map<String, dynamic> body = {
      'key': dataKey,
      'worker_id': uid,
      'q': 'in',
      'lat': _currentPosition!.latitude,
      'longt': _currentPosition!.longitude,
      'area_id': areaValue,
      'absen_area': _currentAddress,
      'file': await MultipartFile.fromFile(_image!.path, filename: fileName),
    };
    String url = utils.getRealUrl(getUrl!, getPath!);
    Dio dio = Dio();
    FormData formData = FormData.fromMap(body);

    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(
      max: 100,
      msg: 'Sedang upload gambar...',
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
    if (kDebugMode) {
      print("Ini data : $data");
    }
    setState(() {
      handleResponse(context, data, uid.toString(), cekKehadiran);
    });
  }

  void _cekOut(context) async {
    var dataKey = getKey;
    Map<String, dynamic> body = {
      'key': dataKey,
      'worker_id': uid,
      'q': 'out',
      'lat': _currentPosition!.latitude,
      'longt': _currentPosition!.longitude,
      'absen_area': _currentAddress,
    };
    final uri = utils.getRealUrl(getUrl!, getPath!);
    Dio dio = Dio();
    FormData formData = FormData.fromMap(body);

    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(
      max: 100,
      msg: 'Hampir selesai...',
      completed: Completed(
        completedMsg: "Absen selesai !",
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
    pd.close();
    var data = response.data;
    setState(() {
      handleResponse(context, data, uid.toString(), cekKehadiran);
    });
  }

  insertAttendance(Attendance object) async {
    final insert = await dbHelper.newAttendances(object);
    debugPrint("Insert ASBEN :$insert");
  }

  void getSetting() async {
    var getSettings = await dbHelper.getSettings(1);
    var getUser = await dbHelper.getUser(1);
    getUrl = getSettings.url;
    getKey = getSettings.key;
    email = getUser.email;
    nama = getUser.nama;
    uid = getUser.uid;
    statusLogin = getUser.status;
    getAreaApi();
  }

  void getAreaApi() async {
    final uri = utils.getRealUrl(getUrl!, getPathArea!);
    Dio dio = Dio();
    final response = await dio.get(uri);
    var data = response.data;
    if (data['message'] == 'success') {
      final uri =
      utils.getRealUrl(getUrl!, "/api/auth/kehadiran/$uid");
      cekKehadiran(uri);
      dataArea = data['area'];
    } else {
      final uri =
      utils.getRealUrl(getUrl!, "/api/auth/kehadiran/$uid");
      cekKehadiran(uri);
      dataArea = [
        {"id": 0, "name": "No Data Area"}
      ];
    }
  }

  void cekKehadiran(url) async {
    Dio dio = Dio();
    final response = await dio.get(url);
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
      _getCurrentPosition();
      _isInitInProgress = false;
    }
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handlePermission();

    if (!hasPermission) {
      return;
    }

    final position = await _geolocatorPlatform.getCurrentPosition();
    _getAddressFromLatLng(position);
    if (kDebugMode) {
      print("Ini posisi : $position");
    }
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.

      AlertDialog(
        title: const Text('Location services disabled'),
        content: const Text(_kLocationServicesDisabledMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );

      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.

        AlertDialog(
          title: const Text('Location permissions denied'),
          content: const Text(_kPermissionDeniedMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );

        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      AlertDialog(
        title: const Text('Location permissions denied'),
        content: const Text(_kPermissionDeniedForeverMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
      return false;
    }

    AlertDialog(
      title: const Text('Location permissions granted'),
      content: const Text(_kPermissionGrantedMessage),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
    return true;
  }

  void _toggleServiceStatusStream() {
    if (_serviceStatusStreamSubscription == null) {
      final serviceStatusStream = _geolocatorPlatform.getServiceStatusStream();
      _serviceStatusStreamSubscription =
          serviceStatusStream.handleError((error) {
            _serviceStatusStreamSubscription?.cancel();
            _serviceStatusStreamSubscription = null;
          }).listen((serviceStatus) {
            String serviceStatusValue;
            if (serviceStatus == ServiceStatus.enabled) {
              if (positionStreamStarted) {
                _toggleListening();
              }
              serviceStatusValue = 'enabled';
            } else {
              if (_positionStreamSubscription != null) {
                setState(() {
                  _positionStreamSubscription?.cancel();
                  _positionStreamSubscription = null;

                  AlertDialog(
                    title: const Text('Location service status changed'),
                    content: const Text('Location service has been disabled'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                });
              }
              serviceStatusValue = 'disabled';
            }

            AlertDialog(
              title: const Text('Location service status changed'),
              content: Text('Location service has been $serviceStatusValue'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          });
    }
  }

  void _toggleListening() {
    if (_positionStreamSubscription == null) {
      final positionStream = _geolocatorPlatform.getPositionStream();
      _positionStreamSubscription = positionStream.handleError((error) {
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = null;
      }).listen((position) =>
        _getAddressFromLatLng(position)
      );
      _positionStreamSubscription?.pause();
    }

    setState(() {
      if (_positionStreamSubscription == null) {
        return;
      }

      String statusDisplayValue;
      if (_positionStreamSubscription!.isPaused) {
        _positionStreamSubscription!.resume();
        statusDisplayValue = 'resumed';
      } else {
        _positionStreamSubscription!.pause();
        statusDisplayValue = 'paused';
      }

      AlertDialog(
        title: const Text('Location permissions granted'),
        content: Text('Listening for position updates $statusDisplayValue'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );
      Placemark place = placemarks[0];
      setState(() {
        _currentPosition = position;
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
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => KeyboardVisibilityProvider(
          child: LoginScreen(),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: isLoading && _isInitInProgress
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
                          color: ThemeColor.shadow,
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
                    stream: Stream.periodic(Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      setState(() {
                        _getTime();
                      });
                      return Container(
                        height: screenHeight / 16,
                        margin: EdgeInsets.only(
                          top: 8,
                          bottom: 24,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColor.primary,
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_elapsedTime',
                                style: TextStyle(
                                  fontFamily: "MontserratRegular",
                                  fontSize: screenWidth / 18,
                                  color: ThemeColor.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
                        _cekOut(context);
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

  Future<void> handleResponse(context, dynamic data, String uid, Function cekKehadiran) async {
    if (data['message'] == 'Success!') {
      setState(() {
        String urlCekhadir = utils.getRealUrl(getUrl!, "/api/auth/kehadiran/$uid");
        cekKehadiran(urlCekhadir);
        Attendance attendance = Attendance(
          id: data['id'],
          date: data['date'],
          time: data['time'],
          location: data['location'],
          type: data['query'],
        );

        // Insert the attendance
        insertAttendance(attendance);
      });
      utils.showAlertDialog(
          "Berhasil melakukan absensi !", "Success", AlertType.success, context, true);
    } else if (data['message'] == 'key_not_valid') {
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
      utils.showAlertDialog(
          "Anda tidak bisa absen di area ini !", "Warning", AlertType.warning, context, true);
    } else if (data['message'] == 'location_not_found') {
      utils.showAlertDialog(
          "Lokasi tidak ditemukan !", "Warning", AlertType.warning, context, true);
    } else if (data['message'] == 'sudah_cek_in') {
      utils.showAlertDialog(
          "Anda sudah absen hari ini !", "Info", AlertType.info, context, true);
    } else if (data['message'] == 'check_in_first') {
      utils.showAlertDialog(
          "Anda harus absen masuk terlebih dahulu !", "Warning", AlertType.warning, context, true);
    } else if (data['message'] == 'error_something_went_wrong') {
      utils.showAlertDialog(
          "Terjadi kesalahan !", "Error", AlertType.error, context, true);
    } else {
      utils.showAlertDialog(
          "Terjadi kesalahan !", "Error", AlertType.error, context, true);
    }
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
          value: areaValue,
          onChanged: (value) {
            setState(() {
              areaValue = value;
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