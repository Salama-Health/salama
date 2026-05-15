import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/dummy_data/salama_data.dart';
import '../../../data/models/child_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/brand_header.dart';
import '../scan/child_detail_sheet.dart';
import 'route_plan_sheet.dart';

// Visual hue for a priority band.
({Color bg, Color border, Color accent, Color surface}) priorityHue(
    RiskBand b) {
  return switch (b) {
    RiskBand.high => (
        bg: const Color(0xFFFFF5F4),
        border: AppColors.riskHigh.withValues(alpha: 0.35),
        accent: AppColors.riskHigh,
        surface: AppColors.riskHighLight,
      ),
    RiskBand.medium => (
        bg: const Color(0xFFFFF8F2),
        border: AppColors.riskMedium.withValues(alpha: 0.3),
        accent: AppColors.riskMedium,
        surface: AppColors.riskMediumLight,
      ),
    RiskBand.watch => (
        bg: const Color(0xFFFFFBF0),
        border: AppColors.riskWatch.withValues(alpha: 0.26),
        accent: AppColors.riskWatch,
        surface: AppColors.riskWatchLight,
      ),
    RiskBand.low => (
        bg: AppColors.cardBackground,
        border: AppColors.borderLight,
        accent: AppColors.riskLow,
        surface: AppColors.riskLowLight,
      ),
  };
}

class VisitsScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const VisitsScreen({super.key, required this.onNavigate});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  int _tab = 0; // 0 To visit · 1 Visited · 2 All
  RiskBand? _priority; // null = all priorities

  static const _priorityChips = [
    (null, 'All'),
    (RiskBand.high, 'High priority'),
    (RiskBand.medium, 'Elevated'),
    (RiskBand.watch, 'Watch'),
    (RiskBand.low, 'Routine'),
  ];

  List<ChildModel> get _filtered {
    var list = SalamaData.children.where((c) {
      if (_tab == 0) return c.status == VisitStatus.toVisit;
      if (_tab == 1) return c.status == VisitStatus.visited;
      return true;
    });
    if (_priority != null) {
      list = list.where((c) => c.riskBand == _priority);
    }
    final sorted = list.toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Column(
      children: [
        const SafeArea(
          bottom: false,
          child: BrandHeader(trailing: ConnectionPill()),
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
              _PriorityVisitsHeader(
                tab: _tab,
                onTab: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              _RouteActions(onOpen: () => showRoutePlanSheet(context)),
              const SizedBox(height: AppDimensions.spaceMD),
              Row(
                children: [
                  const Icon(Icons.filter_list_rounded,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text('Filter by priority',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _priorityChips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final chip = _priorityChips[i];
                    final selected = _priority == chip.$1;
                    return _FilterChip(
                      label: chip.$2,
                      band: chip.$1,
                      selected: selected,
                      onTap: () => setState(() => _priority = chip.$1),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${list.length} ${list.length == 1 ? "child" : "children"}',
                      style: AppTextStyles.h3,
                    ),
                  ),
                  Text('Sorted by priority',
                      style: AppTextStyles.captionMuted),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              if (list.isEmpty)
                _EmptyState()
              else
                ...list.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ChildCard(
                        child: c,
                        onTap: () => showChildDetailSheet(context, c),
                      ),
                    )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Priority visits header card ──────────────────────────────────────────
class _PriorityVisitsHeader extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTab;
  const _PriorityVisitsHeader({required this.tab, required this.onTab});

  static const _tabs = [
    ('To visit', 88),
    ('Visited', 32),
    ('All', 128),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.cardPadding, AppDimensions.cardPadding,
                AppDimensions.cardPadding, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Priority visits',
                          style: AppTextStyles.h1.copyWith(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(
                        'Children who need vaccines most before the risk '
                        'window closes.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('128',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          )),
                      Text('children',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 8.5,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Row(
            children: List.generate(_tabs.length, (i) {
              final active = tab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTab(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${_tabs[i].$1} (${_tabs[i].$2})',
                          style: AppTextStyles.caption.copyWith(
                            color: active
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        height: 2.5,
                        color: active
                            ? AppColors.primary
                            : AppColors.borderLight,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          // Risk window footer
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.cardPadding, vertical: 9),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppDimensions.radiusLG - 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_note_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('18 days left in risk window',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    )),
                const Spacer(),
                Text('Updated today, 6:30 AM',
                    style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final RiskBand? band;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.band,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        band == null ? AppColors.primary : priorityHue(band!).accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected ? accent : AppColors.borderMedium,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (band != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Child card ───────────────────────────────────────────────────────────
class _ChildCard extends StatelessWidget {
  final ChildModel child;
  final VoidCallback onTap;
  const _ChildCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hue = priorityHue(child.riskBand);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
        decoration: BoxDecoration(
          color: hue.bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(color: hue.border, width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: hue.accent.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.child_care_rounded,
                      color: hue.accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${child.name} • ${child.id}',
                          style: AppTextStyles.h4),
                      const SizedBox(height: 1),
                      Text('${child.ageLabel} • ${child.gender}',
                          style: AppTextStyles.captionMuted
                              .copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: hue.accent,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    child.priorityLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Location + last seen
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location_rounded,
                      size: 12, color: hue.accent),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      child.currentLocation,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.directions_walk_rounded,
                      size: 11, color: AppColors.textTertiary),
                  const SizedBox(width: 2),
                  Text('${child.distanceKm} km',
                      style: AppTextStyles.captionMuted.copyWith(
                        fontSize: 10,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: child.dueVaccines
                        .map((v) => _VaccineTag(label: v, color: hue.accent))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 6),
                Text('CDI ${child.riskScore.toStringAsFixed(2)}',
                    style: AppTextStyles.caption.copyWith(
                      color: hue.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    )),
                const Icon(Icons.chevron_right_rounded,
                    size: 17, color: AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VaccineTag extends StatelessWidget {
  final String label;
  final Color color;
  const _VaccineTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              size: 32, color: AppColors.textTertiary.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text('No children match this filter',
              style: AppTextStyles.h4
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text('Try a different priority or tab',
              style: AppTextStyles.captionMuted),
        ],
      ),
    );
  }
}

// ── Route actions ────────────────────────────────────────────────────────
class _RouteActions extends StatelessWidget {
  final VoidCallback onOpen;
  const _RouteActions({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onOpen,
      color: AppColors.primarySurface.withValues(alpha: 0.5),
      borderColor: AppColors.primary.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _ActionLink(
                icon: Icons.map_outlined,
                label: 'View on map',
                onTap: onOpen),
          ),
          Container(
            width: 1,
            height: 20,
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
          Expanded(
            child: _ActionLink(
                icon: Icons.route_rounded,
                label: 'Plan route',
                onTap: onOpen),
          ),
        ],
      ),
    );
  }
}

class _ActionLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}
