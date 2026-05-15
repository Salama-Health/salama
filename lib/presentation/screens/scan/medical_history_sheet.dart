import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/vaccination_record.dart';

void showMedicalHistorySheet(BuildContext context, ChildModel child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _MedicalHistorySheet(child: child),
  );
}

({Color color, Color surface, String label}) _doseStyle(DoseStatus s) {
  return switch (s) {
    DoseStatus.given => (
        color: AppColors.success,
        surface: AppColors.successLight,
        label: 'Given',
      ),
    DoseStatus.due => (
        color: AppColors.warning,
        surface: AppColors.warningLight,
        label: 'Due',
      ),
    DoseStatus.missed => (
        color: AppColors.error,
        surface: AppColors.errorLight,
        label: 'Missed',
      ),
  };
}

class _MedicalHistorySheet extends StatefulWidget {
  final ChildModel child;
  const _MedicalHistorySheet({required this.child});

  @override
  State<_MedicalHistorySheet> createState() => _MedicalHistorySheetState();
}

class _MedicalHistorySheetState extends State<_MedicalHistorySheet> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Icon(
                        _scanned
                            ? Icons.history_rounded
                            : Icons.qr_code_scanner_rounded,
                        color: AppColors.primary,
                        size: 16),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            _scanned
                                ? 'Medical history'
                                : 'Scan child QR code',
                            style: AppTextStyles.h3),
                        Text(
                            _scanned
                                ? '${widget.child.name} • ${widget.child.id}'
                                : 'Verify identity to view records',
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
              child: _scanned
                  ? _HistoryView(child: widget.child)
                  : _ScanView(onScanned: () => setState(() => _scanned = true)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan stage ───────────────────────────────────────────────────────────
class _ScanView extends StatelessWidget {
  final VoidCallback onScanned;
  const _ScanView({required this.onScanned});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          // Scanner frame
          Container(
            width: 188,
            height: 188,
            decoration: BoxDecoration(
              color: AppColors.primaryDeep,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.qr_code_2_rounded,
                    size: 80, color: Colors.white24),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: CustomPaint(painter: _ScanBracketPainter()),
                  ),
                ),
                Positioned(
                  bottom: 22,
                  child: Container(
                    width: 150,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Point the camera at the QR code',
              style: AppTextStyles.h4),
          const SizedBox(height: 2),
          Text(
            'The code on the child’s immunization card unlocks their '
            'full vaccination history.',
            textAlign: TextAlign.center,
            style: AppTextStyles.captionMuted,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onScanned,
            child: Container(
              width: double.infinity,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded,
                      size: 17, color: Colors.white),
                  const SizedBox(width: 7),
                  Text('Scan code',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onScanned,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Enter code manually',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanBracketPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 26.0;
    c.drawLine(const Offset(0, len), const Offset(0, 0), p);
    c.drawLine(const Offset(0, 0), const Offset(len, 0), p);
    c.drawLine(Offset(s.width - len, 0), Offset(s.width, 0), p);
    c.drawLine(Offset(s.width, 0), Offset(s.width, len), p);
    c.drawLine(Offset(0, s.height - len), Offset(0, s.height), p);
    c.drawLine(Offset(0, s.height), Offset(len, s.height), p);
    c.drawLine(Offset(s.width - len, s.height), Offset(s.width, s.height), p);
    c.drawLine(Offset(s.width, s.height - len), Offset(s.width, s.height), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── History stage ────────────────────────────────────────────────────────
class _HistoryView extends StatelessWidget {
  final ChildModel child;
  const _HistoryView({required this.child});

  @override
  Widget build(BuildContext context) {
    final history = child.history;
    final given = history.where((r) => r.status == DoseStatus.given).length;
    final due = history.where((r) => r.status == DoseStatus.due).length;
    final missed =
        history.where((r) => r.status == DoseStatus.missed).length;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      shrinkWrap: true,
      children: [
        // Verified banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded,
                  size: 15, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Identity verified — record C:${child.id}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Summary
        Row(
          children: [
            Expanded(
                child: _SummaryTile(
                    value: '$given',
                    label: 'Given',
                    color: AppColors.success)),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryTile(
                    value: '$due',
                    label: 'Due',
                    color: AppColors.warning)),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryTile(
                    value: '$missed',
                    label: 'Missed',
                    color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 12),
        Text('Vaccination timeline', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 30,
                    color: AppColors.textTertiary.withValues(alpha: 0.6)),
                const SizedBox(height: 6),
                Text('No vaccinations recorded yet',
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('This child has not been vaccinated',
                    style: AppTextStyles.captionMuted),
              ],
            ),
          )
        else
          ...List.generate(history.length, (i) {
            return _HistoryRow(
              record: history[i],
              isLast: i == history.length - 1,
            );
          }),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SummaryTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.statNumberSmall
                  .copyWith(fontSize: 19, color: color)),
          Text(label, style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final VaccinationRecord record;
  final bool isLast;
  const _HistoryRow({required this.record, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final style = _doseStyle(record.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: style.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: style.color, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMD),
                  border:
                      Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              '${record.vaccine} • ${record.dose}',
                              style: AppTextStyles.h4),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: style.surface,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull),
                          ),
                          child: Text(style.label,
                              style: AppTextStyles.caption.copyWith(
                                color: style.color,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.event_rounded,
                            size: 11, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(record.date,
                            style: AppTextStyles.captionMuted
                                .copyWith(fontSize: 10.5)),
                        if (record.batch != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.inventory_2_outlined,
                              size: 11, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text('Batch ${record.batch}',
                              style: AppTextStyles.captionMuted
                                  .copyWith(fontSize: 10.5)),
                        ],
                      ],
                    ),
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

// ── Shared ───────────────────────────────────────────────────────────────
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
