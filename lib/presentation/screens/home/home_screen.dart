import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/alert_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import 'home_body.dart';
import '../visits/visits_screen.dart';
import '../reports/reports_screen.dart';
import '../children/vaccinated_children_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.setForeground(true);
    ConnectivityService.instance.isOnline.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConnectivityService.instance.isOnline
        .removeListener(_onConnectivityChanged);
    super.dispose();
  }

  /// A confirmation belongs on screen when the worker is looking at it, and in
  /// the tray only when they are not.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    NotificationService.instance
        .setForeground(state == AppLifecycleState.resumed);
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
      // The queue has drained, so the standing "waiting to sync" notification
      // is no longer true.
      unawaited(NotificationService.instance.outboxPending(repo.pendingCount));
      if (result.totalSaved == 0) return;

      // In the tray only if the worker was not watching; on screen if they
      // were. Never both.
      unawaited(NotificationService.instance.syncCompleted(
        result.totalSaved,
        enabled: settings.syncNotifications,
      ));
      if (!mounted || !settings.syncNotifications) return;
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

  /// Switches tab. Every slot is now a real tab: slot 2 used to launch the
  /// camera scanner and return, which is why this was async.
  void _goTo(int i) {
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    // The alerts feed is the one source of truth for what is worth telling a
    // worker. The service keeps its own record of what it has already
    // announced, so this cannot notify twice for the same alert, and several
    // arriving together collapse into one summary.
    ref.listen<AsyncValue<List<AlertModel>>>(alertsProvider, (_, next) {
      final alerts = next.valueOrNull;
      if (alerts == null || alerts.isEmpty) return;
      final read = ref.read(alertsRepositoryProvider).readIds;
      unawaited(NotificationService.instance.alertsRaised(
        alerts.where((a) => !read.contains(a.id)).toList(),
        enabled: ref.read(settingsProvider).alertNotifications,
      ));
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          HomeBody(onNavigate: _goTo),
          VisitsScreen(onNavigate: _goTo),
          // Slot 2 was the QR camera. It is now the vaccinated record, which
          // is a place a worker returns to rather than a one-shot action.
          const VaccinatedChildrenScreen(showBack: false),
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
