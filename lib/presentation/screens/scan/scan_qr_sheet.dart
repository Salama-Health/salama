import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/worker_model.dart';
import '../../widgets/common/qr_full_screen.dart';

void showScanQrSheet(BuildContext context, WorkerModel? worker) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _ScanQrSheet(worker: worker),
  );
}

class _ScanQrSheet extends StatelessWidget {
  final WorkerModel? worker;
  const _ScanQrSheet({required this.worker});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
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
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 2),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
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
                    child: const Icon(Icons.qr_code_2_rounded,
                        color: AppColors.primary, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My QR Code', style: AppTextStyles.h3),
                        Text('Show this to identify yourself',
                            style: AppTextStyles.captionMuted),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.borderMedium, width: 1),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: AppColors.borderLight),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                shrinkWrap: true,
                children: [
                  _IdentityQrCard(worker: worker),
                  const SizedBox(height: AppDimensions.spaceSM),
                  QrActionsRow(
                    payload: 'SALAMA-CHW:${worker?.workerId ?? ""}',
                    code: worker?.workerId ?? '—',
                    title: worker?.name ?? 'Health worker',
                    subtitle:
                        '${worker?.role ?? ""} · ${worker?.facility ?? ""}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Identity + QR card ───────────────────────────────────────────────────────
class _IdentityQrCard extends StatelessWidget {
  final WorkerModel? worker;
  const _IdentityQrCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final name = worker?.name ?? '—';
    final role = worker?.role ?? '';
    final id = worker?.workerId ?? '—';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
            decoration: BoxDecoration(
              color: AppColors.primarySurface.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusMD - 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.h3),
                      Text(role, style: AppTextStyles.captionMuted),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Worker ID', style: AppTextStyles.captionMuted),
                    Text(
                      id,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(
              height: 1, thickness: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            child: Column(
              children: [
                Text(
                  'Show this QR to identify yourself at a facility.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionMuted,
                ),
                const SizedBox(height: 10),
                _QrWithBrackets(data: 'SALAMA-CHW:$id'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrWithBrackets extends StatelessWidget {
  final String data;
  const _QrWithBrackets({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      height: 178,
      child: Stack(
        children: [
          Center(
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 142,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.textPrimary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _BracketPainter())),
        ],
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 22.0;
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

