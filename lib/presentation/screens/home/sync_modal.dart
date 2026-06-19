import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';

/// Small popup modal to approve a data sync.
void showSyncModal(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (_, online, _) => _SyncModal(isOnline: online),
    ),
  );
}

class _SyncModal extends ConsumerStatefulWidget {
  final bool isOnline;
  const _SyncModal({required this.isOnline});

  @override
  ConsumerState<_SyncModal> createState() => _SyncModalState();
}

class _SyncModalState extends ConsumerState<_SyncModal> {
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final result = await ref.read(syncRepositoryProvider).upload();
      ref.invalidate(syncStatusProvider);
      ref.invalidate(childrenProvider);
      ref.invalidate(activityProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.totalSaved > 0
              ? 'Synced ${result.totalSaved} record(s) successfully.'
              : 'Everything is already up to date.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.isOnline;
    final syncStatus = ref.watch(syncStatusProvider).valueOrNull;
    final pending = syncStatus?.pendingRecords ?? 0;
    final lastSync = syncStatus?.lastSyncLabel ?? '—';
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_sync_outlined,
                        color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(height: 10),
                  Text('Sync data', style: AppTextStyles.h2),
                  const SizedBox(height: 2),
                  Text(
                    isOnline
                        ? 'Upload your offline records to the server.'
                        : 'You need an internet connection to sync.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.captionMuted,
                  ),
                  const SizedBox(height: 14),
                  // Connection status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.successLight
                          : AppColors.warningLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOnline
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          size: 14,
                          color: isOnline
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'Device is online' : 'Device is offline',
                          style: AppTextStyles.caption.copyWith(
                            color: isOnline
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Detail rows
                  _Row(
                    icon: Icons.folder_open_rounded,
                    label: 'Records awaiting sync',
                    value: '$pending',
                  ),
                  const SizedBox(height: 6),
                  _Row(
                    icon: Icons.schedule_rounded,
                    label: 'Last synced',
                    value: lastSync,
                  ),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: AppColors.borderLight),
            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _ModalButton(
                      label: 'Cancel',
                      outline: true,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _ModalButton(
                      label: _syncing
                          ? 'Syncing…'
                          : (isOnline ? 'Sync now' : 'Offline'),
                      icon: isOnline
                          ? Icons.cloud_upload_outlined
                          : Icons.cloud_off_rounded,
                      enabled: isOnline && !_syncing,
                      onTap: _sync,
                    ),
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

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 7),
        Text(label, style: AppTextStyles.bodySmall),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ModalButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool outline;
  final bool enabled;
  final VoidCallback onTap;

  const _ModalButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.outline = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outline
        ? AppColors.textPrimary
        : (enabled ? Colors.white : AppColors.textTertiary);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outline
              ? AppColors.cardBackground
              : (enabled ? AppColors.primary : AppColors.neutralSurface),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: outline
              ? Border.all(color: AppColors.borderMedium, width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
