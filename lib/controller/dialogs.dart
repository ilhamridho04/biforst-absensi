import 'package:flutter/material.dart';
import 'custom_dialog_box.dart';

class Dialogs extends StatefulWidget {
  const Dialogs({super.key});

  @override
  _DialogsState createState() => _DialogsState();
}

class _DialogsState extends State<Dialogs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Custom Dialog In Flutter"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CustomDialogBox(
                    title: "Custom Dialog Demo",
                    descriptions:
                    "Hii all this is a custom dialog in flutter and  you will be use in your flutter applications",
                    btn: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "Ok",
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: "MontserratRegular",
                        ),
                      ),
                    ),
                    img: Image.asset('assets/images/secure.png'),
                  );
                });
          },
          child: Text("Custom Dialog"),
        ),
      ),
    );
  }
}
