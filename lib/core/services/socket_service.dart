import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../network/api_config.dart';
import '../network/api_client.dart';
import '../../shared/models/parking_session.dart';
import 'socket_events.dart';

/// Real-time socket service for parking sessions
/// Singleton pattern matching LocationService
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  bool _isInitialized = false;
  String? _currentZoneId;

  // Stream controllers for events (broadcast for multiple listeners)
  final _sessionCreatedController =
      StreamController<ParkingSession>.broadcast();
  final _sessionUpdatedController =
      StreamController<ParkingSession>.broadcast();
  final _sessionExpiringController =
      StreamController<ExpiringSessionEvent>.broadcast();
  final _sessionEndedController =
      StreamController<SessionEndedEvent>.broadcast();
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final _zoneSnapshotController =
      StreamController<List<ParkingSession>>.broadcast();

  // Public streams for UI to listen to
  Stream<ParkingSession> get onSessionCreated =>
      _sessionCreatedController.stream;
  Stream<ParkingSession> get onSessionUpdated =>
      _sessionUpdatedController.stream;
  Stream<ExpiringSessionEvent> get onSessionExpiring =>
      _sessionExpiringController.stream;
  Stream<SessionEndedEvent> get onSessionEnded =>
      _sessionEndedController.stream;
  Stream<ConnectionStatus> get onConnectionStatus =>
      _connectionStatusController.stream;
  Stream<List<ParkingSession>> get onZoneSnapshot =>
      _zoneSnapshotController.stream;

  // Status getters
  bool get isConnected => _isConnected;
  String? get currentZoneId => _currentZoneId;

  /// Initialize socket connection
  Future<bool> init() async {
    if (_isInitialized && _socket != null && _isConnected) {
      return true;
    }

    try {
      // Get auth token from ApiClient
      final authHeader =
          ApiClient.instance.dio.options.headers['Authorization'] as String?;
      final token = authHeader?.replaceFirst('Bearer ', '');

      // Get base URL and convert to WebSocket URL
      final baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');

      print('[SocketService] Connecting to: $baseUrl/parking-sessions');

      _socket = io.io(
        '$baseUrl/parking-sessions',
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(10)
            .build(),
      );

      _setupEventListeners();
      _isInitialized = true;

      return true;
    } catch (e) {
      print('[SocketService] Init error: $e');
      return false;
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      print('[SocketService] Connected');
      _isConnected = true;
      _connectionStatusController.add(ConnectionStatus.connected);

      // Rejoin zone if we had one before disconnect
      if (_currentZoneId != null) {
        joinZone(_currentZoneId!);
      }
    });

    _socket!.onDisconnect((_) {
      print('[SocketService] Disconnected');
      _isConnected = false;
      _connectionStatusController.add(ConnectionStatus.disconnected);
    });

    _socket!.onReconnect((_) {
      print('[SocketService] Reconnected');
      _isConnected = true;
      _connectionStatusController.add(ConnectionStatus.reconnected);
    });

    _socket!.onReconnectAttempt((attempt) {
      print('[SocketService] Reconnect attempt $attempt');
      _connectionStatusController.add(ConnectionStatus.reconnecting);
    });

    _socket!.onConnectError((error) {
      print('[SocketService] Connect error: $error');
      _connectionStatusController.add(ConnectionStatus.error);
    });

    _socket!.onError((error) {
      print('[SocketService] Error: $error');
      _connectionStatusController.add(ConnectionStatus.error);
    });

    // Session events
    _socket!.on(SocketEvents.sessionCreated, (data) {
      print('[SocketService] Session created');
      try {
        final session = ParkingSession.fromJson(data as Map<String, dynamic>);
        _sessionCreatedController.add(session);
      } catch (e) {
        print('[SocketService] Error parsing session:created: $e');
      }
    });

    _socket!.on(SocketEvents.sessionUpdated, (data) {
      print('[SocketService] Session updated');
      try {
        final session = ParkingSession.fromJson(data as Map<String, dynamic>);
        _sessionUpdatedController.add(session);
      } catch (e) {
        print('[SocketService] Error parsing session:updated: $e');
      }
    });

    _socket!.on(SocketEvents.sessionExpiring, (data) {
      print('[SocketService] Session expiring');
      try {
        final event =
            ExpiringSessionEvent.fromJson(data as Map<String, dynamic>);
        _sessionExpiringController.add(event);
      } catch (e) {
        print('[SocketService] Error parsing session:expiring: $e');
      }
    });

    _socket!.on(SocketEvents.sessionEnded, (data) {
      print('[SocketService] Session ended');
      try {
        final event = SessionEndedEvent.fromJson(data as Map<String, dynamic>);
        _sessionEndedController.add(event);
      } catch (e) {
        print('[SocketService] Error parsing session:ended: $e');
      }
    });

    _socket!.on(SocketEvents.zoneSnapshot, (data) {
      print('[SocketService] Zone snapshot received');
      try {
        final sessionsData = data['sessions'] as List<dynamic>;
        final sessions = sessionsData
            .map((s) => ParkingSession.fromJson(s as Map<String, dynamic>))
            .toList();
        _zoneSnapshotController.add(sessions);
      } catch (e) {
        print('[SocketService] Error parsing zone:snapshot: $e');
      }
    });

    _socket!.on(SocketEvents.error, (data) {
      print('[SocketService] Server error: $data');
    });
  }

  /// Join a zone room to receive updates
  void joinZone(String zoneId) {
    if (_socket == null) {
      print('[SocketService] Cannot join zone: socket not initialized');
      return;
    }

    if (!_isConnected) {
      print('[SocketService] Cannot join zone: not connected');
      _currentZoneId = zoneId; // Store for when we reconnect
      return;
    }

    // Leave previous zone if switching
    if (_currentZoneId != null && _currentZoneId != zoneId) {
      print('[SocketService] Switching from zone $_currentZoneId to $zoneId');
      _socket!.emit(SocketEvents.zoneSwitch, {
        'fromZoneId': _currentZoneId,
        'toZoneId': zoneId,
      });
    } else {
      print('[SocketService] Joining zone $zoneId');
      _socket!.emit(SocketEvents.zoneJoin, {'zoneId': zoneId});
    }

    _currentZoneId = zoneId;
  }

  /// Leave current zone room
  void leaveZone() {
    if (_socket == null || _currentZoneId == null) return;

    print('[SocketService] Leaving zone $_currentZoneId');
    _socket!.emit(SocketEvents.zoneLeave, {'zoneId': _currentZoneId});
    _currentZoneId = null;
  }

  /// Disconnect socket
  void disconnect() {
    print('[SocketService] Disconnecting');
    _socket?.disconnect();
    _isConnected = false;
  }

  /// Reconnect socket
  Future<void> reconnect() async {
    print('[SocketService] Reconnecting');
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await init();
  }

  /// Dispose resources (call when app is closing)
  void dispose() {
    print('[SocketService] Disposing');
    disconnect();
    _socket?.dispose();
    _socket = null;
    _isInitialized = false;
    _currentZoneId = null;

    // Close stream controllers
    _sessionCreatedController.close();
    _sessionUpdatedController.close();
    _sessionExpiringController.close();
    _sessionEndedController.close();
    _connectionStatusController.close();
    _zoneSnapshotController.close();
  }
}

/// Global singleton instance
final socketService = SocketService();
