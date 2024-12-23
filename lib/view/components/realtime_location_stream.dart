import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../../model/colors.dart';
import 'google_map_component.dart';

class RealtimeLocationStream extends StatefulWidget {
  const RealtimeLocationStream({super.key});

  @override
  State<RealtimeLocationStream> createState() => _RealtimeLocationStreamState();
}

class _RealtimeLocationStreamState extends State<RealtimeLocationStream> {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final GlobalKey<SlideActionState> key = GlobalKey();
  Position? _currentPosition;
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  StreamSubscription<Position>? _positionStreamSubscription;

  final List<LatLng> _routeCoordinates = [];
  Set<Polyline> _polylines = {};

  String? _tripId;
  String? _tripStatus;
  String? _muatLat;
  String? _muatLong;
  String? _bongkarLat;
  String? _bongkarLong;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndFetchLocationStream();
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

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realtime Location Stream')),
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
            text: "Geser Mulai Muat",
            textStyle: TextStyle(
              color: ThemeColor.primary,
              fontSize: MediaQuery.of(context).size.width / 20,
              fontFamily: "MontserratLight",
            ),
            outerColor: ThemeColor.white,
            innerColor: ThemeColor.primary,
            key: key,
            onSubmit: () {
              _startLocationStream();
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
}
