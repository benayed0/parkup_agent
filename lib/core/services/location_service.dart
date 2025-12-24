import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    print('[LocationService] init() called. _isInitialized=$_isInitialized, _positionStream=${_positionStream != null}, isWeb=$kIsWeb');

    // Always try to reinitialize stream after hot reload (only on native, web doesn't use stream)
    if (_isInitialized && _positionStream == null && !kIsWeb) {
      print('[LocationService] Detected hot reload on native, resetting...');
      _isInitialized = false;
    }

    if (_isInitialized) {
      print('[LocationService] Already initialized, returning cached: ${_cachedPosition != null}');
      return _cachedPosition != null;
    }

    try {
      // Check if location services are enabled
      print('[LocationService] Checking if location services enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('[LocationService] Location services enabled: $serviceEnabled');
      if (!serviceEnabled) return false;

      // Check/request permission
      print('[LocationService] Checking permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('[LocationService] Permission: $permission');
      if (permission == LocationPermission.denied) {
        print('[LocationService] Requesting permission...');
        permission = await Geolocator.requestPermission();
        print('[LocationService] Permission after request: $permission');
        if (permission == LocationPermission.denied) return false;
      }

      if (permission == LocationPermission.deniedForever) {
        print('[LocationService] Permission denied forever');
        return false;
      }

      // Get initial position quickly with low accuracy
      print('[LocationService] Getting initial position (low accuracy)...');
      await _updatePosition(highAccuracy: false);
      print('[LocationService] Got initial position: $_cachedPosition');

      // Then get high accuracy position
      print('[LocationService] Getting high accuracy position...');
      _updatePosition(highAccuracy: true);

      // Start listening for position updates
      _startPositionStream();

      _isInitialized = true;
      print('[LocationService] Initialized successfully. cachedPosition: $_cachedPosition');
      return _cachedPosition != null;
    } catch (e) {
      print('[LocationService] Error during init: $e');
      return false;
    }
  }

  /// Reset the service (useful for hot reload or error recovery)
  void reset() {
    _positionStream?.cancel();
    _positionStream = null;
    _isInitialized = false;
  }

  /// Force refresh the cached position
  Future<models.Position?> refreshPosition() async {
    print('[LocationService] refreshPosition() called');
    await _updatePosition(highAccuracy: true);
    print('[LocationService] refreshPosition() done, returning: $_cachedPosition');
    return _cachedPosition;
  }

  /// Get current position - uses cache if recent, otherwise fetches new
  Future<models.Position?> getCurrentPosition() async {
    if (hasRecentPosition) return _cachedPosition;
    return refreshPosition();
  }

  Future<void> _updatePosition({required bool highAccuracy}) async {
    print('[LocationService] _updatePosition(highAccuracy: $highAccuracy, isWeb: $kIsWeb) called');

    // Try last known position first (instant, no GPS needed) - NOT supported on web
    if (_cachedPosition == null && !kIsWeb) {
      try {
        print('[LocationService] Trying getLastKnownPosition first...');
        final lastKnown = await Geolocator.getLastKnownPosition();
        print('[LocationService] Last known: $lastKnown');
        if (lastKnown != null) {
          _cachedPosition = models.Position(
            longitude: lastKnown.longitude,
            latitude: lastKnown.latitude,
          );
          _lastUpdate = DateTime.now();
          print('[LocationService] Using last known position');
        }
      } catch (e) {
        print('[LocationService] Error getting last known: $e');
      }
    }

    // Get fresh position - use different settings for web
    try {
      if (kIsWeb) {
        print('[LocationService] Web: Calling Geolocator.getCurrentPosition (timeout: 15s)...');
        print('[LocationService] Web: Browser should show permission dialog if not already granted');
        // Web doesn't support LocationSettings, use simpler call with longer timeout
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.low,
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('[LocationService] Web: Timeout after 15s - browser may have blocked location');
            throw Exception('Timeout getting position on web');
          },
        );
        print('[LocationService] Web: Got position: lat=${position.latitude}, lng=${position.longitude}');
        _cachedPosition = models.Position(
          longitude: position.longitude,
          latitude: position.latitude,
        );
        _lastUpdate = DateTime.now();
      } else {
        print('[LocationService] Native: Calling Geolocator.getCurrentPosition (timeout: 5s)...');
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          ),
        );
        print('[LocationService] Native: Got position: lat=${position.latitude}, lng=${position.longitude}');
        _cachedPosition = models.Position(
          longitude: position.longitude,
          latitude: position.latitude,
        );
        _lastUpdate = DateTime.now();
      }
    } catch (e) {
      print('[LocationService] Error getting current position: $e');
      print('[LocationService] Stack trace: ${StackTrace.current}');
    }
  }

  void _startPositionStream() {
    // Position stream is not reliable on web, skip it
    if (kIsWeb) {
      print('[LocationService] Skipping position stream on web');
      return;
    }

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
