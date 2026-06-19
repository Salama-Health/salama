import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/vaccination_record.dart';
import '../visits/visits_screen.dart' show priorityHue;
import 'medical_history_sheet.dart';
import 'record_vaccination_sheet.dart';

void showScannedChildSheet(BuildContext context, ChildModel child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _ScannedChildSheet(child: child),
  );
}

class _ScannedChildSheet extends StatelessWidget {
  final ChildModel child;
  const _ScannedChildSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final hue = priorityHue(child.riskBand);
    final given =
        child.history.where((r) => r.status == DoseStatus.given).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
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
            const _Grabber(),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMD, 6, AppDimensions.spaceSM, 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: hue.accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.child_care_rounded,
                        color: hue.accent, size: 20),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.name, style: AppTextStyles.h3),
                        Text('Scanned • ${child.code}',
                            style: AppTextStyles.captionMuted),
                      ],
                    ),
                  ),
                  _CloseButton(onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: AppColors.borderLight),
            // Body
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                shrinkWrap: true,
                children: [
                  // Verified banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 15, color: AppColors.success),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Identity verified via QR code',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Identity
                  _Card(
                    tag: 'CHILD IDENTITY',
                    trailing: _CdiChip(child: child, hue: hue),
                    child: Column(
                      children: [
                        _Row(
                            icon: Icons.cake_outlined,
                            label: 'Date of birth',
                            value: child.bornDate),
                        _Row(
                            icon: Icons.hourglass_bottom_rounded,
                            label: 'Age',
                            value: child.ageLabel),
                        _Row(
                            icon: Icons.wc_rounded,
                            label: 'Gender',
                            value: child.gender),
                        _Row(
                            icon: Icons.my_location_rounded,
                            label: 'Likely current location',
                            value: child.currentLocation,
                            highlight: true),
                        _Row(
                            icon: Icons.schedule_rounded,
                            label: 'Last contact',
                            value: child.lastSeen,
                            last: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Parent
                  _Card(
                    tag: 'PARENT / CAREGIVER',
                    child: child.parentPhone != null
                        ? Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSM),
                                ),
                                child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.primary,
                                    size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(child.parentName ?? 'Caregiver',
                                        style: AppTextStyles.h4),
                                    Text(child.parentPhone!,
                                        style: AppTextStyles.captionMuted),
                                  ],
                                ),
                              ),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSM),
                                ),
                                child: const Icon(Icons.call_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 15,
                                  color: AppColors.textTertiary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'No parent contact on record.',
                                    style: AppTextStyles.bodySmall),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  // Vaccines received
                  _Card(
                    tag: 'VACCINES RECEIVED',
                    trailing: Text('${given.length} doses',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w700,
                        )),
                    child: given.isEmpty
                        ? Text('No vaccinations recorded yet.',
                            style: AppTextStyles.bodySmall)
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: given
                                .map((r) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.successLight,
                                        borderRadius: BorderRadius.circular(
                                            AppDimensions.radiusFull),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_rounded,
                                              size: 11,
                                              color: AppColors.success),
                                          const SizedBox(width: 3),
                                          Text(r.vaccine,
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                color: AppColors.success,
                                                fontWeight:
                                                    FontWeight.w700,
                                                fontSize: 10.5,
                                              )),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 8),
                  // QR options
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
                ],
              ),
            ),
            // Action bar
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMD, 9, AppDimensions.spaceMD, 9),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                    top: BorderSide(
                        color: AppColors.borderMedium, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _BarButton(
                      label: 'View record',
                      icon: Icons.history_rounded,
                      outline: true,
                      onTap: () {
                        Navigator.pop(context);
                        showMedicalHistorySheet(context, child);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BarButton(
                      label: 'Record new',
                      icon: Icons.add_circle_outline_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        showRecordVaccinationSheet(context, child);
                      },
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

class _CdiChip extends StatelessWidget {
  final ChildModel child;
  final ({Color bg, Color border, Color accent, Color surface}) hue;
  const _CdiChip({required this.child, required this.hue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hue.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded, size: 11, color: hue.accent),
          const SizedBox(width: 3),
          Text('CDI ${child.riskScore.toStringAsFixed(2)}',
              style: AppTextStyles.caption.copyWith(
                color: hue.accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              )),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  final bool highlight;
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom:
                    BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: highlight
                  ? AppColors.primary
                  : AppColors.textTertiary),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: AppTextStyles.caption.copyWith(
                  color: highlight
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
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

class _BarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool outline;
  final VoidCallback onTap;
  const _BarButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outline ? AppColors.primary : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outline ? AppColors.cardBackground : AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: outline
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String tag;
  final Widget child;
  final Widget? trailing;
  const _Card({required this.tag, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(tag),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25), width: 0.75),
      ),
      child: Text(text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          )),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 2),
      width: 36,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.borderMedium,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderMedium, width: 1),
        ),
        child: const Icon(Icons.close_rounded,
            size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
