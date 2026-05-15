import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/brand_header.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reports',
                            style: AppTextStyles.h1.copyWith(fontSize: 19)),
                        Text('Immunization coverage & performance',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  _PeriodChip(),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.vaccines_outlined,
                      iconColor: AppColors.info,
                      value: '96',
                      label: 'Doses this month',
                      delta: '+12%',
                      up: true,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spaceSM),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.primary,
                      value: '85%',
                      label: 'Coverage rate',
                      delta: '+8pp',
                      up: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.groups_outlined,
                      iconColor: AppColors.success,
                      value: '128',
                      label: 'Children reached',
                      delta: '+18',
                      up: true,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spaceSM),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_down_rounded,
                      iconColor: AppColors.warning,
                      value: '6%',
                      label: 'Drop-out rate',
                      delta: '-2pp',
                      up: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceSM),
              const _DosesChartCard(),
              const SizedBox(height: AppDimensions.spaceSM),
              const _CoverageCard(),
              const SizedBox(height: AppDimensions.spaceMD),
              AppButton(
                label: 'Export monthly report',
                icon: Icons.file_download_outlined,
                height: 44,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 12, color: AppColors.primary),
          const SizedBox(width: 5),
          Text('This month',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              )),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String delta;
  final bool up;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.delta,
    required this.up,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const Spacer(),
              Icon(
                up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 10,
                color: up ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 1),
              Text(delta,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 9.5,
                    color: up ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.statNumberSmall.copyWith(fontSize: 20)),
          Text(label, style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _DosesChartCard extends StatelessWidget {
  const _DosesChartCard();

  static const _values = [12, 18, 9, 22, 16, 14, 5];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Doses administered', style: AppTextStyles.h3),
          Text('Last 7 days', style: AppTextStyles.captionMuted),
          const SizedBox(height: AppDimensions.spaceMD),
          SizedBox(
            height: 128,
            child: BarChart(
              BarChartData(
                maxY: 26,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 13,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.borderLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 13,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 8.5,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= _days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            _days[i],
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 8.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(enabled: false),
                barGroups: List.generate(_values.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _values[i].toDouble(),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        color: i == 3
                            ? AppColors.primary
                            : AppColors.primaryLighter,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard();

  static const _rows = [
    ('BCG', 0.92),
    ('OPV', 0.86),
    ('Penta', 0.78),
    ('Measles', 0.71),
    ('Rota', 0.64),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coverage by vaccine', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.spaceSM),
          ..._rows.map((r) {
            final pct = r.$2;
            final color = pct >= 0.85
                ? AppColors.success
                : pct >= 0.72
                    ? AppColors.warningMid
                    : AppColors.riskMedium;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(r.$1,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 32,
                    child: Text('${(pct * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
