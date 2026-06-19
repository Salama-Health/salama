import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/facility_model.dart';

IconData hazardIcon(String hazard) {
  final h = hazard.toLowerCase();
  if (h.contains('flood')) return Icons.water_rounded;
  if (h.contains('rain')) return Icons.cloudy_snowing;
  if (h.contains('heat')) return Icons.wb_sunny_rounded;
  if (h.contains('drought')) return Icons.local_fire_department_outlined;
  return Icons.check_circle_outline_rounded;
}

// ── All facilities bottom sheet ──────────────────────────────────────────
void showAllFacilitiesSheet(
    BuildContext context, List<FacilityModel> facilities) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _AllFacilitiesSheet(facilities: facilities),
  );
}

class _AllFacilitiesSheet extends StatelessWidget {
  final List<FacilityModel> facilities;
  const _AllFacilitiesSheet({required this.facilities});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final all = facilities;
    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.88),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Grabber(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMD, 6, AppDimensions.spaceSM, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: const Icon(Icons.local_hospital_outlined,
                        color: AppColors.primary, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All facilities', style: AppTextStyles.h3),
                        Text('${all.length} facilities in your region',
                            style: AppTextStyles.captionMuted),
                      ],
                    ),
                  ),
                  _CloseButton(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: AppColors.borderLight),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                shrinkWrap: true,
                itemCount: all.length,
                itemBuilder: (_, i) => FacilityCard(
                  facility: all[i],
                  onTap: () {
                    Navigator.pop(context);
                    showFacilityDetailSheet(context, all[i]);
                  },
                ),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Facility detail sheet (climate hazard) ───────────────────────────────
void showFacilityDetailSheet(BuildContext context, FacilityModel f) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _FacilityDetailSheet(facility: f),
  );
}

class _FacilityDetailSheet extends StatelessWidget {
  final FacilityModel facility;
  const _FacilityDetailSheet({required this.facility});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final risk = facility.risk;
    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.9),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Grabber(),
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMD, 6, AppDimensions.spaceSM, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: risk.color.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Icon(Icons.local_hospital_outlined,
                        color: risk.color, size: 16),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(facility.name,
                                  style: AppTextStyles.h3),
                            ),
                            if (facility.assigned) ...[
                              const SizedBox(width: 6),
                              const _AssignedTag(),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.place_outlined,
                                size: 11, color: AppColors.textTertiary),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(facility.county,
                                  style: AppTextStyles.captionMuted,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _CloseButton(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: AppColors.borderLight),
            // ── Body ────────────────────────────────────────────
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                shrinkWrap: true,
                children: [
                  _HazardCard(facility: facility),
                  const SizedBox(height: 8),
                  _StatsRow(facility: facility),
                  const SizedBox(height: 8),
                  _ExpectCard(facility: facility),
                  const SizedBox(height: 8),
                  _BreakdownCard(facility: facility),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hazard hero card ─────────────────────────────────────────────────────
class _HazardCard extends StatelessWidget {
  final FacilityModel facility;
  const _HazardCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    final risk = facility.risk;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: risk.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
            color: risk.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag('CLIMATE HAZARD',
                  color: risk.color,
                  bg: AppColors.cardBackground.withValues(alpha: 0.7)),
              const Spacer(),
              _Tag(risk.label.toUpperCase(),
                  color: Colors.white, bg: risk.color, bordered: false),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: risk.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(hazardIcon(facility.hazard),
                    color: risk.color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(facility.hazard,
                        style: AppTextStyles.h2.copyWith(color: risk.color)),
                    const SizedBox(height: 1),
                    Text(
                      facility.daysToWindow > 0
                          ? 'Risk window opens in ${facility.daysToWindow} days'
                          : 'No disruption in the forecast window',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final FacilityModel facility;
  const _StatsRow({required this.facility});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: facility.cdiScore.toStringAsFixed(2),
            label: 'CDI Score',
            color: facility.risk.color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            value: facility.daysToWindow > 0
                ? '${facility.daysToWindow}'
                : '—',
            label: 'Days to risk',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            value: '${facility.children}',
            label: 'Children',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.statNumberSmall
                  .copyWith(fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.captionMuted.copyWith(fontSize: 9.5)),
        ],
      ),
    );
  }
}

// ── What to expect card ──────────────────────────────────────────────────
class _ExpectCard extends StatelessWidget {
  final FacilityModel facility;
  const _ExpectCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Tag('WHAT TO EXPECT'),
          const SizedBox(height: 8),
          Text(facility.hazardDetail, style: AppTextStyles.bodySmall),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_bottom_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 7),
                Text('Duration',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    )),
                const Spacer(),
                Flexible(
                  child: Text(
                    facility.hazardTimeframe,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
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

// ── Children breakdown card ──────────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  final FacilityModel facility;
  const _BreakdownCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    final total = facility.children;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag('CHILDREN BREAKDOWN'),
              const Spacer(),
              Text('$total total',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          _BreakdownRow(
            color: AppColors.riskHigh,
            label: 'High priority',
            count: facility.highPriority,
            total: total,
          ),
          const SizedBox(height: 8),
          _BreakdownRow(
            color: AppColors.warningMid,
            label: 'Due soon',
            count: facility.dueSoon,
            total: total,
          ),
          const SizedBox(height: 8),
          _BreakdownRow(
            color: AppColors.success,
            label: 'Recently visited',
            count: facility.recentlyVisited,
            total: total,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _BreakdownRow({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            Text('$count',
                style: AppTextStyles.h4.copyWith(color: color)),
            Text('  ·  ${(pct * 100).round()}%',
                style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── Reusable facility card ───────────────────────────────────────────────
class FacilityCard extends StatelessWidget {
  final FacilityModel facility;
  final VoidCallback onTap;
  const FacilityCard({
    super.key,
    required this.facility,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final risk = facility.risk;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
              color: facility.assigned
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.borderLight,
              width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: risk.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Icon(hazardIcon(facility.hazard),
                  color: risk.color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(facility.name, style: AppTextStyles.h4),
                      ),
                      if (facility.assigned) ...[
                        const SizedBox(width: 5),
                        const _AssignedTag(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    facility.daysToWindow > 0
                        ? '${facility.hazard} • ${facility.daysToWindow}d to window'
                        : '${facility.hazard} • ${facility.county}',
                    style: AppTextStyles.captionMuted.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: risk.surface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    risk.label,
                    style: AppTextStyles.caption.copyWith(
                      color: risk.color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text('CDI ${facility.cdiScore.toStringAsFixed(2)}',
                    style: AppTextStyles.caption.copyWith(
                      color: risk.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 17, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Small caps tag ───────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  final bool bordered;
  const _Tag(
    this.text, {
    this.color = AppColors.primary,
    this.bg = AppColors.primarySurface,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: bordered
            ? Border.all(color: color.withValues(alpha: 0.25), width: 0.75)
            : null,
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _AssignedTag extends StatelessWidget {
  const _AssignedTag();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3), width: 0.75),
      ),
      child: Text(
        'Assigned',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Shared sheet chrome ──────────────────────────────────────────────────
class _Grabber extends StatelessWidget {
  const _Grabber();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 2),
      width: 36,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.borderMedium,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderMedium, width: 1),
        ),
        child: const Icon(Icons.close_rounded,
            size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
