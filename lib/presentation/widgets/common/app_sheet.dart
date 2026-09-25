import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Drag handle at the top of a bottom sheet.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8, bottom: 6),
        width: 36,
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.borderMedium,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      );
}

/// Small circular dismiss button used in sheet headers.
class SheetCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const SheetCloseButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(right: 4),
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded,
              size: 16, color: AppColors.textSecondary),
        ),
      );
}

/// Standard bottom-sheet shell: grabber, icon + title header, divider, body.
class AppSheet extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final double maxHeightFactor;

  const AppSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.iconColor,
    this.footer,
    this.maxHeightFactor = 0.92,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final tint = iconColor ?? AppColors.primary;

    return Container(
      constraints:
          BoxConstraints(maxHeight: mq.size.height * maxHeightFactor),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetGrabber(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMD, 6, AppDimensions.spaceSM, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Icon(icon, color: tint, size: 16),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppTextStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: AppTextStyles.captionMuted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  SheetCloseButton(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: AppColors.borderLight),
            Flexible(child: child),
            if (footer != null) ...[
              const Divider(
                  height: 1, thickness: 1, color: AppColors.borderLight),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceMD, 10, AppDimensions.spaceMD, 10),
                child: footer!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Convenience opener matching the app's sheet styling.
Future<T?> showAppSheet<T>(BuildContext context, Widget sheet) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => sheet,
  );
}

/// Section label with an optional trailing action, matching the home screen.
class SheetSectionLabel extends StatelessWidget {
  final String text;
  const SheetSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
            letterSpacing: 0.7,
          ),
        ),
      );
}
