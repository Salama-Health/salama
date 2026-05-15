import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/dummy_data/salama_data.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/facility_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/brand_header.dart';
import 'facility_sheets.dart';
import 'sync_modal.dart';

class HomeBody extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const HomeBody({super.key, required this.onNavigate});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  @override
  Widget build(BuildContext context) {
    final w = SalamaData.worker;
    final firstName = w.name.split(' ').first;

    // Top 4 facilities by climate-disruption score.
    final topFacilities = [...SalamaData.facilities]
      ..sort((a, b) => b.cdiScore.compareTo(a.cdiScore));
    final shown = topFacilities.take(4).toList();
    final atRisk = SalamaData.assignedFacilities
        .where((f) => f.risk == FacilityRisk.danger)
        .length;

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
                _NotificationBell(count: 2),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              AppDimensions.spaceMD,
              AppDimensions.screenPadding,
              AppDimensions.spaceXXL,
            ),
            children: [
              // ── Greeting + worker summary ──────────────────────
              Text('Hello, $firstName 👋',
                  style: AppTextStyles.h1.copyWith(fontSize: 19)),
              const SizedBox(height: 1),
              Text('${w.role} · ${w.county}',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: AppDimensions.spaceMD),
              _WorkerSummaryCard(
                county: w.county,
                facilities: w.facilitiesCount,
                children: 128,
                atRisk: atRisk,
              ),
              const SizedBox(height: AppDimensions.spaceSM),

              // ── Priority visit list ────────────────────────────
              _PriorityVisitCard(onTap: () => widget.onNavigate(1)),
              const SizedBox(height: AppDimensions.spaceMD),

              // ── Facility risk section ──────────────────────────
              _SectionHeader(
                title: 'Facility risk',
                action: 'View all',
                onAction: () => showAllFacilitiesSheet(context),
              ),
              const SizedBox(height: 6),
              ...shown.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: FacilityCard(
                      facility: f,
                      onTap: () => showFacilityDetailSheet(context, f),
                    ),
                  )),
              const SizedBox(height: AppDimensions.spaceSM),

              // ── Sync data card ─────────────────────────────────
              ValueListenableBuilder<bool>(
                valueListenable: ConnectivityService.instance.isOnline,
                builder: (_, online, _) => _SyncCard(
                  isOnline: online,
                  onSync: () => showSyncModal(context),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),

              // ── Recent activity ────────────────────────────────
              _SectionHeader(
                title: 'Recent activity',
                action: 'View all',
                onAction: () {},
              ),
              const SizedBox(height: 6),
              _RecentActivityCard(items: SalamaData.recentActivity),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Notification bell ────────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  final int count;
  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.notifications_none_rounded,
                size: 22, color: AppColors.primary),
          ),
          Positioned(
            top: 1,
            right: 1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text('$count',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────
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

// ── Worker summary card ──────────────────────────────────────────────────
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

// ── Priority visit card ──────────────────────────────────────────────────
class _PriorityVisitCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PriorityVisitCard({required this.onTap});

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
                      Text('128',
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
              children: const [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.outlined_flag_rounded,
                    iconColor: AppColors.riskHigh,
                    value: '25',
                    label: 'High priority',
                  ),
                ),
                _StatDivider(),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.warningMid,
                    value: '63',
                    label: 'Due soon',
                  ),
                ),
                _StatDivider(),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.success,
                    value: '40',
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

// ── Sync data card ───────────────────────────────────────────────────────
class _SyncCard extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onSync;
  const _SyncCard({required this.isOnline, required this.onSync});

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
                  value: '${SalamaData.pendingRecords}',
                  label: 'Records awaiting sync',
                  highlight: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SyncStat(
                  value: SalamaData.lastSync,
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

// ── Recent activity ──────────────────────────────────────────────────────
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
