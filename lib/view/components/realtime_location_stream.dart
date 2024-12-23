import 'dart:async';
import 'package:attendance/utils/strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../../database/db_helper.dart';
import '../../model/colors.dart';
import '../../response/trip.dart';
import '../../utils/utils.dart';
import 'google_map_component.dart';

class RealtimeLocationStream extends StatefulWidget {
  const RealtimeLocationStream({super.key});

  @override
  State<RealtimeLocationStream> createState() => _RealtimeLocationStreamState();
}

class _RealtimeLocationStreamState extends State<RealtimeLocationStream> with WidgetsBindingObserver {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final GlobalKey<SlideActionState> key = GlobalKey();
  Position? _currentPosition;
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  StreamSubscription<Position>? _positionStreamSubscription;

  final List<LatLng> _routeCoordinates = [];
  Set<Polyline> _polylines = {};

  String? _tripId;
  String? _tripStatus;
  String? _nextStatus;
  String? _muatLat;
  String? _muatLong;
  String? _bongkarLat;
  String? _bongkarLong;

  String? nik,
      nama,
      email,
      pass,
      isLogged,
      getUrl,
      getKey,
      stringImage;

  int? statusLogin, uid, role;

  DbHelper dbHelper = DbHelper();
  Utils utils = Utils();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getSetting();
    _checkPermissionAndFetchLocationStream();
  }

  void getSetting() async {
    var getSettings = await dbHelper.getSettings(1);
    var getUser = await dbHelper.getUser(1);
    if(mounted){
      setState(() {
        getUrl = getSettings.url;
        getKey = getSettings.key;
        email = getUser.email;
        nama = getUser.nama;
        uid = getUser.uid;
        statusLogin = getUser.status;
        _getCurrentTrip();
      });
    }
  }

  Future<void> _getCurrentTrip() async {
    try {
      String url = utils.getRealUrl(getUrl!, "/api/auth/getTrip/$uid");
      Dio dio = Dio();
      final response = await dio.get(url);
      final data = response.data['trip'];
      print('Current trip data: $data');
      if (response.statusCode == 200) {
        setState(() {
          _tripId = data['id'];
          _tripStatus = data['status'];
          _muatLat = data['muat_lat'].toString();
          _muatLong = data['muat_long'].toString();
          _bongkarLat = data['bongkar_lat'].toString();
          _bongkarLong = data['bongkar_long'].toString();
          _nextStatus = getNextStatus(_tripStatus!);
        });
      } else {
        print('Failed to fetch current trip');
      }
    } catch (e) {
      print('Error fetching current trip: $e');
    }
  }

  Future<void> _checkPermissionAndFetchLocationStream() async {
    final hasPermission = await _handlePermission();
    if (hasPermission) {
      _startLocationStream();
    }
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are permanently denied.')),
        );
      }
      return false;
    }

    return true;
  }

  void _startLocationStream() {
    _positionStreamSubscription = Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = position;
        LatLng newPosition = LatLng(position.latitude, position.longitude);

        // Add new position to the route coordinates
        _routeCoordinates.add(newPosition);

        // Update polylines to show the route
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: _routeCoordinates,
          ),
        };
      });

      // Update camera position on the map
      if (_mapController.isCompleted) {
        _mapController.future.then((controller) {
          controller.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        });
      }
    });
  }

  String getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'absent':
        return 'pickup';
      case 'pickup':
        return 'loading';
      case 'loading':
        return 'loaded';
      case 'loaded':
        return 'go';
      case 'go':
        return 'arrived';
      case 'arrived':
        return 'unloading';
      case 'unloading':
        return 'SJ';
      case 'SJ':
        return 'completed';
      case 'completed':
        return 'completed';
      case 'canceled':
        return 'canceled'; // or handle as needed
      default:
        return 'unknown'; // or handle as needed
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Realtime Location Stream \n$_tripStatus'),
        titleTextStyle: TextStyle(
          color: ThemeColor.white,
          fontSize: MediaQuery.of(context).size.width / 20,
          fontFamily: "MontserratLight",
        ),
        backgroundColor: ThemeColor.primary,
      ),
      body: (_currentPosition != null)
          ? Column(
        children: [
          GoogleMapComponent(
            currentPosition: _currentPosition!,
            polylines: _polylines,
            mapController: _mapController,
          ),
          const SizedBox(
            height: 20,
          ),
          SlideAction(
            text: "Geser mulai $_nextStatus",
            textStyle: TextStyle(
              color: ThemeColor.primary,
              fontSize: MediaQuery.of(context).size.width / 20,
              fontFamily: "MontserratLight",
            ),
            outerColor: ThemeColor.white,
            innerColor: ThemeColor.primary,
            key: key,
            onSubmit: () {
              _updateStatus(context);
              return null;
            },
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  void _updateStatus(context) async {
    try {
      Map<String, dynamic> body = {
        'uid': uid,
        'trip_id': _tripId,
        'status': _nextStatus,
      };
      print('Update status body: $body');
      String url = utils.getRealUrl(getUrl!, "/api/auth/updateStatus");
      Dio dio = Dio();
      FormData formData = FormData.fromMap(body);

      ProgressDialog pd = ProgressDialog(context: context);
      pd.show(
        max: 100,
        msg: 'Sedang update status...',
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
      print('Update status response: $data');
      if (response.statusCode == 200) {
        // Handle success
        print('Status updated successfully');
        _getCurrentTrip();
      } else {
        // Handle error
        print('Failed to update status');
      }
    } catch (e) {
      print('Error updating status: $e');
    } finally {
      if(mounted){
        setState(() {
          _getCurrentTrip();
        });
      }
    }
  }
}
