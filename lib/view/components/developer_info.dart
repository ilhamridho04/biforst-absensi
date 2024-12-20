import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../model/colors.dart';

class DeveloperInfo extends StatefulWidget {
  final String nama;
  const DeveloperInfo({super.key, required this.nama});

  @override
  State<DeveloperInfo> createState() => _DeveloperInfoState();
}

class _DeveloperInfoState extends State<DeveloperInfo> {
  double screenHeight = 0;
  double screenWidth = 0;

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Container(
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
            "Hi ${widget.nama}",
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
            "<p>Kami mendeteksi bahwa perangkat anda mengaktifkan <b style='color: red;'>opsi pengembang</b>.</p></p>Silahkan matikan <b style='color: red;'>opsi pengembang</b> pada perangkat anda untuk menggunakan aplikasi kami.</p>",
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
    );
  }
}