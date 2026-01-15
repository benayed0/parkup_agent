import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/services/socket_events.dart';
import '../../../../core/widgets/license_plate_input.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/repositories/active_sessions_repository.dart';

/// Active sessions map page with real-time updates
/// Displays all active parking sessions on an interactive map
class ActiveSessionsMapPage extends StatefulWidget {
  const ActiveSessionsMapPage({super.key});

  @override
  State<ActiveSessionsMapPage> createState() => _ActiveSessionsMapPageState();
}

class _ActiveSessionsMapPageState extends State<ActiveSessionsMapPage> {
  final MapController _mapController = MapController();
  List<ParkingSession> _sessions = [];
  bool _isLoading = true;
  String? _error;
  ParkingSession? _selectedSession;
  ParkingZone? _selectedZone;

  // Socket subscriptions
  StreamSubscription<ParkingSession>? _createdSub;
  StreamSubscription<ParkingSession>? _updatedSub;
  StreamSubscription<ExpiringSessionEvent>? _expiringSub;
  StreamSubscription<SessionEndedEvent>? _endedSub;
  StreamSubscription<List<ParkingSession>>? _snapshotSub;
  StreamSubscription<ConnectionStatus>? _connectionSub;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    socketService.leaveZone();
    super.dispose();
  }

  void _cancelSubscriptions() {
    _createdSub?.cancel();
    _updatedSub?.cancel();
    _expiringSub?.cancel();
    _endedSub?.cancel();
    _snapshotSub?.cancel();
    _connectionSub?.cancel();
  }

  Future<void> _initialize() async {
    // Get user position first
    if (locationService.cachedPosition == null) {
      await locationService.getCurrentPosition();
    }

    // Initialize socket connection
    await socketService.init();
    _setupSocketListeners();

    // Set initial zone and join
    final agent = authRepository.currentAgent;
    final zones = agent?.assignedZones ?? [];
    if (zones.isNotEmpty) {
      _selectedZone = zones.first;
      socketService.joinZone(_selectedZone!.id);
    }

    // Load initial sessions via REST as fallback
    await _loadSessions();
  }

  void _setupSocketListeners() {
    // Connection status
    _connectionSub = socketService.onConnectionStatus.listen((status) {
      if (mounted) {
        setState(() {});
        if (status == ConnectionStatus.reconnected && _selectedZone != null) {
          socketService.joinZone(_selectedZone!.id);
        }
      }
    });

    // Zone snapshot (initial load when joining zone)
    _snapshotSub = socketService.onZoneSnapshot.listen((sessions) {
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    });

    // New session created
    _createdSub = socketService.onSessionCreated.listen((session) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          // Add only if not already in list
          if (!_sessions.any((s) => s.id == session.id)) {
            _sessions = [..._sessions, session];
          }
        });
        _showNotification(l10n.newSession(session.licensePlate), Icons.add_circle);
      }
    });

    // Session updated
    _updatedSub = socketService.onSessionUpdated.listen((session) {
      if (mounted) {
        setState(() {
          _sessions = _sessions.map((s) => s.id == session.id ? session : s).toList();
          if (_selectedSession?.id == session.id) {
            _selectedSession = session;
          }
        });
      }
    });

    // Session expiring warning
    _expiringSub = socketService.onSessionExpiring.listen((event) {
      if (mounted) {
        setState(() {
          _sessions = _sessions
              .map((s) => s.id == event.session.id ? event.session : s)
              .toList();
        });
        _showExpiringNotification(event);
      }
    });

    // Session ended
    _endedSub = socketService.onSessionEnded.listen((event) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _sessions = _sessions.where((s) => s.id != event.sessionId).toList();
          if (_selectedSession?.id == event.sessionId) {
            _selectedSession = null;
          }
        });
        _showNotification(
          l10n.sessionEvent(event.reason, event.sessionId.substring(0, 8)),
          Icons.remove_circle,
        );
      }
    });
  }

  Future<void> _loadSessions() async {
    if (_selectedZone == null) {
      final agent = authRepository.currentAgent;
      final zones = agent?.assignedZones ?? [];
      if (zones.isEmpty) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isLoading = false;
          _error = l10n.noAssignedZones;
        });
        return;
      }
      _selectedZone = zones.first;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions = await activeSessionsRepository.getActiveSessionsByZone(
        _selectedZone!.id,
      );
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _onZoneChanged(ParkingZone zone) {
    if (zone.id == _selectedZone?.id) return;

    setState(() {
      _selectedZone = zone;
      _isLoading = true;
      _sessions = [];
    });

    // Join the new zone room (will receive snapshot)
    socketService.joinZone(zone.id);

    // Also load via REST as backup
    _loadSessions();
  }

  LatLng _getInitialCenter() {
    final pos = locationService.cachedPosition;
    if (pos != null) {
      return LatLng(pos.latitude, pos.longitude);
    }

    final agent = authRepository.currentAgent;
    final zones = agent?.assignedZones ?? [];
    if (zones.isNotEmpty && zones.first.location != null) {
      final loc = zones.first.location!;
      return LatLng(loc.latitude, loc.longitude);
    }

    return const LatLng(33.5731, -7.5898);
  }

  void _showNotification(String message, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showExpiringNotification(ExpiringSessionEvent event) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          event.isCritical
              ? l10n.criticalExpiring(event.session.licensePlate, event.minutesRemaining)
              : l10n.sessionExpiring(event.session.licensePlate, event.minutesRemaining),
        ),
        backgroundColor: event.isCritical ? AppColors.error : AppColors.warning,
        duration: Duration(seconds: event.isCritical ? 10 : 5),
        action: SnackBarAction(
          label: l10n.view,
          textColor: Colors.white,
          onPressed: () {
            _onMarkerTapped(event.session);
            final lat = event.session.latitude;
            final lng = event.session.longitude;
            if (lat != null && lng != null) {
              _mapController.move(LatLng(lat, lng), 17);
            }
          },
        ),
      ),
    );
  }

  void _onMarkerTapped(ParkingSession session) {
    setState(() {
      _selectedSession = session;
    });
  }

  void _closeSessionDetails() {
    setState(() {
      _selectedSession = null;
    });
  }

  Color _getMarkerColor(ParkingSession session) {
    if (session.isExpired) {
      return AppColors.error;
    }
    if (session.remainingMinutes <= 10) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final agent = authRepository.currentAgent;
    final zones = agent?.assignedZones ?? [];
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeSessions),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              socketService.isConnected ? Icons.wifi : Icons.wifi_off,
              color: socketService.isConnected ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          // Zone selector dropdown
          if (zones.length > 1)
            PopupMenuButton<ParkingZone>(
              icon: const Icon(Icons.location_on),
              tooltip: l10n.selectZone,
              onSelected: _onZoneChanged,
              itemBuilder: (context) => zones.map((zone) {
                final isSelected = zone.id == _selectedZone?.id;
                return PopupMenuItem(
                  value: zone,
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(Icons.check, size: 18, color: AppColors.primary)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(zone.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSessions,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _getInitialCenter(),
            initialZoom: 15,
            minZoom: 10,
            maxZoom: 19,
            onTap: (_, __) => _closeSessionDetails(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.parkup.agent',
              maxZoom: 19,
            ),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),

        // Session count and zone badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_parking, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  l10n.activeCount(_sessions.length),
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                if (_selectedZone != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 16,
                    color: AppColors.border,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedZone!.name,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Legend
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem(AppColors.success, l10n.valid),
                const SizedBox(height: 4),
                _buildLegendItem(AppColors.warning, l10n.lessThan10Min),
                const SizedBox(height: 4),
                _buildLegendItem(AppColors.error, l10n.expiredStatus),
              ],
            ),
          ),
        ),

        // My location button
        Positioned(
          bottom: _selectedSession != null ? 220 : 24,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'myLocation',
            onPressed: _centerOnMyLocation,
            backgroundColor: AppColors.surface,
            child: Icon(Icons.my_location, color: AppColors.primary),
          ),
        ),

        // Selected session details panel
        if (_selectedSession != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSessionDetailsPanel(_selectedSession!),
          ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    return _sessions
        .where((s) => s.latitude != null && s.longitude != null)
        .map((session) {
      final isSelected = _selectedSession?.id == session.id;
      final color = _getMarkerColor(session);

      return Marker(
        point: LatLng(session.latitude!, session.longitude!),
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        child: GestureDetector(
          onTap: () => _onMarkerTapped(session),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.directions_car,
                color: Colors.white,
                size: isSelected ? 24 : 20,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildSessionDetailsPanel(ParkingSession session) {
    final l10n = AppLocalizations.of(context)!;
    final remainingMinutes = session.remainingMinutes;
    final isExpired = session.isExpired;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LicensePlateDisplay.fromString(
                        session.licensePlate,
                        scale: 0.9,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.zoneName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _closeSessionDetails,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpired
                    ? AppColors.error.withValues(alpha: 0.1)
                    : remainingMinutes <= 10
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpired ? Icons.timer_off : Icons.timer,
                    color: _getMarkerColor(session),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExpired
                              ? l10n.expiredStatus
                              : l10n.minutesRemaining(remainingMinutes),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getMarkerColor(session),
                          ),
                        ),
                        Text(
                          l10n.endsAt(_formatTime(session.endTime)),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.schedule,
                    l10n.duration,
                    '${session.durationMinutes} min',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.attach_money,
                    l10n.amount,
                    '${session.amount.toStringAsFixed(2)} MAD',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _centerOnMyLocation() async {
    final pos = locationService.cachedPosition ??
        await locationService.getCurrentPosition();
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 17);
    }
  }
}
