import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/report_models.dart';
import '../../../data/models/worker_model.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_sheet.dart';

void showExportReportSheet(
  BuildContext context, {
  required ReportsBundle bundle,
  WorkerModel? worker,
}) {
  showAppSheet(
    context,
    _ExportReportSheet(bundle: bundle, worker: worker),
  );
}

/// Turns the monthly figures into text a worker can actually send.
///
/// Reporting up the chain in Unity State happens over WhatsApp and SMS far more
/// often than over email, so the export copies to the clipboard in two shapes:
/// a readable summary to paste into a message, and CSV for a spreadsheet.
class _ExportReportSheet extends StatefulWidget {
  final ReportsBundle bundle;
  final WorkerModel? worker;

  const _ExportReportSheet({required this.bundle, this.worker});

  @override
  State<_ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends State<_ExportReportSheet> {
  bool _csv = false;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String get _period {
    final now = DateTime.now();
    return '${_months[now.month - 1]} ${now.year}';
  }

  String get _text {
    final s = widget.bundle.summary;
    final w = widget.worker;
    final b = StringBuffer()
      ..writeln('SALAMA HEALTH — MONTHLY IMMUNIZATION REPORT')
      ..writeln(_period)
      ..writeln('');
    if (w != null) {
      b
        ..writeln('Worker:   ${w.name} (${w.workerId})')
        ..writeln('Facility: ${w.facility}')
        ..writeln('County:   ${w.county}')
        ..writeln('');
    }
    b
      ..writeln('SUMMARY')
      ..writeln('Doses given this month : ${s.dosesThisMonth}')
      ..writeln('Children reached       : ${s.childrenReached}')
      ..writeln('Coverage rate          : ${(s.coverageRate * 100).round()}%')
      ..writeln('Drop-out rate          : ${(s.dropoutRate * 100).round()}%')
      ..writeln('');

    if (widget.bundle.coverage.isNotEmpty) {
      b.writeln('COVERAGE BY VACCINE');
      for (final v in widget.bundle.coverage) {
        final pct = (v.coverage * 100).round();
        b.writeln('${v.name.padRight(16)} ${pct.toString().padLeft(3)}%');
      }
      b.writeln('');
    }

    if (widget.bundle.weeklyDoses.isNotEmpty) {
      b.writeln('DOSES BY DAY (LAST 7)');
      for (final d in widget.bundle.weeklyDoses) {
        b.writeln('${d.label.padRight(6)} ${d.count}');
      }
      b.writeln('');
    }

    b.writeln('Generated ${_stamp()} from Salama Health.');
    return b.toString();
  }

  String get _csvText {
    final s = widget.bundle.summary;
    final w = widget.worker;
    final b = StringBuffer()..writeln('section,label,value');
    if (w != null) {
      b
        ..writeln('meta,worker,"${w.name}"')
        ..writeln('meta,worker_id,${w.workerId}')
        ..writeln('meta,facility,"${w.facility}"')
        ..writeln('meta,county,"${w.county}"');
    }
    b
      ..writeln('meta,period,"$_period"')
      ..writeln('summary,doses_this_month,${s.dosesThisMonth}')
      ..writeln('summary,children_reached,${s.childrenReached}')
      ..writeln('summary,coverage_rate,${s.coverageRate.toStringAsFixed(3)}')
      ..writeln('summary,dropout_rate,${s.dropoutRate.toStringAsFixed(3)}');
    for (final v in widget.bundle.coverage) {
      b.writeln('coverage,"${v.name}",${v.coverage.toStringAsFixed(3)}');
    }
    for (final d in widget.bundle.weeklyDoses) {
      b.writeln('daily_doses,"${d.label}",${d.count}');
    }
    return b.toString();
  }

  String _stamp() {
    final n = DateTime.now();
    final hh = n.hour.toString().padLeft(2, '0');
    final mm = n.minute.toString().padLeft(2, '0');
    return '${n.day}/${n.month}/${n.year} $hh:$mm';
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _csv ? _csvText : _text));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_csv
            ? 'CSV copied — paste it into a spreadsheet.'
            : 'Report copied — paste it into a message or email.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _csv ? _csvText : _text;

    return AppSheet(
      icon: Icons.file_download_outlined,
      title: 'Export report',
      subtitle: _period,
      maxHeightFactor: 0.85,
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Close',
              variant: AppButtonVariant.outline,
              height: 44,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceSM),
          Expanded(
            flex: 2,
            child: AppButton(
              label: _csv ? 'Copy CSV' : 'Copy report',
              icon: Icons.copy_rounded,
              height: 44,
              onPressed: _copy,
            ),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        children: [
          Row(
            children: [
              Expanded(
                child: _FormatTab(
                  label: 'Readable',
                  hint: 'For WhatsApp or email',
                  selected: !_csv,
                  onTap: () => setState(() => _csv = false),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSM),
              Expanded(
                child: _FormatTab(
                  label: 'CSV',
                  hint: 'For a spreadsheet',
                  selected: _csv,
                  onTap: () => setState(() => _csv = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          const SheetSectionLabel('Preview'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                  color: AppColors.borderLight,
                  width: AppDimensions.borderNormal),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                body,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          Container(
            padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Signed PDF export lands with the supervisor dashboard. '
                    'Until then this copies the same figures as text.',
                    style: AppTextStyles.bodySmall,
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

class _FormatTab extends StatelessWidget {
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _FormatTab({
    required this.label,
    required this.hint,
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 11),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primarySurface : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected
                ? AppDimensions.borderMedium
                : AppDimensions.borderNormal,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.h4.copyWith(
                  color:
                      selected ? AppColors.primary : AppColors.textPrimary,
                )),
            Text(hint, style: AppTextStyles.captionMuted),
          ],
        ),
      ),
    );
  }
}
