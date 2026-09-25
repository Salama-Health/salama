import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/facility_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/brand_header.dart';
import '../../widgets/common/offline_banner.dart';
import '../activity/activity_screen.dart';
import '../alerts/alerts_screen.dart';
import '../children/child_code_sheet.dart';
import '../children/register_child_screen.dart';
import 'facility_sheets.dart';
import 'sync_modal.dart';

class HomeBody extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  const HomeBody({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(currentWorkerProvider);
    final firstName = (worker?.name.split(' ').first) ?? 'there';

    final childrenAsync = ref.watch(childrenProvider);
    final facilitiesAsync = ref.watch(facilitiesProvider);
    final activityAsync = ref.watch(activityProvider);
    final syncAsync = ref.watch(syncStatusProvider);

    final children = childrenAsync.valueOrNull ?? const <ChildModel>[];
    final facilities = facilitiesAsync.valueOrNull ?? const <FacilityModel>[];

    final shown = facilities.take(4).toList();
    final atRisk = facilities
        .where((f) => f.assigned && f.risk == FacilityRisk.danger)
        .length;
    final total = children.length;
    final highPriority = children
        .where((c) =>
            c.riskBand == RiskBand.high || c.riskBand == RiskBand.medium)
        .length;
    final dueSoon =
        children.where((c) => c.status == VisitStatus.toVisit).length;
    final recentlyVisited =
        children.where((c) => c.status == VisitStatus.visited).length;

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: BrandHeader(
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                ConnectionPill(),
                SizedBox(width: 8),
                _NotificationBell(),
              ],
            ),
          ),
        ),
        const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(childrenProvider);
              ref.invalidate(facilitiesProvider);
              ref.invalidate(activityProvider);
              ref.invalidate(syncStatusProvider);
              await Future.wait([
                ref.read(childrenProvider.future),
                ref.read(facilitiesProvider.future),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                AppDimensions.spaceMD,
                AppDimensions.screenPadding,
                AppDimensions.spaceXXL,
              ),
              children: [
                Text('Hello, $firstName 👋',
                    style: AppTextStyles.h1.copyWith(fontSize: 19)),
                const SizedBox(height: 1),
                Text('${worker?.role ?? "Community Health Worker"} · ${worker?.county ?? ""}',
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: AppDimensions.spaceMD),
                _WorkerSummaryCard(
                  county: worker?.county ?? '—',
                  facilities: worker?.facilitiesCount ?? facilities.length,
                  children: total,
                  atRisk: atRisk,
                ),
                const SizedBox(height: AppDimensions.spaceSM),

                _QuickActions(
                  onRegister: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const RegisterChildScreen()),
                  ),
                  onScan: () => showChildCodeSheet(context),
                  onVaccinated: () => onNavigate(2),
                ),
                const SizedBox(height: AppDimensions.spaceSM),

                _PriorityVisitCard(
                  total: total,
                  highPriority: highPriority,
                  dueSoon: dueSoon,
                  recentlyVisited: recentlyVisited,
                  onTap: () => onNavigate(1),
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                _SectionHeader(
                  title: 'Facility risk',
                  action: 'View all',
                  onAction: () => showAllFacilitiesSheet(context, facilities),
                ),
                const SizedBox(height: 6),
                facilitiesAsync.when(
                  loading: () => const _SectionLoader(),
                  error: (e, _) => _SectionError(
                      message: '$e',
                      onRetry: () => ref.invalidate(facilitiesProvider)),
                  data: (_) => Column(
                    children: shown
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: FacilityCard(
                                facility: f,
                                onTap: () =>
                                    showFacilityDetailSheet(context, f),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceSM),

                ValueListenableBuilder<bool>(
                  valueListenable: ConnectivityService.instance.isOnline,
                  builder: (_, online, _) => _SyncCard(
                    isOnline: online,
                    pending: syncAsync.valueOrNull?.pendingRecords ?? 0,
                    lastSync: syncAsync.valueOrNull?.lastSyncLabel ?? '—',
                    onSync: () => showSyncModal(context),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                _SectionHeader(
                  title: 'Recent activity',
                  action: 'View all',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ActivityScreen()),
                  ),
                ),
                const SizedBox(height: 6),
                activityAsync.when(
                  loading: () => const _SectionLoader(),
                  error: (e, _) => _SectionError(
                      message: '$e',
                      onRetry: () => ref.invalidate(activityProvider)),
                  data: (items) => items.isEmpty
                      ? const _EmptyActivity()
                      : _RecentActivityCard(items: items),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared small states ──────────────────────────────────────────────────────
class _SectionLoader extends StatelessWidget {
  const _SectionLoader();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _SectionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Couldn’t load. $message',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionMuted),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text('No recent activity',
              style: AppTextStyles.captionMuted),
        ),
      );
}

// ── Notification bell ────────────────────────────────────────────────────────
/// Opens the alerts screen. The badge is the real number of unread alerts —
/// facilities at risk, overdue children and work waiting to sync — so a zero
/// count shows no badge at all.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadAlertCountProvider);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AlertsScreen()),
      ),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.notifications_none_rounded,
                  size: 22, color: AppColors.primary),
            ),
            if (count > 0)
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 14, minHeight: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    border:
                        Border.all(color: AppColors.background, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(count > 9 ? '9+' : '$count',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Quick actions ────────────────────────────────────────────────────────────
/// What a worker starts a visit with: adding a new child, pulling up one who
/// already has a code, or reviewing the doses they have already given.
class _QuickActions extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onScan;
  final VoidCallback onVaccinated;

  const _QuickActions({
    required this.onRegister,
    required this.onScan,
    required this.onVaccinated,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ActionTile(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Register a child',
            hint: 'New to the register',
            primary: true,
            onTap: onRegister,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSM),
        Expanded(
          flex: 2,
          child: _ActionTile(
            icon: Icons.tag_rounded,
            label: 'Enter code',
            hint: 'Find a record',
            primary: false,
            onTap: onScan,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceSM),
        Expanded(
          flex: 2,
          child: _ActionTile(
            icon: Icons.vaccines_rounded,
            label: 'Vaccinated',
            hint: 'Doses you gave',
            primary: false,
            onTap: onVaccinated,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final bool primary;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.textOnPrimary : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.cardBackground,
          gradient: primary ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(
            color: primary
                ? Colors.transparent
                : AppColors.primary.withValues(alpha: 0.22),
            width: AppDimensions.borderNormal,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primary
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Icon(icon, size: 16, color: fg),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4.copyWith(color: fg)),
                  Text(hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionMuted.copyWith(
                        color: primary
                            ? Colors.white.withValues(alpha: 0.75)
                            : AppColors.textTertiary,
                        fontSize: 10,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.h2)),
        GestureDetector(
          onTap: onAction,
          child: Row(
            children: [
              Text(action,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  )),
              const Icon(Icons.chevron_right_rounded,
                  size: 15, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Worker summary card ──────────────────────────────────────────────────────
class _WorkerSummaryCard extends StatelessWidget {
  final String county;
  final int facilities;
  final int children;
  final int atRisk;

  const _WorkerSummaryCard({
    required this.county,
    required this.facilities,
    required this.children,
    required this.atRisk,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      color: AppColors.primary,
      borderColor: AppColors.primary,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: const Icon(Icons.place_outlined,
                      color: Colors.white, size: 17),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your coverage area',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                          )),
                      Text(county,
                          style: AppTextStyles.h3
                              .copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Row(
              children: [
                _WorkerStat(
                    value: '$facilities',
                    label: 'Facilities',
                    icon: Icons.local_hospital_outlined),
                _WorkerStatDivider(),
                _WorkerStat(
                    value: '$children',
                    label: 'Children',
                    icon: Icons.groups_outlined),
                _WorkerStatDivider(),
                _WorkerStat(
                    value: '$atRisk',
                    label: 'At risk',
                    icon: Icons.warning_amber_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: Colors.white.withValues(alpha: 0.16),
    );
  }
}

class _WorkerStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _WorkerStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(value,
                  style: AppTextStyles.statNumberSmall
                      .copyWith(fontSize: 17, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 1),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

// ── Priority visit card ──────────────────────────────────────────────────────
class _PriorityVisitCard extends StatelessWidget {
  final int total;
  final int highPriority;
  final int dueSoon;
  final int recentlyVisited;
  final VoidCallback onTap;
  const _PriorityVisitCard({
    required this.total,
    required this.highPriority,
    required this.dueSoon,
    required this.recentlyVisited,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: AppColors.primarySurface.withValues(alpha: 0.6),
      borderColor: AppColors.primary.withValues(alpha: 0.18),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.13),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Priority visit list', style: AppTextStyles.h3),
                      Text('Children who need vaccines most',
                          style: AppTextStyles.captionMuted),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.13),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Row(
                    children: [
                      Text('$total',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(width: 3),
                      Text('children',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 9.5,
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.primary),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.cardPaddingSm, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.outlined_flag_rounded,
                    iconColor: AppColors.riskHigh,
                    value: '$highPriority',
                    label: 'High priority',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.warningMid,
                    value: '$dueSoon',
                    label: 'Due soon',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.success,
                    value: '$recentlyVisited',
                    label: 'Recently visited',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.primary.withValues(alpha: 0.12),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(value,
                style: AppTextStyles.statNumberSmall.copyWith(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 1),
        Text(label,
            textAlign: TextAlign.center,
            style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
      ],
    );
  }
}

// ── Sync data card ───────────────────────────────────────────────────────────
class _SyncCard extends StatelessWidget {
  final bool isOnline;
  final int pending;
  final String lastSync;
  final VoidCallback onSync;
  const _SyncCard({
    required this.isOnline,
    required this.pending,
    required this.lastSync,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: const Icon(Icons.cloud_sync_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sync data', style: AppTextStyles.h3),
                    Text('Keep your records up to date',
                        style: AppTextStyles.captionMuted),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.success
                          : AppColors.warningMid,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(isOnline ? 'Online' : 'Offline',
                      style: AppTextStyles.caption.copyWith(
                        color: isOnline
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SyncStat(
                  value: '$pending',
                  label: 'Records awaiting sync',
                  highlight: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SyncStat(
                  value: lastSync,
                  label: 'Last synced',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onSync,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_rounded,
                        size: 15, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('Sync data',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStat extends StatelessWidget {
  final String value;
  final String label;
  final bool highlight;
  const _SyncStat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.warningSurface
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: highlight
              ? AppColors.warningMid.withValues(alpha: 0.3)
              : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w800,
                color: highlight
                    ? AppColors.warning
                    : AppColors.textPrimary,
              )),
          const SizedBox(height: 1),
          Text(label,
              style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Recent activity ──────────────────────────────────────────────────────────
class _RecentActivityCard extends StatelessWidget {
  final List<ActivityModel> items;
  const _RecentActivityCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final shown = items.take(4).toList();
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.cardPaddingSm, vertical: 4),
      child: Column(
        children: List.generate(shown.length, (i) {
          final a = shown[i];
          return Container(
            decoration: BoxDecoration(
              border: i < shown.length - 1
                  ? const Border(
                      bottom: BorderSide(
                          color: AppColors.borderLight, width: 1))
                  : null,
            ),
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: a.type.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Icon(a.type.icon, size: 16, color: a.type.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: AppTextStyles.h4),
                      const SizedBox(height: 1),
                      Text(a.subtitle,
                          style: AppTextStyles.captionMuted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(a.time,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          );
        }),
      ),
    );
  }
}
