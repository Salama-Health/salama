import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Top header showing the Salama logo, app name and facility location.
/// Used across Home, Visits, Scan QR and Profile.
class BrandHeader extends StatelessWidget {
  final Widget? trailing;
  final bool showDivider;

  const BrandHeader({super.key, this.trailing, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.screenPadding, 8, AppDimensions.screenPadding, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: showDivider
            ? const Border(
                bottom: BorderSide(
                    color: AppColors.borderLight,
                    width: AppDimensions.borderThin),
              )
            : null,
      ),
      child: Row(
        children: [
          const AppLogo(size: 34),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 1),
                Text(
                  '${AppConstants.region} • ${AppConstants.facility}',
                  style: AppTextStyles.captionMuted,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The app logo rendered in a rounded container.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: Image.asset(
        AppConstants.logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.26),
          ),
          child: Icon(Icons.health_and_safety_rounded,
              color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }
}

/// Small status pill — Online / Offline / Synced / Active.
class StatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color background;
  final bool dot;

  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    required this.background,
    this.dot = false,
  });

  factory StatusPill.offline() => const StatusPill(
        label: 'Offline',
        icon: Icons.cloud_off_rounded,
        color: AppColors.textSecondary,
        background: AppColors.neutralSurface,
      );

  factory StatusPill.online() => const StatusPill(
        label: 'Online',
        dot: true,
        color: AppColors.success,
        background: AppColors.successLight,
      );

  /// Live network pill — flips between Online / Offline automatically.
  static Widget connection() => const ConnectionPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dot ? 10 : 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
            color: color.withValues(alpha: 0.22), width: 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reactive connection pill — listens to live network state.
class ConnectionPill extends StatelessWidget {
  const ConnectionPill({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (_, online, _) =>
          online ? StatusPill.online() : StatusPill.offline(),
    );
  }
}
