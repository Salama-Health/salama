import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/storage/offline_cache.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/core_providers.dart';

/// Thin strip shown above a screen's content when what is on screen came from
/// the device rather than the server.
///
/// It is deliberately quiet — a worker offline in a village is doing normal
/// work, not experiencing an error. It says what the data is and how old, and
/// then gets out of the way.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(offlineCacheProvider);

    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, online, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: cache.servingStale,
          builder: (context, stale, _) {
            if (online && !stale) return const SizedBox.shrink();

            final saved = cache.savedAtLabel(OfflineCache.kChildren) ??
                cache.savedAtLabel(OfflineCache.kFacilities);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding, vertical: 7),
              color: AppColors.warningSurface,
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 13, color: AppColors.warning),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      online
                          ? 'Server unreachable — showing saved data'
                          : 'Offline — showing saved data',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                  if (saved != null)
                    Text('Updated $saved',
                        style: AppTextStyles.captionMuted.copyWith(
                          color: AppColors.warning.withValues(alpha: 0.8),
                          fontSize: 10,
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
