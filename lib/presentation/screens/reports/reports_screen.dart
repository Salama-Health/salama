import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/report_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/brand_header.dart';
import '../../widgets/common/offline_banner.dart';
import 'export_report_sheet.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return Column(
      children: [
        const SafeArea(
          bottom: false,
          child: BrandHeader(trailing: ConnectionPill()),
        ),
        const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reportsProvider);
              await ref.read(reportsProvider.future);
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
                reportsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => _ErrorState(
                    message: '$e',
                    onRetry: () => ref.invalidate(reportsProvider),
                  ),
                  data: (bundle) => _ReportsBody(bundle: bundle),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportsBody extends StatelessWidget {
  final ReportsBundle bundle;
  const _ReportsBody({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final s = bundle.summary;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.vaccines_outlined,
                iconColor: AppColors.info,
                value: '${s.dosesThisMonth}',
                label: 'Doses this month',
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSM),
            Expanded(
              child: _StatCard(
                icon: Icons.shield_outlined,
                iconColor: AppColors.primary,
                value: '${(s.coverageRate * 100).round()}%',
                label: 'Coverage rate',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceSM),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.groups_outlined,
                iconColor: AppColors.success,
                value: '${s.childrenReached}',
                label: 'Children reached',
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSM),
            Expanded(
              child: _StatCard(
                icon: Icons.trending_down_rounded,
                iconColor: AppColors.warning,
                value: '${(s.dropoutRate * 100).round()}%',
                label: 'Drop-out rate',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceSM),
        _DosesChartCard(days: bundle.weeklyDoses),
        const SizedBox(height: AppDimensions.spaceSM),
        _CoverageCard(rows: bundle.coverage),
        const SizedBox(height: AppDimensions.spaceMD),
        Consumer(
          builder: (context, ref, _) => AppButton(
            label: 'Export monthly report',
            icon: Icons.file_download_outlined,
            height: 44,
            onPressed: () => showExportReportSheet(
              context,
              bundle: bundle,
              worker: ref.read(currentWorkerProvider),
            ),
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

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
  final List<DayCount> days;
  const _DosesChartCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final values = days.map((d) => d.count).toList();
    final labels = days.map((d) => d.label).toList();
    final maxVal = values.isEmpty
        ? 10
        : values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal <= 0 ? 10 : (maxVal * 1.2)).toDouble();
    final interval = (maxY / 2).clamp(1, double.infinity);
    final peakIndex = values.isEmpty
        ? -1
        : values.indexOf(maxVal);

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
            child: values.isEmpty
                ? Center(
                    child: Text('No data yet',
                        style: AppTextStyles.captionMuted),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: interval.toDouble(),
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
                            interval: interval.toDouble(),
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
                              if (i < 0 || i >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  labels[i],
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
                      barGroups: List.generate(values.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: values[i].toDouble(),
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                              color: i == peakIndex
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
  final List<VaccineCoverage> rows;
  const _CoverageCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coverage by vaccine', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.spaceSM),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No coverage data yet',
                  style: AppTextStyles.captionMuted),
            )
          else
            ...rows.map((r) {
              final pct = r.coverage;
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
                      child: Text(r.name,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 30, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text('Couldn’t load reports',
              style:
                  AppTextStyles.h4.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionMuted),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
