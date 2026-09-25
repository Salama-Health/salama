import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/activity_model.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/brand_header.dart';
import '../../widgets/common/offline_banner.dart';

/// The full activity feed — every dose, visit, registration and sync, newest
/// first. Reached from "View all" on the home screen.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  ActivityType? _type;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(activityProvider);
    final all = async.valueOrNull ?? const <ActivityModel>[];
    final list =
        _type == null ? all : all.where((a) => a.type == _type).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(6, 6, AppDimensions.screenPadding, 10),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(
                      color: AppColors.borderLight,
                      width: AppDimensions.borderThin),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary, size: 20),
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent activity',
                            style: AppTextStyles.h1.copyWith(fontSize: 17)),
                        Text(
                          '${all.length} ${all.length == 1 ? "entry" : "entries"}',
                          style: AppTextStyles.captionMuted,
                        ),
                      ],
                    ),
                  ),
                  const ConnectionPill(),
                ],
              ),
            ),
          ),
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(activityProvider);
                await ref.read(activityProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  AppDimensions.spaceMD,
                  AppDimensions.screenPadding,
                  AppDimensions.spaceXXL,
                ),
                children: [
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _Chip(
                          label: 'All',
                          selected: _type == null,
                          onTap: () => setState(() => _type = null),
                        ),
                        ...ActivityType.values.map((t) {
                          final n = all.where((a) => a.type == t).length;
                          if (n == 0) return const SizedBox.shrink();
                          return _Chip(
                            label: '${_label(t)} ($n)',
                            icon: t.icon,
                            selected: _type == t,
                            onTap: () => setState(
                                () => _type = _type == t ? null : t),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  async.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 44),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              size: 30, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text('Couldn’t load activity',
                              style: AppTextStyles.h4),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref.invalidate(activityProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (_) => list.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 50),
                            child: Column(
                              children: [
                                const Icon(Icons.history_rounded,
                                    size: 30, color: AppColors.textTertiary),
                                const SizedBox(height: 8),
                                Text('Nothing here yet',
                                    style: AppTextStyles.h4),
                                const SizedBox(height: 2),
                                Text('Work you record will appear here.',
                                    style: AppTextStyles.bodySmall),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusLG),
                              border: Border.all(
                                  color: AppColors.borderLight,
                                  width: AppDimensions.borderNormal),
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < list.length; i++)
                                  _ActivityRow(
                                    item: list[i],
                                    isLast: i == list.length - 1,
                                  ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _label(ActivityType t) => switch (t) {
        ActivityType.vaccination => 'Doses',
        ActivityType.visit => 'Visits',
        ActivityType.sync => 'Syncs',
        ActivityType.alert => 'Alerts',
        ActivityType.registration => 'Registrations',
      };
}

class _ActivityRow extends StatelessWidget {
  final ActivityModel item;
  final bool isLast;

  const _ActivityRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                    color: AppColors.borderLight,
                    width: AppDimensions.borderThin),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: item.type.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(item.type.icon, size: 15, color: item.type.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h4),
                if (item.subtitle.isNotEmpty)
                  Text(item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionMuted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(item.time, style: AppTextStyles.captionMuted),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderLight,
              width: 0.75,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 12,
                    color: selected
                        ? AppColors.textOnPrimary
                        : AppColors.textTertiary),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                    color: selected
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
