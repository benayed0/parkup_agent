import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../shared/models/models.dart' as models;

/// Location service with pre-cached GPS
/// Keeps location updated in background for instant ticket creation
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  models.Position? _cachedPosition;
  DateTime? _lastUpdate;
  bool _isInitialized = false;
  StreamSubscription<Position>? _positionStream;

  /// Get cached position (may be null if not yet available)
  models.Position? get cachedPosition => _cachedPosition;

  /// Check if we have a recent position (within last 30 seconds)
  bool get hasRecentPosition {
    if (_cachedPosition == null || _lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!).inSeconds < 30;
  }

  /// Initialize location service and start background updates
  Future<bool> init() async {
    if (_isInitialized) return _cachedPosition != null;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      // Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }

      if (permission == LocationPermission.deniedForever) return false;

      // Get initial position quickly with low accuracy
      await _updatePosition(highAccuracy: false);

      // Then get high accuracy position
      _updatePosition(highAccuracy: true);

      // Start listening for position updates
      _startPositionStream();

      _isInitialized = true;
      return _cachedPosition != null;
    } catch (e) {
      return false;
    }
  }

  /// Force refresh the cached position
  Future<models.Position?> refreshPosition() async {
    await _updatePosition(highAccuracy: true);
    return _cachedPosition;
  }

  /// Get current position - uses cache if recent, otherwise fetches new
  Future<models.Position?> getCurrentPosition() async {
    if (hasRecentPosition) return _cachedPosition;
    return refreshPosition();
  }

  Future<void> _updatePosition({required bool highAccuracy}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        ),
      );

      _cachedPosition = models.Position(
        longitude: position.longitude,
        latitude: position.latitude,
      );
      _lastUpdate = DateTime.now();
    } catch (e) {
      // Silent fail - keep using cached position
    }
  }

  void _startPositionStream() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((position) {
      _cachedPosition = models.Position(
        longitude: position.longitude,
        latitude: position.latitude,
      );
      _lastUpdate = DateTime.now();
    });
  }

  void dispose() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}

/// Singleton instance
final locationService = LocationService();
