import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';

/// Wraps child content and shows a banner when offline
/// - Red banner when offline: "No internet connection"
/// - Green banner when back online: "Back online" (auto-dismisses after 3s)
class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  StreamSubscription<bool>? _subscription;
  bool _isConnected = true;
  bool _showBackOnline = false;
  bool _wasOffline = false;
  Timer? _dismissTimer;

  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _isConnected = connectivityService.isConnected;
    if (!_isConnected) {
      _wasOffline = true;
      _animController.value = 1.0;
    }

    _subscription = connectivityService.onConnectivityChanged.listen((connected) {
      setState(() {
        _isConnected = connected;

        if (!connected) {
          // Went offline
          _wasOffline = true;
          _showBackOnline = false;
          _dismissTimer?.cancel();
          _animController.forward();
        } else if (_wasOffline) {
          // Came back online after being offline
          _showBackOnline = true;
          _animController.forward();
          _dismissTimer?.cancel();
          _dismissTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              _animController.reverse().then((_) {
                if (mounted) {
                  setState(() {
                    _showBackOnline = false;
                    _wasOffline = false;
                  });
                }
              });
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = !_isConnected || _showBackOnline;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        if (showBanner)
          SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: _isConnected ? AppColors.success : AppColors.error,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isConnected ? Icons.wifi : Icons.wifi_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isConnected
                            ? (l10n?.backOnline ?? 'Back online')
                            : (l10n?.noInternetConnection ?? 'No internet connection'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
