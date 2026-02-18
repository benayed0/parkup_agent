import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Connectivity service — monitors network state changes
/// Uses connectivity_plus + HTTP HEAD check for real internet verification
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _controller = StreamController<bool>.broadcast();

  bool _isConnected = true;
  bool _isInitialized = false;
  Timer? _retryTimer;

  /// Whether the device currently has internet access
  bool get isConnected => _isConnected;

  /// Stream that emits connectivity changes (true = online, false = offline)
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Initialize the service and start listening
  Future<void> init() async {
    if (_isInitialized) return;

    // Check initial state
    final results = await _connectivity.checkConnectivity();
    final hasConnection = _hasNetworkInterface(results);

    if (hasConnection) {
      _isConnected = await _hasRealInternet();
    } else {
      _isConnected = false;
    }

    if (!_isConnected) _startRetryTimer();

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);

    _isInitialized = true;
    debugPrint('[ConnectivityService] Initialized. isConnected=$_isConnected');
  }

  Future<void> _onChanged(List<ConnectivityResult> results) async {
    final hasInterface = _hasNetworkInterface(results);

    if (!hasInterface) {
      _setConnected(false);
      return;
    }

    // Network interface appeared — wait a moment for the stack to be ready,
    // then retry up to 3 times with increasing delay
    for (var attempt = 0; attempt < 3; attempt++) {
      await Future.delayed(Duration(seconds: attempt == 0 ? 1 : 2));
      final reachable = await _hasRealInternet();
      if (reachable) {
        _setConnected(true);
        return;
      }
      debugPrint('[ConnectivityService] HEAD check attempt ${attempt + 1} failed, retrying...');
    }

    // All attempts failed — stay offline, periodic timer will keep trying
    _setConnected(false);
  }

  void _setConnected(bool connected) {
    if (_isConnected == connected) return;
    _isConnected = connected;
    debugPrint('[ConnectivityService] Connectivity changed: $_isConnected');
    _controller.add(_isConnected);

    if (!connected) {
      _startRetryTimer();
    } else {
      _stopRetryTimer();
    }
  }

  /// Periodically re-check while offline (every 5s)
  void _startRetryTimer() {
    _stopRetryTimer();
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_isConnected) {
        _stopRetryTimer();
        return;
      }
      final reachable = await _hasRealInternet();
      if (reachable) {
        _setConnected(true);
      }
    });
  }

  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Check if any connectivity result indicates a network interface
  bool _hasNetworkInterface(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Do a lightweight HTTP HEAD to verify real internet access
  Future<bool> _hasRealInternet() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio.head('https://clients3.google.com/generate_204');
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _stopRetryTimer();
    _controller.close();
    _isInitialized = false;
  }
}

/// Singleton instance
final connectivityService = ConnectivityService();
