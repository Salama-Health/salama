import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/id_gen.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/qr_full_screen.dart';
import 'register_child_screen.dart';

/// Confirmation after a registration, built around the thing the caregiver
/// leaves with: the child's QR code.
class ChildRegisteredScreen extends StatelessWidget {
  final String name;
  final String code;
  final String ageLabel;
  final String village;
  final List<String> dueVaccines;

  /// False when the record is queued on the device awaiting sync.
  final bool synced;

  const ChildRegisteredScreen({
    super.key,
    required this.name,
    required this.code,
    required this.ageLabel,
    required this.village,
    required this.dueVaccines,
    required this.synced,
  });

  @override
  Widget build(BuildContext context) {
    final payload = IdGen.qrPayload(code);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.screenPadding,
                  AppDimensions.spaceXL,
                  AppDimensions.screenPadding,
                  AppDimensions.spaceLG,
                ),
                children: [
                  const _SuccessMark(),
                  const SizedBox(height: AppDimensions.spaceLG),
                  Text(
                    '$name is registered',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h1.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$ageLabel · $village',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  Center(child: _SyncPill(synced: synced)),
                  const SizedBox(height: AppDimensions.spaceLG),

                  // ── QR card ────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceLG),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLG),
                      border: Border.all(
                          color: AppColors.borderLight,
                          width: AppDimensions.borderNormal),
                    ),
                    child: Column(
                      children: [
                        Text('CHILD IMMUNIZATION CODE',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            )),
                        const SizedBox(height: AppDimensions.spaceMD),
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.spaceMD),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMD),
                            border: Border.all(
                                color: AppColors.borderLight, width: 1),
                          ),
                          child: QrImageView(
                            data: payload,
                            version: QrVersions.auto,
                            size: 172,
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
                        const SizedBox(height: AppDimensions.spaceMD),
                        Text(
                          code,
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 17,
                            letterSpacing: 1.5,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceMD),
                        QrActionsRow(
                          payload: payload,
                          code: code,
                          title: name,
                          subtitle: '$ageLabel · $village',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),

                  _NextStepCard(
                    icon: Icons.print_outlined,
                    title: 'Give the code to the caregiver',
                    body: 'Open it full screen and photograph it, or write the '
                        'code onto the paper card. Scanning it at the next '
                        'visit pulls up this child instantly.',
                  ),
                  if (dueVaccines.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spaceSM),
                    _DueCard(vaccines: dueVaccines),
                  ],
                  if (!synced) ...[
                    const SizedBox(height: AppDimensions.spaceSM),
                    _NextStepCard(
                      icon: Icons.cloud_upload_outlined,
                      tint: AppColors.warning,
                      surface: AppColors.warningSurface,
                      title: 'Waiting to sync',
                      body: 'This registration is stored on the phone. It '
                          'uploads automatically the next time you sync with '
                          'a connection.',
                    ),
                  ],
                ],
              ),
            ),

            // ── Actions ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(AppDimensions.screenPadding,
                  10, AppDimensions.screenPadding, 10),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  top: BorderSide(
                      color: AppColors.borderLight,
                      width: AppDimensions.borderThin),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Register another',
                      variant: AppButtonVariant.outline,
                      icon: Icons.person_add_alt_1_outlined,
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const RegisterChildScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSM),
                  Expanded(
                    child: AppButton(
                      label: 'Done',
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.of(context).pop(),
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

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 62,
        height: 62,
        decoration: const BoxDecoration(
          color: AppColors.successLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded,
            size: 32, color: AppColors.success),
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  final bool synced;
  const _SyncPill({required this.synced});

  @override
  Widget build(BuildContext context) {
    final color = synced ? AppColors.success : AppColors.warning;
    final surface = synced ? AppColors.successLight : AppColors.warningLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            synced ? Icons.cloud_done_rounded : Icons.phone_android_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            synced ? 'Saved to the register' : 'Saved on this device',
            style: AppTextStyles.caption
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color tint;
  final Color surface;

  const _NextStepCard({
    required this.icon,
    required this.title,
    required this.body,
    this.tint = AppColors.primary,
    this.surface = AppColors.cardBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
            color: surface == AppColors.cardBackground
                ? AppColors.borderLight
                : tint.withValues(alpha: 0.22),
            width: AppDimensions.borderNormal),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(icon, size: 15, color: tint),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                const SizedBox(height: 2),
                Text(body, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  final List<String> vaccines;
  const _DueCard({required this.vaccines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
            color: AppColors.borderLight, width: AppDimensions.borderNormal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: const Icon(Icons.vaccines_outlined,
                    size: 15, color: AppColors.info),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${vaccines.length} '
                  '${vaccines.length == 1 ? "dose is" : "doses are"} due now',
                  style: AppTextStyles.h4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: vaccines
                .map((v) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(v,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.info)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
