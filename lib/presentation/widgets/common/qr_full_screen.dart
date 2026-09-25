import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// A QR code filling the screen, for scanning off this phone or photographing
/// to print.
///
/// The card is plain white with wide quiet margins because that is what a
/// scanner needs — and what survives being printed on a shared office printer
/// and taped into a paper immunization card.
class QrFullScreen extends StatelessWidget {
  final String payload;
  final String code;
  final String title;
  final String? subtitle;

  const QrFullScreen({
    super.key,
    required this.payload,
    required this.code,
    required this.title,
    this.subtitle,
  });

  static Future<void> open(
    BuildContext context, {
    required String payload,
    required String code,
    required String title,
    String? subtitle,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => QrFullScreen(
          payload: payload,
          code: code,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final qrSize = (width - 88).clamp(180.0, 340.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceSM, 6, AppDimensions.spaceSM, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    tooltip: 'Close',
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Code $code copied'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy code'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXXL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h1.copyWith(fontSize: 18)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall),
                      ],
                      const SizedBox(height: AppDimensions.spaceXL),
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spaceXL),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusLG),
                          border: Border.all(
                              color: AppColors.borderLight, width: 1),
                        ),
                        child: QrImageView(
                          data: payload,
                          version: QrVersions.auto,
                          size: qrSize,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primaryDeep,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceLG),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(
                          code,
                          style: AppTextStyles.h2.copyWith(
                            letterSpacing: 1.6,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      Text(
                        'Hold steady under good light to scan.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.captionMuted,
                      ),
                      const SizedBox(height: AppDimensions.spaceXL),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two small actions under a QR card: copy the code, or open it full screen.
class QrActionsRow extends StatelessWidget {
  final String payload;
  final String code;
  final String title;
  final String? subtitle;

  const QrActionsRow({
    super.key,
    required this.payload,
    required this.code,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Action(
            icon: Icons.copy_rounded,
            label: 'Copy code',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Code $code copied'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Action(
            icon: Icons.fullscreen_rounded,
            label: 'Full screen',
            onTap: () => QrFullScreen.open(
              context,
              payload: payload,
              code: code,
              title: title,
              subtitle: subtitle,
            ),
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
              color: AppColors.borderLight, width: AppDimensions.borderNormal),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
