import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/theme.dart';

/// Map location picker widget
/// Allows user to view and adjust location on OpenStreetMap
class MapLocationPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final Function(double latitude, double longitude) onLocationChanged;
  final double height;

  const MapLocationPicker({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onLocationChanged,
    this.height = 250,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _selectedLocation;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(widget.initialLatitude, widget.initialLongitude);
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(MapLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update marker if initial location changes
    if (oldWidget.initialLatitude != widget.initialLatitude ||
        oldWidget.initialLongitude != widget.initialLongitude) {
      setState(() {
        _selectedLocation = LatLng(widget.initialLatitude, widget.initialLongitude);
      });
      _mapController.move(_selectedLocation, _mapController.camera.zoom);
    }
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    widget.onLocationChanged(point.latitude, point.longitude);
  }

  void _centerOnLocation() {
    _mapController.move(_selectedLocation, 18);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 18,
              minZoom: 10,
              maxZoom: 19,
              onTap: _handleTap,
            ),
            children: [
              // OpenStreetMap tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.parkup.agent',
                maxZoom: 19,
              ),
              // Marker layer
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: AppColors.error,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Center button
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              onPressed: _centerOnLocation,
              backgroundColor: AppColors.surface,
              child: const Icon(
                Icons.my_location,
                color: AppColors.primary,
              ),
            ),
          ),
          // Instruction text
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Tap to adjust location',
                style: AppTextStyles.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
