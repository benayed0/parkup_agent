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

/// Filter options for expired sessions time range
enum ExpiredTimeFilter {
  last15min(0.25, 'last15min'),
  last24h(24, 'last24h');

  final double maxExpiredHours;
  final String l10nKey;

  const ExpiredTimeFilter(this.maxExpiredHours, this.l10nKey);
}

/// Helper class to group sessions by zone
class ZoneGroup {
  final String zoneId;
  final String zoneName;
  final List<EnforcementSession> sessions;
  final List<List<double>>? boundaries;
  final double? latitude;
  final double? longitude;

  ZoneGroup({
    required this.zoneId,
    required this.zoneName,
    required this.sessions,
    this.boundaries,
    this.latitude,
    this.longitude,
  });

  bool get hasExpired => sessions.any((s) => s.isExpired && !s.alreadyTicketed);
  bool get hasExpiringSoon => sessions.any((s) => !s.isExpired);
  int get expiredCount =>
      sessions.where((s) => s.isExpired && !s.alreadyTicketed).length;
  int get expiringSoonCount => sessions.where((s) => !s.isExpired).length;
}

/// Enforcement sessions map page
/// Displays expired and soon-to-expire parking sessions for agents
class ActiveSessionsMapPage extends StatefulWidget {
  const ActiveSessionsMapPage({super.key});

  @override
  State<ActiveSessionsMapPage> createState() => _ActiveSessionsMapPageState();
}

class _ActiveSessionsMapPageState extends State<ActiveSessionsMapPage> {
  final MapController _mapController = MapController();
  EnforcementData? _enforcementData;
  bool _isLoading = true;
  String? _error;
  EnforcementSession? _selectedSession;
  ParkingZone? _selectedZone;
  String _searchQuery = '';
  bool _isSheetExpanded = false;
  bool _showTicketed = false; // Toggle to show already ticketed sessions
  ExpiredTimeFilter _expiredTimeFilter = ExpiredTimeFilter.last15min;

  // Socket subscriptions for real-time notifications
  StreamSubscription<ExpiringSessionEvent>? _expiringSub;
  StreamSubscription<SessionEndedEvent>? _endedSub;
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

  List<EnforcementSession> get _allSessions =>
      _enforcementData?.allSessions ?? [];

  List<EnforcementSession> get _filteredSessions {
    if (_searchQuery.isEmpty) return _allSessions;
    final query = _searchQuery.toLowerCase();
    return _allSessions
        .where((s) => s.licensePlate.toLowerCase().contains(query))
        .toList();
  }

  void _cancelSubscriptions() {
    _expiringSub?.cancel();
    _endedSub?.cancel();
    _connectionSub?.cancel();
  }

  Future<void> _initialize() async {
    // Get user position first
    if (locationService.cachedPosition == null) {
      await locationService.getCurrentPosition();
    }

    // Initialize socket connection for real-time notifications
    await socketService.init();
    _setupSocketListeners();

    // Set initial zone and join
    final agent = authRepository.currentAgent;
    final zones = agent?.assignedZones ?? [];
    if (zones.isNotEmpty) {
      _selectedZone = zones.first;
      socketService.joinZone(_selectedZone!.id);
    }

    // Load enforcement data
    await _loadEnforcementData();
  }

