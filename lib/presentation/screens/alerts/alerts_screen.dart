import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/alert_model.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/facility_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/brand_header.dart';
import '../../widgets/common/offline_banner.dart';
import '../home/facility_sheets.dart';
import '../home/sync_modal.dart';
import '../scan/child_detail_sheet.dart';

/// Everything asking for the worker's attention, in one place: facilities whose
/// cold chain is at risk, disruption windows about to open, children overdue on
/// doses, and work still waiting to sync.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertSeverity? _severity;
  AlertKind? _kind;

  List<AlertModel> _filter(List<AlertModel> all) {
    return all.where((a) {
      if (_severity != null && a.severity != _severity) return false;
      if (_kind != null && a.kind != _kind) return false;
      return true;
    }).toList();
  }

  Future<void> _open(AlertModel alert) async {
    await ref.read(alertsRepositoryProvider).markRead(alert.id);
    ref.read(alertReadTickProvider.notifier).state++;
    if (!mounted) return;

    if (alert.kind == AlertKind.sync) {
      showSyncModal(context);
      return;
    }
    if (alert.facilityId != null) {
      final facilities =
          ref.read(facilitiesProvider).valueOrNull ?? const <FacilityModel>[];
      final match = facilities.where((f) => f.id == alert.facilityId);
      if (match.isNotEmpty) {
        showFacilityDetailSheet(context, match.first);
        return;
      }
    }
    if (alert.childId != null) {
      final children =
          ref.read(childrenProvider).valueOrNull ?? const <ChildModel>[];
      final match = children.where((c) => c.id == alert.childId);
      if (match.isNotEmpty) {
        showChildDetailSheet(context, match.first);
        return;
      }
    }
    setState(() {}); // at minimum, clear the unread dot
  }

  Future<void> _markAllRead(List<AlertModel> alerts) async {
    await ref
        .read(alertsRepositoryProvider)
        .markAllRead(alerts.map((a) => a.id));
    ref.read(alertReadTickProvider.notifier).state++;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsProvider);
    final all = alertsAsync.valueOrNull ?? const <AlertModel>[];
    final read = ref.watch(alertsRepositoryProvider).readIds;
    ref.watch(alertReadTickProvider);

    final list = _filter(all);
    final critical =
        all.where((a) => a.severity == AlertSeverity.critical).length;
    final warning =
        all.where((a) => a.severity == AlertSeverity.warning).length;
    final info = all.where((a) => a.severity == AlertSeverity.info).length;
    final unread = all.where((a) => !read.contains(a.id)).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _Header(
              unread: unread,
              onBack: () => Navigator.pop(context),
              onMarkAll: all.isEmpty ? null : () => _markAllRead(all),
            ),
          ),
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(alertsProvider);
                await ref.read(alertsProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  AppDimensions.spaceMD,
                  AppDimensions.screenPadding,
                  AppDimensions.spaceXXL,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SeverityTile(
                          count: critical,
                          label: 'Critical',
                          color: AppColors.riskHigh,
                          surface: AppColors.riskHighLight,
                          selected: _severity == AlertSeverity.critical,
                          onTap: () => setState(() => _severity =
                              _severity == AlertSeverity.critical
                                  ? null
                                  : AlertSeverity.critical),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceSM),
                      Expanded(
                        child: _SeverityTile(
                          count: warning,
                          label: 'Warning',
                          color: AppColors.warningMid,
                          surface: AppColors.warningLight,
                          selected: _severity == AlertSeverity.warning,
                          onTap: () => setState(() => _severity =
                              _severity == AlertSeverity.warning
                                  ? null
                                  : AlertSeverity.warning),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceSM),
                      Expanded(
                        child: _SeverityTile(
                          count: info,
                          label: 'Info',
                          color: AppColors.info,
                          surface: AppColors.infoLight,
                          selected: _severity == AlertSeverity.info,
                          onTap: () => setState(() => _severity =
                              _severity == AlertSeverity.info
                                  ? null
                                  : AlertSeverity.info),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _KindChip(
                          label: 'All',
                          selected: _kind == null,
                          onTap: () => setState(() => _kind = null),
                        ),
                        ...AlertKind.values.map((k) {
                          final n = all.where((a) => a.kind == k).length;
                          if (n == 0) return const SizedBox.shrink();
                          return _KindChip(
                            label: '${k.label} ($n)',
                            icon: k.icon,
                            selected: _kind == k,
                            onTap: () => setState(
                                () => _kind = _kind == k ? null : k),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  alertsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _ErrorState(
                      message: '$e',
                      onRetry: () => ref.invalidate(alertsProvider),
                    ),
                    // Built lazily: an alert card is not cheap (stripe,
                    // wrapped body, action row) and a busy county can raise
                    // dozens at once.
                    data: (_) => list.isEmpty
                        ? _EmptyState(filtered: _severity != null || _kind != null)
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 7),
                            itemBuilder: (context, i) {
                              final a = list[i];
                              return AlertCard(
                                key: ValueKey(a.id),
                                alert: a,
                                unread: !read.contains(a.id),
                                onTap: () => _open(a),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int unread;
  final VoidCallback onBack;
  final VoidCallback? onMarkAll;

  const _Header({
    required this.unread,
    required this.onBack,
    this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, AppDimensions.spaceSM, 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
              color: AppColors.borderLight, width: AppDimensions.borderThin),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 20),
            tooltip: 'Back',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alerts', style: AppTextStyles.h1.copyWith(fontSize: 17)),
                Text(
                  unread == 0
                      ? 'Nothing new'
                      : '$unread unread ${unread == 1 ? "alert" : "alerts"}',
                  style: AppTextStyles.captionMuted,
                ),
              ],
            ),
          ),
          if (onMarkAll != null)
            TextButton(
              onPressed: onMarkAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Mark all read',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary)),
            ),
          const SizedBox(width: 4),
          const ConnectionPill(),
        ],
      ),
    );
  }
}

