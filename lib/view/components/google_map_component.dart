import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapComponent extends StatelessWidget {
  final Position currentPosition;
  final Set<Polyline> polylines;
  final Completer<GoogleMapController> mapController;

  const GoogleMapComponent({
    super.key,
    required this.currentPosition,
    required this.polylines,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            currentPosition.latitude,
            currentPosition.longitude,
          ),
          zoom: 17,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(
              currentPosition.latitude,
              currentPosition.longitude,
            ),
            infoWindow: const InfoWindow(title: 'Current Location'),
          ),
        },
        polylines: polylines,
        onMapCreated: (controller) => mapController.complete(controller),
      ),
    );
  }
}