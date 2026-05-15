import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks live network reachability (Wi-Fi, mobile, ethernet…).
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  /// `true` when the device has any active network connection.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  /// The active connection kind — used for labels ("Wi-Fi" / "Mobile data").
  final ValueNotifier<ConnectivityResult> kind =
      ValueNotifier<ConnectivityResult>(ConnectivityResult.wifi);

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> init() async {
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (_) {
      isOnline.value = false;
    }
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    isOnline.value = online;
    kind.value = results.firstWhere(
      (r) => r != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
  }

  String get kindLabel => switch (kind.value) {
        ConnectivityResult.wifi => 'Wi-Fi',
        ConnectivityResult.mobile => 'Mobile data',
        ConnectivityResult.ethernet => 'Ethernet',
        ConnectivityResult.vpn => 'VPN',
        _ => 'No connection',
      };

  void dispose() => _sub?.cancel();
}