// ── Severity summary tile ────────────────────────────────────────────────────
class _SeverityTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color surface;
  final bool selected;
  final VoidCallback onTap;

  const _SeverityTile({
    required this.count,
    required this.label,
    required this.color,
    required this.surface,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? surface : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.45)
                : AppColors.borderLight,
            width: selected
                ? AppDimensions.borderMedium
                : AppDimensions.borderNormal,
          ),
        ),
        child: Column(
          children: [
            Text('$count',
                style: AppTextStyles.statNumberSmall
                    .copyWith(fontSize: 19, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderLight,
              width: 0.75,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 12,
                    color: selected
                        ? AppColors.textOnPrimary
                        : AppColors.textTertiary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert card ───────────────────────────────────────────────────────────────
class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final bool unread;
  final VoidCallback onTap;

  const AlertCard({
    super.key,
    required this.alert,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = alert.severity.color;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(
              color: unread
                  ? color.withValues(alpha: 0.30)
                  : AppColors.borderLight,
              width: AppDimensions.borderNormal),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity stripe
              Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppDimensions.radiusLG)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: alert.severity.surface,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSM),
                            ),
                            child:
                                Icon(alert.kind.icon, size: 15, color: color),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alert.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.h4.copyWith(
                                          fontWeight: unread
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (unread) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  alert.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          _Tag(
                            label: alert.severity.label,
                            color: color,
                            surface: alert.severity.surface,
                          ),
                          if (alert.timingLabel.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      size: 11,
                                      color: AppColors.textTertiary),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(alert.timingLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.captionMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded,
                              size: 17, color: AppColors.textTertiary),
                        ],
                      ),
                      if (alert.action != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSM),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  size: 13, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  alert.action!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color surface;

  const _Tag({
    required this.label,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSmall
              .copyWith(color: color, fontSize: 9, letterSpacing: 0.5),
        ),
      );
}

// ── States ───────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool filtered;
  const _EmptyState({required this.filtered});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 28, color: AppColors.success),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(filtered ? 'Nothing matches that filter' : 'All clear',
              style: AppTextStyles.h3),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              filtered
                  ? 'Try a different severity or category.'
                  : 'No facilities at risk, no overdue children and nothing '
                      'waiting to sync.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 30, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text('Couldn’t load alerts', style: AppTextStyles.h4),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(message,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionMuted),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
