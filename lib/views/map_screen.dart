import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/risk_circle.dart';
import '../services/data_service.dart';
import '../utils/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  static const LatLng _initial = LatLng(8.4871, 76.9520);

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final circles = data.areas.map((a) => buildRiskCircle(a)).toList();
    final centerDots = data.areas.map((a) => buildAreaDot(a)).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'Flood Risk Map',
        subtitle: 'Trivandrum Flood Monitor',
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initial,
              initialZoom: 11.4,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.floodwatchapp',
              ),
              CircleLayer(circles: circles.cast<CircleMarker>()),
              MarkerLayer(markers: centerDots.cast<Marker>()),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: buildLegendCard(),
            ),
          ),
          Positioned(
            bottom: 28,
            right: 20,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: _goToMyLocation,
              icon: const Icon(Icons.my_location, color: Colors.white),
              label: const Text('My location'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location permissions are permanently denied. Please enable them in settings.')));
      return;
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _mapController.move(LatLng(position.latitude, position.longitude), 14.5);

    if (mounted) ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Centered to your location.')));
  }
}
