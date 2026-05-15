import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/dummy_data/salama_data.dart';
import '../../../data/models/child_model.dart';

void showScanQrSheet(BuildContext context, {ChildModel? child}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _ScanQrSheet(child: child ?? SalamaData.children.first),
  );
}

class _ScanQrSheet extends StatelessWidget {
  final ChildModel child;
  const _ScanQrSheet({required this.child});

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
            // Grabber
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 2),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            // Header
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
                        Text('Child QR Code', style: AppTextStyles.h3),
                        Text('Scan to access immunization record',
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
                  _IdentityQrCard(child: child),
                  const SizedBox(height: AppDimensions.spaceSM),
                  Row(
                    children: const [
                      Expanded(
                          child: _MiniAction(
                              icon: Icons.file_download_outlined,
                              label: 'Save')),
                      SizedBox(width: 6),
                      Expanded(
                          child: _MiniAction(
                              icon: Icons.share_outlined, label: 'Share')),
                      SizedBox(width: 6),
                      Expanded(
                          child: _MiniAction(
                              icon: Icons.print_outlined, label: 'Print')),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceSM),
                  const _QuickAction(
                    icon: Icons.vaccines_outlined,
                    iconColor: AppColors.warningMid,
                    title: 'View vaccination record',
                    subtitle: 'See all vaccines and doses',
                  ),
                  const SizedBox(height: 6),
                  const _QuickAction(
                    icon: Icons.add_moderator_outlined,
                    iconColor: AppColors.info,
                    title: 'Record new vaccination',
                    subtitle: 'Add a new vaccine dose',
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

// ── Identity + QR card ───────────────────────────────────────────────────
class _IdentityQrCard extends StatelessWidget {
  final ChildModel child;
  const _IdentityQrCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Column(
        children: [
          // Identity
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
                  child: const Icon(Icons.child_care_rounded,
                      color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name, style: AppTextStyles.h3),
                      Text(
                        '${child.gender} • ${child.ageLabel} • Born ${child.bornDate}',
                        style: AppTextStyles.captionMuted,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Record ID', style: AppTextStyles.captionMuted),
                    Text(
                      child.id,
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
          // QR
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            child: Column(
              children: [
                Text(
                  'Show this QR to any health worker to view history.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionMuted,
                ),
                const SizedBox(height: 10),
                _QrWithBrackets(data: 'SALAMA:${child.id}'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface.withValues(alpha: 0.6),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Contains a secure identifier only. '
                          'Personal data is protected.',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _QuickAction({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                Text(subtitle, style: AppTextStyles.captionMuted),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
