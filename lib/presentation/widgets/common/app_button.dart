import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool iconTrailing;
  final bool isLoading;
  final bool small;
  final double? height;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.iconTrailing = false,
    this.isLoading = false,
    this.small = false,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ??
        (small ? AppDimensions.buttonHeightSM : AppDimensions.buttonHeightLG);
    final fs = small ? 13.0 : 14.5;

    final Color bg;
    final Color fg;
    final Color? borderColor;

    switch (variant) {
      case AppButtonVariant.secondary:
        bg = AppColors.primarySurface;
        fg = AppColors.primary;
        borderColor = null;
      case AppButtonVariant.outline:
        bg = AppColors.cardBackground;
        fg = AppColors.primary;
        borderColor = AppColors.primary.withValues(alpha: 0.4);
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primary;
        borderColor = null;
      case AppButtonVariant.danger:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        borderColor = null;
      case AppButtonVariant.primary:
        bg = AppColors.primary;
        fg = AppColors.textOnPrimary;
        borderColor = null;
    }

    final content = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null && !iconTrailing) ...[
                Icon(icon, size: small ? 16 : 18, color: fg),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: fs,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              if (icon != null && iconTrailing) ...[
                const SizedBox(width: 7),
                Icon(icon, size: small ? 16 : 18, color: fg),
              ],
            ],
          );

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: h,
        width: width ?? double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: borderColor != null
              ? Border.all(color: borderColor, width: AppDimensions.borderNormal)
              : null,
        ),
        child: content,
      ),
    );
  }
}
