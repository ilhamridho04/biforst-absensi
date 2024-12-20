import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:dio/dio.dart';

import '../database/db_helper.dart';
import '../model/colors.dart';
import '../response/single_user_response.dart';
import '../response/user_response.dart';
import '../services/http_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? nik = "",
      nama = "",
      email = "",
      pass = "",
      isLogged = "",
      getUrl = "",
      getKey = "",
      jamMasuk = "",
      stringImage = "",
      getPathArea = '/api/auth/area',
      getPath = '/api/auth/hadir';

  double screenHeight = 0;
  double screenWidth = 0;

  bool isLoading = true;

  late int uid;

  late SingleUserResponse singleUserResponse;
  late UserResponse userResponse;

  late HttpService httpService;

  DbHelper dbHelper = DbHelper();

  @override
  void initState() {
    httpService = HttpService();
    singleUserResponse = SingleUserResponse();
    userResponse = UserResponse();
    getSetting();
    super.initState();
  }

  Future<void> getSetting() async {
    var getSettings = await dbHelper.getSettings(1);
    var getUser = await dbHelper.getUser(1);
    setState(() {
      getUrl = getSettings.url;
      getKey = getSettings.key;
      email = getUser.email;
      nama = getUser.nama;
      uid = getUser.uid;

      _getUser();
    });
  }

  Future<void> _getUser() async {
    Response response;
    try {
      response = await httpService.getRequest("/api/auth/user/$uid");
      if (response.statusCode == 200) {
        var data = response.data;
        setState(() {
          isLoading = false;
          singleUserResponse = SingleUserResponse.fromJson(data);

          userResponse = singleUserResponse.userResponse;
          // print(data);
        });
      } else {
        isLoading = false;
        print("Gagal mendapatkan data");
      }
    } on Exception catch (e) {
      isLoading = false;
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: isLoading
            ? Center(
          child: LoadingAnimationWidget.discreteCircle(
            color: ThemeColor.primary,
            size: 50,
          ),
        )
            : Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(140),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 10,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 120,
                      backgroundImage: userResponse.img_type.isNotEmpty
                          ? NetworkImage(userResponse.img_type)
                          : AssetImage('assets/icons/icon.png') as ImageProvider,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 35,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userResponse.name.isNotEmpty
                        ? userResponse.name
                        : "Demo Biforst",
                    style: TextStyle(
                      color: ThemeColor.black,
                      fontFamily: "MontserratBold",
                      fontSize: screenWidth / 16,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 18,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userResponse.email,
                    style: TextStyle(
                      color: ThemeColor.lightBlue,
                      fontFamily: "MontserratRegular",
                      fontSize: screenWidth / 24,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
