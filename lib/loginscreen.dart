import 'package:attendance/utils/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/db_helper.dart';
import 'homescreen.dart';
import 'model/colors.dart';
import 'model/settings.dart';
import 'model/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum LoginStatus { notSignIn, signIn, doubleCheck }

class _LoginScreenState extends State<LoginScreen> {
  // Global key scaffold
  final _key = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  LoginStatus _loginStatus = LoginStatus.notSignIn;
  bool _isPermissionRequestInProgress = false;

  String? nik, nama, email, pass, isLogged, getUrl, getKey;
  int? uid, role;
  String statusLogged = 'logged';
  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();
  double screenHeight = 0;
  double screenWidth = 0;

  DbHelper dbHelper = DbHelper();
  late ProgressDialog pr;
  bool _secureText = true;

  Color primary = Colors.blue;

  @override
  void initState() {
    super.initState();
    getSettings();
    getPermissionAttendance();

    pr = ProgressDialog(context,
        type: ProgressDialogType.normal, isDismissible: false, showLogs: false);

    pr.style(
        message: "Memeriksa...",
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        padding: EdgeInsets.all(10.0),
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
          color: Colors.black,
          fontFamily: "MontserratRegular",
          fontSize: screenWidth / 40,
        ),
        messageTextStyle: TextStyle(
          color: Colors.black,
          fontFamily: "MontserratRegular",
          fontSize: screenWidth / 24,
        ));
  }

  @override
  void dispose() {
    super.dispose();
    pr.hide().whenComplete(() {
      if (kDebugMode) {
        print(pr.isShowing());
      }
    });
  }

  Future<void> getPermissionAttendance() async {
    if (_isPermissionRequestInProgress) return;

    setState(() {
      _isPermissionRequestInProgress = true;
    });

    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      // Handle the permission statuses here

    } catch (e) {
      if (kDebugMode) {
        print('Failed to request permissions: $e');
      }
    } finally {
      setState(() {
        _isPermissionRequestInProgress = false;
      });
    }
  }

  showHide() {
    setState(() {
      _secureText = !_secureText;
    });
  }

  void check() async {
    final form = _key.currentState;
    if (form != null && form.validate()) {
      form.save();
      login('clickButton');
    }
  }

  void getSettings() async {
    var getSettings = await dbHelper.getSettings(1);
    var getUser = await dbHelper.getUser(1);
    setState(() {
      getUrl = getSettings.url;
      getKey = getSettings.key;
      email = getUser.email;
    });
    getPref();
  }

  void login(String fromWhere) async {
    if (fromWhere == 'clickButton') {
      pr.show();
    }
    var urlLogin = "https://biforst.cbnet.my.id/api/auth/login2";
    try {
      var dio = Dio();
      FormData formData = FormData.fromMap({
        "email": email,
        "password": pass,
      });

      final response = await dio.post(
        urlLogin,
        data: formData,
        options: Options(
          receiveDataWhenStatusError: true,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      var data = response.data;
      pr.hide().whenComplete(() {
        if (kDebugMode) {
          print(pr.isShowing());
        }
      });
      String message = data['message'];
      String pesan = data['pesan'];
      if (message == 'success') {
        isLogged = statusLogged;
        uid = data['user']['id'];
        nik = data['user']['nik'];
        nama = data['user']['nama'];
        email = data['user']['email'];
        role = data['user']['role'];

        User user = User(
          id: 1,
          uid: uid!,
          nik: nik!,
          nama: nama!,
          email: email!,
          role: role!,
          status: 1,
        );
        setState(() {
          Future.delayed(Duration(seconds: 0)).then((value) {
            pr.hide().whenComplete(() {
              print(pr.isShowing());
            });
            Settings updateSettings =
            Settings(id: 1, url: "$base_url", key: "$key_app");
            dbHelper.updateSettings(updateSettings);
            updateUser(user);
          });
        });
      } else {
        if (fromWhere == 'clickButton') {
          setState(() {
            Future.delayed(Duration(seconds: 0)).then((value) {
              pr.hide().whenComplete(() {
                if (kDebugMode) {
                  print(pr.isShowing());
                }
              });
              Alert(
                  context: context,
                  type: AlertType.error,
                  title: message.toUpperCase(),
                  desc: pesan,
                  buttons: [
                    DialogButton(
                      onPressed: () => Navigator.pop(context),
                      width: 75,
                      child: Text(
                        "Ok",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ]).show();
            });
          });
        } else {
          if (fromWhere == 'clickButton') {
            setState(() {
              Future.delayed(Duration(seconds: 0)).then((value) {
                pr.hide().whenComplete(() {
                  print(pr.isShowing());
                });
                Alert(
                    context: context,
                    type: AlertType.error,
                    title: message,
                    desc: pesan,
                    buttons: [
                      DialogButton(
                        onPressed: () => Navigator.pop(context),
                        width: 75,
                        child: Text(
                          "Ok",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ]).show();
              });
            });
          } else {
            setState(() {
              _loginStatus = LoginStatus.notSignIn;
              removePref();
            });
          }
        }
      }
    } on DioException catch (e) {
      if (fromWhere == 'clickButton') {
        setState(() {
          Future.delayed(Duration(seconds: 0)).then((value) {
            pr.hide().whenComplete(() {
              if (kDebugMode) {
                print(pr.isShowing());
              }
            });
            Alert(
                context: context,
                type: AlertType.error,
                title: "Error".toUpperCase(),
                desc: e.message,
                buttons: [
                  DialogButton(
                    onPressed: () => Navigator.pop(context),
                    width: 75,
                    child: Text(
                      "Ok",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ]).show();
          });
        });
      } else {
        setState(() {
          _loginStatus = LoginStatus.notSignIn;
          removePref();
        });
      }
    }
  }

  void getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      var getStatusSp = preferences.getString("status");
      var getEmail = preferences.getString("email");
      var getPassword = preferences.getString("password");
      var getKey = preferences.getString("key");

      if (getStatusSp == statusLogged) {
        _loginStatus = LoginStatus.doubleCheck;
        // if user aleady login, will check again, if there is any change on web server
        // Like change the role, or the status
        email = getEmail;
        pass = getPassword;
        login('doubleCheck');
      } else {
        _loginStatus = LoginStatus.notSignIn;
      }
    });
  }

  Future<void> loginBtn() async {
    FocusScope.of(context).unfocus();
    email = idController.text.trim();
    pass = passController.text.trim();

    if (email!.isEmpty) {
      idController.text = "demo_biforst";
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username tidak boleh kosong"),
        ),
      );
    }
    if (pass!.isEmpty) {
      passController.text = "demo123";
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password tidak boleh kosong"),
        ),
      );
    } else {
      FocusScope.of(context).requestFocus(FocusNode());
      check();
      // print(message);
    }
  }

  void updateUser(User object) async {
    await dbHelper.updateUser(object);
    Future.delayed(Duration(seconds: 0)).then((value) {
      if (mounted) {
        setState(() {
          goToMainMenu();
        });
      }
    });
  }

  void goToMainMenu() {
    _loginStatus = LoginStatus.signIn;
    savePref(isLogged!, email!, pass!, uid!, key_app);
    // Navigator.of(context).pop();
  }

  void savePref(
      String status, String email, String pass, int uid, String key) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      preferences.setString("status", status);
      preferences.setString("email", email);
      preferences.setString("password", pass);
      preferences.setInt("id", uid);
      preferences.setString("key", key);
    });
  }

  void removePref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setString("logged", "notLogged");
    preferences.setString("email", "");
    preferences.setString("password", "");
    preferences.setInt("id", 0);
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible =
    KeyboardVisibilityProvider.isKeyboardVisible(context);
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: ThemeColor.primary,
    ));

    switch (_loginStatus) {
      case LoginStatus.notSignIn:
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              isKeyboardVisible
                  ? SizedBox(
                height: screenHeight / 16,
              )
                  : Container(
                height: screenHeight / 2.5,
                width: screenWidth,
                decoration: BoxDecoration(
                    color: ThemeColor.primary,
                    borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(70))),
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(100.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image(
                      image: AssetImage('assets/images/secure.png'),
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                    top: screenHeight / 15, bottom: screenHeight / 20),
                child: Text(
                  "Login",
                  style: TextStyle(
                      fontSize: screenWidth / 18, fontFamily: "MontserratBold"),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
                child: Form(
                  key: _key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fieldTitle("Email"),
                      customField(
                          "Email/Username",
                          Icon(
                            Icons.person,
                            color: ThemeColor.primary,
                            size: screenWidth / 15,
                          ),
                          IconButton(
                            onPressed: () => '',
                            icon: Icon(Icons.person),
                            color: Colors.transparent,
                          ),
                          idController,
                          false),
                      fieldTitle("Password"),
                      customField(
                        "Password",
                        Icon(
                          Icons.key,
                          color: ThemeColor.primary,
                          size: screenWidth / 15,
                        ),
                        IconButton(
                          onPressed: showHide,
                          icon: Icon(_secureText
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                        passController,
                        _secureText,
                      ),
                      Container(
                        margin: EdgeInsets.only(
                          top: screenHeight / 25,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 150,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => loginBtn(),
                              style: ButtonStyle(
                                foregroundColor:
                                WidgetStateProperty.all<Color>(
                                  Colors.white,
                                ),
                                backgroundColor:
                                WidgetStateProperty.all<Color>(
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
                                "Login",
                                style: TextStyle(
                                  fontSize: screenWidth / 24,
                                  fontFamily: "MontserratRegular",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case LoginStatus.doubleCheck:
        return Scaffold(
          key: _scaffoldKey,
          body: Stack(
            children: [
              Center(
                child: LoadingAnimationWidget.discreteCircle(
                  color: ThemeColor.primary,
                  size: 50,
                ),
              ),
            ],
          ),
        );
      case LoginStatus.signIn:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false,
          );
        });
        return Container();
    }
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
            fontSize: screenWidth / 26, fontFamily: "MontserratRegular"),
      ),
    );
  }

  Widget customField(String hint, Icon icon, IconButton iconBtn,
      TextEditingController controller, bool obscure) {
    return Container(
      width: screenWidth,
      margin: EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: screenWidth / 6,
            child: icon,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 12),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight / 35,
                    ),
                    border: InputBorder.none,
                    suffixIcon: iconBtn,
                    hintText: hint),
                maxLines: 1,
                obscureText: obscure,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