  void _setupSocketListeners() {
    // Connection status
    _connectionSub = socketService.onConnectionStatus.listen((status) {
      if (mounted) {
        setState(() {});
        if (status == ConnectionStatus.reconnected && _selectedZone != null) {
          socketService.joinZone(_selectedZone!.id);
          _loadEnforcementData(); // Refresh data on reconnect
        }
      }
    });

    // Session expiring warning - refresh to get updated data
    _expiringSub = socketService.onSessionExpiring.listen((event) {
      if (mounted) {
        _showExpiringNotification(event);
        // Refresh enforcement data to get latest state
        _loadEnforcementData();
      }
    });

    // Session ended - refresh data
    _endedSub = socketService.onSessionEnded.listen((event) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showNotification(
          l10n.sessionEvent(event.reason, event.sessionId.substring(0, 8)),
          Icons.remove_circle,
        );
        // Refresh enforcement data
        _loadEnforcementData();
      }
    });
  }

  Future<void> _loadEnforcementData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = _enforcementData == null; // Only show loading on first load
      _error = null;
    });

    try {
      final data = await activeSessionsRepository.getEnforcementData(
        zoneId: _selectedZone?.id,
        expiringThresholdMinutes: 15,
        maxExpiredHours: _expiredTimeFilter.maxExpiredHours,
        includeTicketed: _showTicketed,
      );
      if (mounted) {
        setState(() {
          _enforcementData = data;
          _isLoading = false;
          // Clear selected session if it's no longer in the list
          if (_selectedSession != null &&
              !data.allSessions.any((s) => s.id == _selectedSession!.id)) {
            _selectedSession = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _onZoneChanged(ParkingZone zone) {
    if (zone.id == _selectedZone?.id) return;

    setState(() {
      _selectedZone = zone;
      _enforcementData = null;
      _isLoading = true;
    });

    // Join the new zone room for real-time notifications
    socketService.joinZone(zone.id);

    // Load enforcement data for the new zone
    _loadEnforcementData();
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
              ? l10n.criticalExpiring(
                  event.session.licensePlate,
                  event.minutesRemaining,
                )
              : l10n.sessionExpiring(
                  event.session.licensePlate,
                  event.minutesRemaining,
                ),
        ),
        backgroundColor: event.isCritical ? AppColors.error : AppColors.warning,
        duration: Duration(seconds: event.isCritical ? 10 : 5),
        action: SnackBarAction(
          label: l10n.refresh,
          textColor: Colors.white,
          onPressed: _loadEnforcementData,
        ),
      ),
    );
  }

  void _onMarkerTapped(EnforcementSession session) {
    setState(() {
      _selectedSession = session;
    });
  }

  void _closeSessionDetails() {
    setState(() {
      _selectedSession = null;
    });
  }

  void _toggleSheet() {
    setState(() {
      _isSheetExpanded = !_isSheetExpanded;
    });
  }

  void _toggleShowTicketed() {
    setState(() {
      _showTicketed = !_showTicketed;
    });
    _loadEnforcementData();
  }

  void _onExpiredFilterChanged(ExpiredTimeFilter filter) {
    if (filter == _expiredTimeFilter) return;
    setState(() {
      _expiredTimeFilter = filter;
    });
    _loadEnforcementData();
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else if (minutes < 1440) {
      // Less than 24 hours
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    } else {
      // Days
      final days = minutes ~/ 1440;
      final hours = (minutes % 1440) ~/ 60;
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
  }

  Color _getMarkerColor(EnforcementSession session) {
    if (session.isExpired) {
      // Red for expired, but lighter if already ticketed
      return session.alreadyTicketed
          ? AppColors.error.withValues(alpha: 0.5)
          : AppColors.error;
    }
    // Warning color for expiring soon
    final minutes = session.minutesRemaining ?? 0;
    if (minutes <= 5) {
      return AppColors.warning;
    }
    return AppColors.warning.withValues(alpha: 0.7);
  }

  /// Get icon for location confidence level
  IconData _getLocationConfidenceIcon(EnforcementSession session) {
    switch (session.locationSource) {
      case LocationSource.gpsAuto:
        return session.locationWithinZone
            ? Icons.gps_fixed
            : Icons.gps_not_fixed;
      case LocationSource.userPin:
        return Icons.touch_app;
      case LocationSource.zoneCentroid:
        return Icons.location_searching;
      case LocationSource.unknown:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = authRepository.currentAgent;
    final zones = agent?.assignedZones ?? [];
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.enforcementMap),
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
          // Toggle to show ticketed sessions
          IconButton(
            icon: Icon(
              _showTicketed == true ? Icons.visibility : Icons.visibility_off,
              color: _showTicketed == true ? AppColors.success : null,
            ),
            tooltip: _showTicketed == true ? l10n.hideTicketed : l10n.showTicketed,
            onPressed: _toggleShowTicketed,
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
            onPressed: _loadEnforcementData,
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
            Text(
              _error!,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEnforcementData,
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
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.parkup.agent',
              maxZoom: 19,
            ),
            // Zone boundaries layer
            PolygonLayer(polygons: _buildZonePolygons()),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),

        // My location button
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'myLocation',
            onPressed: _centerOnMyLocation,
            backgroundColor: AppColors.surface,
            child: Icon(Icons.my_location, color: AppColors.primary),
          ),
        ),

        // Bottom sheet with sessions list
        Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomSheet()),

        // Selected session details overlay - only show when sheet is collapsed
        if (_selectedSession != null && !_isSheetExpanded)
          Positioned(
            bottom: 70,
            left: 16,
            right: 16,
            child: _buildSessionDetailsCard(_selectedSession!),
          ),
      ],
    );
  }

  /// Group sessions by zone for polygon rendering and list view
  List<ZoneGroup> _groupSessionsByZone(List<EnforcementSession> sessions) {
    final Map<String, ZoneGroup> groups = {};

    for (final session in sessions) {
      if (groups.containsKey(session.zoneId)) {
        groups[session.zoneId]!.sessions.add(session);
      } else {
        groups[session.zoneId] = ZoneGroup(
          zoneId: session.zoneId,
          zoneName: session.zoneName,
          sessions: [session],
          boundaries: session.zoneBoundaries,
          latitude: session.zoneLatitude,
          longitude: session.zoneLongitude,
        );
      }
    }

    // Sort by priority: zones with expired sessions first
    final sortedGroups = groups.values.toList()
      ..sort((a, b) {
        if (a.hasExpired && !b.hasExpired) return -1;
        if (!a.hasExpired && b.hasExpired) return 1;
        return b.sessions.length.compareTo(a.sessions.length);
      });

    return sortedGroups;
  }

  /// Build zone boundary polygons with violation-based coloring
  List<Polygon> _buildZonePolygons() {
    final groups = _groupSessionsByZone(_allSessions);
    final polygons = <Polygon>[];

    for (final group in groups) {
      if (group.boundaries == null || group.boundaries!.isEmpty) continue;

      // Convert boundaries to LatLng points
      final points = group.boundaries!.map((coord) {
        return LatLng(coord[1], coord[0]); // [lng, lat] -> LatLng(lat, lng)
      }).toList();

      // Determine color based on session status
      Color fillColor;
      Color borderColor;
      if (group.hasExpired) {
        fillColor = AppColors.error.withValues(alpha: 0.15);
        borderColor = AppColors.error.withValues(alpha: 0.6);
      } else if (group.hasExpiringSoon) {
        fillColor = AppColors.warning.withValues(alpha: 0.10);
        borderColor = AppColors.warning.withValues(alpha: 0.5);
      } else {
        fillColor = Colors.transparent;
        borderColor = AppColors.border;
      }

      polygons.add(
        Polygon(
          points: points,
          color: fillColor,
          borderColor: borderColor,
          borderStrokeWidth: 2,
        ),
      );
    }

    return polygons;
  }

  List<Marker> _buildMarkers() {
    return _allSessions
        .where((s) => s.displayLatitude != null && s.displayLongitude != null)
        .map((session) {
          final isSelected = _selectedSession?.id == session.id;

          return Marker(
            point: LatLng(session.displayLatitude!, session.displayLongitude!),
            width: isSelected ? 50 : 40,
            height: isSelected ? 50 : 40,
            child: GestureDetector(
              onTap: () => _onMarkerTapped(session),
              child: _buildMarkerWidget(session, isSelected),
            ),
          );
        })
        .toList();
  }

  /// Build marker widget based on location confidence
  Widget _buildMarkerWidget(EnforcementSession session, bool isSelected) {
    final statusColor = _getMarkerColor(session);

    // High confidence: Sharp pin marker
    if (session.hasHighConfidenceLocation) {
      return _buildPreciseMarker(session, statusColor, isSelected);
    }

    // GPS outside zone: Sharp pin with warning border
    if (session.isLocationOutsideZone) {
      return _buildOutsideZoneMarker(session, statusColor, isSelected);
    }

    // Medium confidence (user pin): Soft circle marker
    if (session.hasMediumConfidenceLocation) {
      return _buildApproximateMarker(session, statusColor, isSelected);
    }

    // Low confidence: Large faded circle
    return _buildLowConfidenceMarker(session, statusColor, isSelected);
  }

  /// High confidence marker - sharp pin icon, full opacity
  Widget _buildPreciseMarker(
    EnforcementSession session,
    Color color,
    bool isSelected,
  ) {
    return Container(
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
          session.isExpired
              ? (session.alreadyTicketed ? Icons.check_circle : Icons.warning)
              : Icons.timer,
          color: Colors.white,
          size: isSelected ? 24 : 20,
        ),
      ),
    );
  }

  /// GPS location outside zone - sharp pin with orange warning border
  Widget _buildOutsideZoneMarker(
    EnforcementSession session,
    Color color,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.orange,
          width: isSelected ? 3 : 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          session.isExpired
              ? (session.alreadyTicketed ? Icons.check_circle : Icons.warning)
              : Icons.timer,
          color: Colors.white,
          size: isSelected ? 24 : 20,
        ),
      ),
    );
  }

  /// Medium confidence marker - softer circle, slight transparency
  Widget _buildApproximateMarker(
    EnforcementSession session,
    Color color,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.8),
          width: isSelected ? 3 : 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.location_on_outlined,
          color: Colors.white.withValues(alpha: 0.9),
          size: isSelected ? 22 : 18,
        ),
      ),
    );
  }

  /// Low confidence marker - large translucent circle
  Widget _buildLowConfidenceMarker(
    EnforcementSession session,
    Color color,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : color.withValues(alpha: 0.6),
          width: isSelected ? 3 : 2,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.question_mark,
          color: Colors.white.withValues(alpha: 0.8),
          size: isSelected ? 20 : 16,
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    final l10n = AppLocalizations.of(context)!;
    final filteredSessions = _filteredSessions;

    final screenHeight = MediaQuery.of(context).size.height;
    final collapsedHeight = 60.0;
    final expandedHeight = screenHeight * 0.65;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: _isSheetExpanded ? expandedHeight : collapsedHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar - always visible and tappable
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleSheet,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.sessions,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Expired badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_enforcementData?.expiredWithoutTicket ?? 0}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Expiring badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_enforcementData?.totalExpiringSoon ?? 0}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isSheetExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded content
          if (_isSheetExpanded)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Expired time filter chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: ExpiredTimeFilter.values.map((filter) {
                        final isSelected = _expiredTimeFilter == filter;
                        final label = filter == ExpiredTimeFilter.last15min
                            ? l10n.last15min
                            : l10n.last24h;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (_) => _onExpiredFilterChanged(filter),
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: AppTextStyles.caption.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Selected session details at top of sheet
                  if (_selectedSession != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _buildInlineSessionDetails(_selectedSession!),
                    ),
                    Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),
                  ],
                  // Search field using LicensePlateInput
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LicensePlateInput(
                      showTypeSelector: true,
                      compactTypeSelector: true,
                      onChanged: (plate) {
                        setState(() => _searchQuery = plate.formatted);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sessions list (grouped by zone)
                  if (filteredSessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: AppColors.success,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? l10n.noViolationsFound
                                  : l10n.noSessionsFound,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._buildZoneGroupedList(filteredSessions),
                  // Bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build zone-grouped list widgets
  List<Widget> _buildZoneGroupedList(List<EnforcementSession> sessions) {
    final groups = _groupSessionsByZone(sessions);
    final widgets = <Widget>[];

    for (final group in groups) {
      widgets.add(_buildZoneHeader(group));
      for (final session in group.sessions) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSessionListItem(session, showZone: false),
          ),
        );
      }
      widgets.add(Divider(height: 20, color: AppColors.border));
    }

    return widgets;
  }

  /// Build zone section header
  Widget _buildZoneHeader(ZoneGroup group) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: group.hasExpired ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              group.zoneName,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // Expired count badge
          if (group.expiredCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${group.expiredCount}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Expiring soon count badge
          if (group.expiringSoonCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${group.expiringSoonCount}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionListItem(
    EnforcementSession session, {
    bool showZone = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = _selectedSession?.id == session.id;
    final color = _getMarkerColor(session);

    return GestureDetector(
      onTap: () => _selectAndCenterSession(session),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                session.isExpired
                    ? (session.alreadyTicketed
                          ? Icons.check_circle
                          : Icons.warning)
                    : Icons.timer,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Session info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        session.licensePlate,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      if (session.alreadyTicketed) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.ticketed,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Show zone name if showZone is true, otherwise show location confidence
                  if (showZone)
                    Text(
                      session.zoneName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          _getLocationConfidenceIcon(session),
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getLocationConfidenceText(session),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Time status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                session.isExpired
                    ? '+${_formatDuration(session.minutesOverdue ?? 0)}'
                    : _formatDuration(session.minutesRemaining ?? 0),
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineSessionDetails(EnforcementSession session) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getMarkerColor(session);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Status icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.isExpired
                      ? (session.alreadyTicketed
                            ? Icons.check_circle
                            : Icons.warning)
                      : Icons.timer,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              // Plate and zone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.licensePlate,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      session.zoneName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // Location confidence indicator
                    Row(
                      children: [
                        Icon(
                          _getLocationConfidenceIcon(session),
                          size: 12,
                          color: session.isLocationOutsideZone
                              ? Colors.orange
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getLocationConfidenceText(session),
                          style: AppTextStyles.caption.copyWith(
                            color: session.isLocationOutsideZone
                                ? Colors.orange
                                : AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Time badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  session.isExpired
                      ? '+${_formatDuration(session.minutesOverdue ?? 0)}'
                      : _formatDuration(session.minutesRemaining ?? 0),
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Close button
              GestureDetector(
                onTap: _closeSessionDetails,
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // Action button for expired sessions without ticket
          if (session.isExpired && !session.alreadyTicketed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCreateTicket(session),
                icon: const Icon(Icons.receipt_long, size: 16),
                label: Text(l10n.createTicket),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (session.alreadyTicketed) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  l10n.alreadyTicketed,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Get localized location confidence text
  String _getLocationConfidenceText(EnforcementSession session) {
    final l10n = AppLocalizations.of(context)!;
    switch (session.locationSource) {
      case LocationSource.gpsAuto:
        return session.locationWithinZone ? l10n.locationGps : l10n.locationGpsOutsideZone;
      case LocationSource.userPin:
        return l10n.locationUserPlaced;
      case LocationSource.zoneCentroid:
        return l10n.locationZoneOnly;
      case LocationSource.unknown:
        return l10n.locationUnknown;
    }
  }

  void _selectAndCenterSession(EnforcementSession session) {
    setState(() {
      _selectedSession = session;
      _isSheetExpanded = false; // Collapse to show map with details card
    });
    // Center map on session (use display coordinates that account for low confidence fallback)
    if (session.displayLatitude != null && session.displayLongitude != null) {
      _mapController.move(
        LatLng(session.displayLatitude!, session.displayLongitude!),
        17,
      );
    }
  }

  Widget _buildSessionDetailsCard(EnforcementSession session) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getMarkerColor(session);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.isExpired
                      ? (session.alreadyTicketed
                            ? Icons.check_circle
                            : Icons.warning)
                      : Icons.timer,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LicensePlateDisplay.fromString(
                      session.licensePlate,
                      scale: 0.8,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.zoneName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Location confidence indicator
                    Row(
                      children: [
                        Icon(
                          _getLocationConfidenceIcon(session),
                          size: 12,
                          color: session.isLocationOutsideZone
                              ? Colors.orange
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getLocationConfidenceText(session),
                          style: AppTextStyles.caption.copyWith(
                            color: session.isLocationOutsideZone
                                ? Colors.orange
                                : AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _closeSessionDetails,
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status and time row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        session.isExpired ? Icons.warning : Icons.timer,
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        session.isExpired
                            ? '+${_formatDuration(session.minutesOverdue ?? 0)}'
                            : _formatDuration(session.minutesRemaining ?? 0),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (session.alreadyTicketed) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.ticketed,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          // Action button for expired sessions without ticket
          if (session.isExpired && !session.alreadyTicketed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCreateTicket(session),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: Text(l10n.createTicket),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToCreateTicket(EnforcementSession session) {
    // Navigate to check vehicle page with pre-filled plate data
    Navigator.of(context).pushNamed(
      '/check-vehicle',
      arguments: {
        'plate': session.plate,
        'licensePlate': session.licensePlate,
        'zoneId': session.zoneId,
      },
    );
  }

  void _centerOnMyLocation() async {
    final pos =
        locationService.cachedPosition ??
        await locationService.getCurrentPosition();
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 17);
    }
  }
}
