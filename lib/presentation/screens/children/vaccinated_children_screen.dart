import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/administered_dose.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/offline_banner.dart';

/// Children this worker has vaccinated, most recently vaccinated first, each
/// with the doses they were given.
///
/// This answers "who have I actually reached", which the priority list cannot:
/// that one ranks by who still needs a visit, so a child drops down it as they
/// catch up and eventually disappears from view entirely.
class VaccinatedChildrenScreen extends ConsumerStatefulWidget {
  /// When false the screen is a tab and has no back button.
  final bool showBack;
  const VaccinatedChildrenScreen({super.key, this.showBack = true});

  @override
  ConsumerState<VaccinatedChildrenScreen> createState() =>
      _VaccinatedChildrenScreenState();
}

class _VaccinatedChildrenScreenState
    extends ConsumerState<VaccinatedChildrenScreen> {
  String _scope = 'mine';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(vaccinatedChildrenProvider(_scope));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                  6, 6, AppDimensions.screenPadding, 10),
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
                  if (widget.showBack)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary, size: 20),
                      tooltip: 'Back',
                    )
                  else
                    const SizedBox(width: AppDimensions.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Children vaccinated',
                            style: AppTextStyles.h3
                                .copyWith(color: AppColors.textPrimary)),
                        Text(
                          async.valueOrNull == null
                              ? (_scope == 'mine'
                                  ? 'Your record of doses given'
                                  : 'Doses given across your county')
                              : _subtitle(async.value!),
                          style: AppTextStyles.captionMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const OfflineBanner(),
          // Mine vs region. A CHW needs their own record for accountability,
          // and the county view to see coverage around them - including
          // children a colleague reached, which their own list never shows.
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                AppDimensions.spaceMD,
                AppDimensions.screenPadding,
                0),
            child: Row(
              children: [
                for (final option in const [
                  ('mine', 'I vaccinated'),
                  ('region', 'My region'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppDimensions.spaceSM),
                    child: GestureDetector(
                      onTap: () => setState(() => _scope = option.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceMD, vertical: 7),
                        decoration: BoxDecoration(
                          color: _scope == option.$1
                              ? AppColors.primary
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull),
                          border: Border.all(
                              color: _scope == option.$1
                                  ? AppColors.primary
                                  : AppColors.borderMedium,
                              width: 1),
                        ),
                        child: Text(option.$2,
                            style: AppTextStyles.caption.copyWith(
                              color: _scope == option.$1
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            )),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => _Message(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load your record',
                body: 'Check your connection and pull down to try again.',
                onRetry: () => ref.invalidate(administeredDosesProvider(_scope)),
              ),
              data: (children) {
                if (children.isEmpty) {
                  return _Message(
                    icon: Icons.vaccines_outlined,
                    title: _scope == 'mine'
                        ? 'No doses recorded yet'
                        : 'No doses in your county yet',
                    body: _scope == 'mine'
                        ? 'Children you vaccinate will appear here, with what '
                            'they received and when.'
                        : 'Doses given anywhere in your county will appear '
                            'here, whoever recorded them.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(administeredDosesProvider(_scope));
                    await ref.read(administeredDosesProvider(_scope).future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.screenPadding),
                    itemCount: children.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimensions.spaceMD),
                    itemBuilder: (_, i) => _ChildDoses(entry: children[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _subtitle(List<VaccinatedChild> children) {
    final doses = children.fold<int>(0, (sum, c) => sum + c.doses.length);
    final childWord = children.length == 1 ? 'child' : 'children';
    final doseWord = doses == 1 ? 'dose' : 'doses';
    return '${children.length} $childWord · $doses $doseWord given';
  }
}

// ── One child and their doses ────────────────────────────────────────────────
class _ChildDoses extends StatelessWidget {
  final VaccinatedChild entry;
  const _ChildDoses({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
            color: AppColors.borderLight, width: AppDimensions.borderThin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 18),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.childName,
                        style: AppTextStyles.bodySemibold
                            .copyWith(color: AppColors.textPrimary)),
                    Text(
                      '${entry.doses.length} '
                      '${entry.doses.length == 1 ? "dose" : "doses"}'
                      '${_lastLabel(entry)}',
                      style: AppTextStyles.captionMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Wrap(
            spacing: AppDimensions.spaceSM,
            runSpacing: AppDimensions.spaceSM,
            children: [for (final d in entry.doses) _DoseChip(dose: d)],
          ),
        ],
      ),
    );
  }

  static String _lastLabel(VaccinatedChild e) {
    final at = e.lastGivenAt;
    return at == null ? '' : ' · last ${_fmt(at)}';
  }
}

class _DoseChip extends StatelessWidget {
  final AdministeredDose dose;
  const _DoseChip({required this.dose});

  @override
  Widget build(BuildContext context) {
    // Site is shown when it was recorded. Doses given before the server stored
    // it simply omit it rather than showing a blank field.
    final detail = [
      if (dose.givenAt != null) _fmt(dose.givenAt!),
      if (dose.site != null && dose.site!.isNotEmpty) dose.site!,
      if (dose.administeredBy != null && dose.administeredBy!.isNotEmpty)
        dose.administeredBy!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMD, vertical: AppDimensions.spaceSM),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dose.vaccine,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textPrimary)),
          if (detail.isNotEmpty)
            Text(detail, style: AppTextStyles.captionMuted),
        ],
      ),
    );
  }
}

// ── Empty / error state ──────────────────────────────────────────────────────
class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppDimensions.spaceMD),
            Text(title,
                style: AppTextStyles.bodyLargeSemibold
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spaceXS),
            Text(body,
                style: AppTextStyles.captionMuted, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spaceMD),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmt(DateTime d) => '${_months[d.month - 1]} ${d.day}';
