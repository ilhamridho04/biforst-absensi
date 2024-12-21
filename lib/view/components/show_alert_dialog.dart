import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class ShowAlertDialog extends StatelessWidget {
  final BuildContext context;
  final AlertType? type;
  final String title;
  final String description;
  final String buttonText;

  const ShowAlertDialog({
    super.key,
    required this.context,
    required this.type,
    required this.title,
    required this.description,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Alert(
        context: this.context,
        type: type,
        title: title,
        desc: description,
        buttons: [
          DialogButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            width: 120,
            child: Text(
              buttonText,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ],
      ).show(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return Container(); // Return an empty container while the alert is being shown
      },
    );
  }
}