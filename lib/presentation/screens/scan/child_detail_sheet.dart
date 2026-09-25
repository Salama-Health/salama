import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/child_model.dart';
import '../../providers/data_providers.dart';
import '../visits/visits_screen.dart' show priorityHue;
import 'medical_history_sheet.dart';
import 'record_vaccination_sheet.dart';

void showChildDetailSheet(BuildContext context, ChildModel child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _ChildDetailSheet(passedChild: child),
  );
}

class _ChildDetailSheet extends ConsumerWidget {
  final ChildModel passedChild;
  const _ChildDetailSheet({required this.passedChild});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq = MediaQuery.of(context);
    // Use the full detail (with vaccination history) once loaded.
    final child =
        ref.watch(childDetailProvider(passedChild.id)).valueOrNull ?? passedChild;
    final hue = priorityHue(child.riskBand);
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
                        Text('${child.code} • ${child.ageLabel}',
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
                  _PriorityBanner(child: child, hue: hue),
                  const SizedBox(height: 8),
                  _DetailsCard(child: child),
                  const SizedBox(height: 8),
                  _ParentCard(child: child),
                  const SizedBox(height: 8),
                  _DueVaccinesCard(child: child, accent: hue.accent),
                ],
              ),
            ),
            // Action bar
            _ActionBar(child: child),
          ],
        ),
      ),
    );
  }
}

// ── Priority banner ──────────────────────────────────────────────────────
class _PriorityBanner extends StatelessWidget {
  final ChildModel child;
  final ({Color bg, Color border, Color accent, Color surface}) hue;
  const _PriorityBanner({required this.child, required this.hue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: hue.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
            color: hue.accent.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high_rounded, color: hue.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.priorityLabel,
                    style: AppTextStyles.h4.copyWith(color: hue.accent)),
                Text('Climate-disruption index for this child',
                    style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
              ],
            ),
          ),
          Text(child.riskScore.toStringAsFixed(2),
              style: AppTextStyles.statNumberSmall
                  .copyWith(fontSize: 20, color: hue.accent)),
        ],
      ),
    );
  }
}

// ── Details card ─────────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final ChildModel child;
  const _DetailsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return _Card(
      tag: 'CHILD DETAILS',
      child: Column(
        children: [
          _DetailRow(
              icon: Icons.cake_outlined,
              label: 'Date of birth',
              value: child.bornDate),
          _DetailRow(
              icon: Icons.wc_rounded, label: 'Gender', value: child.gender),
          _DetailRow(
              icon: Icons.schedule_rounded,
              label: 'Last contact',
              value: child.lastSeen),
          _DetailRow(
              icon: Icons.my_location_rounded,
              label: 'Likely current location',
              value: child.currentLocation,
              highlight: true),
          _DetailRow(
              icon: Icons.directions_walk_rounded,
              label: 'Distance from you',
              value: '${child.distanceKm} km',
              last: true),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  final bool highlight;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              color: highlight ? AppColors.primary : AppColors.textTertiary),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                color: highlight ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Parent card ──────────────────────────────────────────────────────────
class _ParentCard extends StatelessWidget {
  final ChildModel child;
  const _ParentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final hasParent = child.parentPhone != null;
    return _Card(
      tag: 'PARENT / CAREGIVER',
      child: hasParent
          ? Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.parentName ?? 'Caregiver',
                          style: AppTextStyles.h4),
                      Text(child.parentPhone!,
                          style: AppTextStyles.captionMuted),
                    ],
                  ),
                ),
                // Placing a call needs the dialer, which this build does not
                // open; copying the number is the honest equivalent.
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: child.parentPhone!));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Copied ${child.parentPhone} — paste it into your dialler.'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: const Icon(Icons.content_copy_rounded,
                        color: Colors.white, size: 15),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('No parent contact on record for this child.',
                      style: AppTextStyles.bodySmall),
                ),
              ],
            ),
    );
  }
}

// ── Due vaccines card ────────────────────────────────────────────────────
class _DueVaccinesCard extends StatelessWidget {
  final ChildModel child;
  final Color accent;
  const _DueVaccinesCard({required this.child, required this.accent});

  @override
  Widget build(BuildContext context) {
    return _Card(
      tag: 'VACCINES DUE',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: child.dueVaccines
            .map((v) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.3), width: 0.75),
                  ),
                  child: Text(v,
                      style: AppTextStyles.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      )),
                ))
            .toList(),
      ),
    );
  }
}

// ── Action bar ───────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final ChildModel child;
  const _ActionBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceMD, 9, AppDimensions.spaceMD, 9),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border:
            Border(top: BorderSide(color: AppColors.borderMedium, width: 1)),
      ),
      child: Row(
        children: [
          _SquareButton(
            icon: Icons.qr_code_scanner_rounded,
            onTap: () {
              Navigator.pop(context);
              showMedicalHistorySheet(context, child);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                showRecordVaccinationSheet(context, child);
              },
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.vaccines_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 7),
                    Text('Record vaccination',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Icon(icon, size: 19, color: AppColors.primary),
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String tag;
  final Widget child;
  const _Card({required this.tag, required this.child});

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
          _Tag(tag),
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
