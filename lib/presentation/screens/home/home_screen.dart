import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/child_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../scan/qr_scanner_screen.dart';
import '../scan/scanned_child_sheet.dart';
import 'home_body.dart';
import '../visits/visits_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.isOnline.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    ConnectivityService.instance.isOnline
        .removeListener(_onConnectivityChanged);
    super.dispose();
  }

  /// When a connection returns, refresh what was stale and push up anything
  /// recorded while offline — a worker walking back into signal should not have
  /// to remember to sync.
  Future<void> _onConnectivityChanged() async {
    if (!mounted || !ConnectivityService.instance.isOnline.value) return;

    // Re-confirm the session and reload the lists that were served from cache.
    unawaited(ref.read(authProvider.notifier).refreshProfile());
    ref.invalidate(childrenProvider);
    ref.invalidate(facilitiesProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(reportsProvider);

    final settings = ref.read(settingsProvider);
    if (!settings.autoSync) return;

    final onMobile =
        ConnectivityService.instance.kind.value == ConnectivityResult.mobile;
    if (onMobile && !settings.syncOnMobileData) return;

    final repo = ref.read(syncRepositoryProvider);
    if (repo.pendingCount == 0 || _syncing) return;

    _syncing = true;
    try {
      final result = await repo.upload();
      ref.invalidate(syncStatusProvider);
      ref.invalidate(childrenProvider);
      ref.invalidate(activityProvider);
      ref.invalidate(alertsProvider);
      if (!mounted || result.totalSaved == 0) return;
      if (!settings.syncNotifications) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Back online — synced ${result.totalSaved} record(s).'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // Still unreachable — the queue keeps the work until the next attempt.
    } finally {
      _syncing = false;
    }
  }

  /// Bottom-nav index 2 is Scan QR — it opens the live camera scanner.
  Future<void> _goTo(int i) async {
    if (i == 2) {
      final child = await Navigator.of(context).push<ChildModel?>(
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );
      if (child != null && mounted) {
        showScannedChildSheet(context, child);
      }
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          HomeBody(onNavigate: _goTo),
          VisitsScreen(onNavigate: _goTo),
          const SizedBox.shrink(), // slot 2 — Scan QR opens the camera
          const ReportsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _index,
        onTap: _goTo,
      ),
    );
  }
}
