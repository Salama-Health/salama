import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/worker_model.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_sheet.dart';
import '../../widgets/common/app_text_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Personal information
// ─────────────────────────────────────────────────────────────────────────────
void showPersonalInfoSheet(BuildContext context, WorkerModel? worker) {
  showAppSheet(
    context,
    AppSheet(
      icon: Icons.person_outline_rounded,
      title: 'Personal information',
      subtitle: worker?.name ?? 'Not signed in',
      maxHeightFactor: 0.8,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        shrinkWrap: true,
        children: [
          if (worker == null)
            const _Empty(text: 'No profile loaded.')
          else ...[
            _InfoGroup(rows: [
              ('Full name', worker.name),
              ('Role', worker.role),
              ('Worker ID', worker.workerId),
              ('Phone', worker.phone.isEmpty ? '—' : worker.phone),
            ]),
            const SizedBox(height: AppDimensions.spaceMD),
            const SheetSectionLabel('Posting'),
            _InfoGroup(rows: [
              ('Facility', worker.facility),
              ('County', worker.county),
              ('Facilities covered', '${worker.facilitiesCount}'),
              ('Status', worker.active ? 'Active' : 'Inactive'),
            ]),
            const SizedBox(height: AppDimensions.spaceMD),
            _Note(
              icon: Icons.lock_outline_rounded,
              text: 'Your posting and role are set by your supervisor. Ask '
                  'them to update anything that is wrong here.',
            ),
            const SizedBox(height: AppDimensions.spaceSM),
            AppButton(
              label: 'Copy worker ID',
              variant: AppButtonVariant.outline,
              icon: Icons.copy_rounded,
              height: 42,
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: worker.workerId));
                if (!context.mounted) return;
                _toast(context, 'Worker ID copied');
              },
            ),
          ],
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Security — change PIN
// ─────────────────────────────────────────────────────────────────────────────
void showSecuritySheet(BuildContext context) {
  showAppSheet(context, const _SecuritySheet());
}

class _SecuritySheet extends ConsumerStatefulWidget {
  const _SecuritySheet();

  @override
  ConsumerState<_SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends ConsumerState<_SecuritySheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _current.text.trim();
    final next = _next.text.trim();
    final confirm = _confirm.text.trim();

    if (current.isEmpty) {
      setState(() => _error = 'Enter your current PIN.');
      return;
    }
    if (next.length < 4) {
      setState(() => _error = 'The new PIN must be at least 4 digits.');
      return;
    }
    if (next == current) {
      setState(() => _error = 'The new PIN must be different.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'The two new PINs do not match.');
      return;
    }
    if (!ConnectivityService.instance.isOnline.value) {
      setState(() => _error =
          'Changing your PIN needs a connection — it must be saved on the server.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .changePin(currentPin: current, newPin: next);
      if (!mounted) return;
      Navigator.pop(context);
      _toast(context, 'PIN changed');
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        // The endpoint is still being built; a 404 here is not the worker
        // getting their own PIN wrong.
        _error = e.statusCode == 404
            ? 'Changing your PIN is not available on the server yet. '
                'Ask your supervisor to reset it.'
            : e.message;
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      icon: Icons.lock_outline_rounded,
      iconColor: AppColors.info,
      title: 'Security',
      subtitle: 'Change the PIN you sign in with',
      maxHeightFactor: 0.85,
      footer: AppButton(
        label: 'Change PIN',
        icon: Icons.check_rounded,
        height: 44,
        isLoading: _saving,
        onPressed: _submit,
      ),
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        shrinkWrap: true,
        children: [
          AppTextField(
            label: 'Current PIN',
            controller: _current,
            obscure: true,
            icon: Icons.lock_outline_rounded,
            keyboardType: TextInputType.number,
            capitalization: TextCapitalization.none,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          AppTextField(
            label: 'New PIN',
            controller: _next,
            obscure: true,
            icon: Icons.lock_reset_rounded,
            keyboardType: TextInputType.number,
            capitalization: TextCapitalization.none,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helper: 'At least 4 digits. Avoid 1234 or your year of birth.',
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          AppTextField(
            label: 'Confirm new PIN',
            controller: _confirm,
            obscure: true,
            icon: Icons.lock_reset_rounded,
            keyboardType: TextInputType.number,
            capitalization: TextCapitalization.none,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: _error,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          _Note(
            icon: Icons.shield_outlined,
            text: 'Your PIN protects the children’s records on this phone. '
                'Never share it, and change it if someone else has used the '
                'device.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language
// ─────────────────────────────────────────────────────────────────────────────
void showLanguageSheet(BuildContext context) {
  showAppSheet(context, const _LanguageSheet());
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return AppSheet(
      icon: Icons.language_rounded,
      title: 'Language',
      subtitle: settings.language.label,
      maxHeightFactor: 0.7,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        shrinkWrap: true,
        children: [
          ...AppLanguage.values.map((lang) {
            final selected = settings.language == lang;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: lang.available
                    ? () {
                        ref
                            .read(settingsProvider.notifier)
                            .update(settings.copyWith(language: lang));
                        Navigator.pop(context);
                      }
                    : null,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: lang.available ? 1 : 0.55,
                  child: Container(
                    padding:
                        const EdgeInsets.all(AppDimensions.cardPaddingSm),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primarySurface
                          : AppColors.cardBackground,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMD),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.borderLight,
                        width: selected
                            ? AppDimensions.borderMedium
                            : AppDimensions.borderNormal,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lang.label, style: AppTextStyles.h4),
                              Text(lang.nativeLabel,
                                  style: AppTextStyles.captionMuted),
                            ],
                          ),
                        ),
                        if (!lang.available)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.neutralSurface,
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                            ),
                            child: Text('Coming soon',
                                style: AppTextStyles.captionMuted
                                    .copyWith(fontSize: 10)),
                          )
                        else if (selected)
                          const Icon(Icons.check_circle_rounded,
                              size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: AppDimensions.spaceSM),
          _Note(
            icon: Icons.translate_rounded,
            text: 'Juba Arabic, Nuer and Dinka are on the roadmap. Translation '
                'is being done with health workers so the vaccine names and '
                'consent wording are right.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────────
void showNotificationsSheet(BuildContext context) {
  showAppSheet(context, const _NotificationsSheet());
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AppSheet(
      icon: Icons.notifications_none_rounded,
      iconColor: AppColors.accentPurple,
      title: 'Notifications',
      subtitle: 'What the app tells you about',
      maxHeightFactor: 0.75,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        shrinkWrap: true,
        children: [
          _ToggleRow(
            icon: Icons.warning_amber_rounded,
            title: 'Risk alerts',
            subtitle: 'Cold chain and climate disruption warnings',
            value: s.alertNotifications,
            onChanged: (v) =>
                notifier.update(s.copyWith(alertNotifications: v)),
          ),
          _ToggleRow(
            icon: Icons.event_available_outlined,
            title: 'Visit reminders',
            subtitle: 'Children falling due in your area',
            value: s.visitReminders,
            onChanged: (v) => notifier.update(s.copyWith(visitReminders: v)),
          ),
          _ToggleRow(
            icon: Icons.cloud_done_outlined,
            title: 'Sync confirmations',
            subtitle: 'Tell me when records finish uploading',
            value: s.syncNotifications,
            onChanged: (v) =>
                notifier.update(s.copyWith(syncNotifications: v)),
            isLast: true,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          _Note(
            icon: Icons.phone_android_rounded,
            text: 'These control what appears inside the app. Push '
                'notifications to a locked phone arrive in a later release.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sync settings
// ─────────────────────────────────────────────────────────────────────────────
void showSyncSettingsSheet(BuildContext context) {
  showAppSheet(context, const _SyncSettingsSheet());
}

class _SyncSettingsSheet extends ConsumerWidget {
  const _SyncSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final queue = ref.watch(syncRepositoryProvider).pendingBreakdown;
    final total = queue.vaccinations + queue.children + queue.visits;

    return AppSheet(
      icon: Icons.cloud_sync_outlined,
      iconColor: AppColors.warningMid,
      title: 'Sync settings',
      subtitle: total == 0
          ? 'Nothing waiting'
          : '$total ${total == 1 ? "record" : "records"} waiting',
      maxHeightFactor: 0.8,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        shrinkWrap: true,
        children: [
          _ToggleRow(
            icon: Icons.sync_rounded,
            title: 'Sync automatically',
            subtitle: 'Upload queued work as soon as a connection returns',
            value: s.autoSync,
            onChanged: (v) => notifier.update(s.copyWith(autoSync: v)),
          ),
          _ToggleRow(
            icon: Icons.signal_cellular_alt_rounded,
            title: 'Use mobile data',
            subtitle: 'Off means sync waits for Wi-Fi',
            value: s.syncOnMobileData,
            onChanged: (v) =>
                notifier.update(s.copyWith(syncOnMobileData: v)),
            isLast: true,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          const SheetSectionLabel('Waiting on this device'),
          _InfoGroup(rows: [
            ('Vaccination records', '${queue.vaccinations}'),
            ('New registrations', '${queue.children}'),
            ('Visit outcomes', '${queue.visits}'),
          ]),
          const SizedBox(height: AppDimensions.spaceMD),
          _Note(
            icon: Icons.info_outline_rounded,
            text: 'Queued records stay on the phone until the server confirms '
                'it has them. Nothing is deleted on a failed upload.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App settings
// ─────────────────────────────────────────────────────────────────────────────
void showAppSettingsSheet(BuildContext context) {
  showAppSheet(context, const _AppSettingsSheet());
}

class _AppSettingsSheet extends ConsumerStatefulWidget {
  const _AppSettingsSheet();

  @override
  ConsumerState<_AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends ConsumerState<_AppSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final cache = ref.watch(offlineCacheProvider);
    final consent = ref.watch(consentLogRepositoryProvider);
    final pending = ref.watch(syncRepositoryProvider).pendingCount;
    final size = cache.approxSizeKb;

    return AppSheet(
      icon: Icons.smartphone_rounded,
      title: 'App settings',
      subtitle: 'Offline data held on this phone',
      maxHeightFactor: 0.8,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        shrinkWrap: true,
        children: [
          _InfoGroup(rows: [
            ('Cached lists', '${cache.entryCount}'),
            ('Approximate size', '${size.toStringAsFixed(1)} KB'),
            (
              'Last updated',
              cache.savedAtLabel('children') ?? 'never',
            ),
          ]),
          const SizedBox(height: AppDimensions.spaceMD),
          const SheetSectionLabel('Consent records'),
          _InfoGroup(rows: [
            ('Registrations with consent recorded', '${consent.count}'),
          ]),
          const SizedBox(height: 6),
          _Note(
            icon: Icons.assignment_outlined,
            text: 'Consent is held on this phone. The server does not store it '
                'yet, so export this log if the device is being replaced.',
          ),
          const SizedBox(height: 6),
          AppButton(
            label: 'Export consent log',
            variant: AppButtonVariant.outline,
            icon: Icons.copy_rounded,
            height: 42,
            onPressed: consent.count == 0
                ? null
                : () async {
                    await Clipboard.setData(
                        ClipboardData(text: consent.toCsv()));
                    if (!context.mounted) return;
                    _toast(context,
                        '${consent.count} consent records copied as CSV');
                  },
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          const SheetSectionLabel('Connection'),
          _InfoGroup(rows: [
            ('Server', AppConstants.apiBaseUrl),
            ('Network', ConnectivityService.instance.kindLabel),
          ]),
          const SizedBox(height: AppDimensions.spaceMD),
          if (pending > 0)
            _Note(
              icon: Icons.warning_amber_rounded,
              tint: AppColors.warning,
              surface: AppColors.warningSurface,
              text: '$pending ${pending == 1 ? "record is" : "records are"} '
                  'still waiting to upload. Sync before clearing anything.',
            )
          else
            _Note(
              icon: Icons.check_circle_outline_rounded,
              text: 'Everything recorded here has reached the server. Clearing '
                  'saved data only removes the offline copies of lists, which '
                  'reload on the next connection.',
            ),
          const SizedBox(height: AppDimensions.spaceSM),
          AppButton(
            label: 'Clear saved data',
            variant: AppButtonVariant.danger,
            icon: Icons.delete_outline_rounded,
            height: 42,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLG)),
                  title: Text('Clear saved data?', style: AppTextStyles.h2),
                  content: Text(
                    pending > 0
                        ? 'You still have $pending unsynced '
                            '${pending == 1 ? "record" : "records"}. Those are '
                            'kept — only the downloaded lists are cleared, and '
                            'the app will need a connection to show them again.'
                        : 'The downloaded lists are removed. The app will need '
                            'a connection to show children and facilities '
                            'again.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style:
                          TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await cache.clearAll();
              ref.invalidate(childrenProvider);
              ref.invalidate(facilitiesProvider);
              ref.invalidate(activityProvider);
              ref.invalidate(reportsProvider);
              if (!context.mounted) return;
              setState(() {});
              _toast(context, 'Saved data cleared');
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Help centre
// ─────────────────────────────────────────────────────────────────────────────
void showHelpSheet(BuildContext context) {
  showAppSheet(context, const _HelpSheet());
}

class _HelpSheet extends StatefulWidget {
  const _HelpSheet();

  @override
  State<_HelpSheet> createState() => _HelpSheetState();
}

class _HelpSheetState extends State<_HelpSheet> {
  int? _open;

  static const _faqs = <({String q, String a})>[
    (
      q: 'Can I work without a connection?',
      a: 'Yes. Children, facility risk and your route are saved on the phone '
          'and stay visible offline. Doses, registrations and visit outcomes '
          'are queued and upload automatically when you next sync.',
    ),
    (
      q: 'What does the CDI score mean?',
      a: 'The Climate Disruption Index estimates how likely weather is to '
          'interrupt immunization at a facility in the coming weeks — flooding '
          'cutting a road, or heat breaking the cold chain. Higher is worse; '
          '0.75 and above is treated as a cold chain risk.',
    ),
    (
      q: 'How is the visit priority worked out?',
      a: 'Each child gets a risk score from how overdue their doses are, how '
          'far they live from the facility, and the climate risk where they '
          'are. The Visits tab sorts by that score so the most urgent come '
          'first.',
    ),
    (
      q: 'A child has lost their QR code.',
      a: 'Tap Scan, then "Enter code manually" and search by name, village or '
          'caregiver. Open their record and show the code full screen so the '
          'caregiver can photograph it again.',
    ),
    (
      q: 'I recorded a dose by mistake.',
      a: 'Tell your supervisor. Records cannot be deleted from the phone — '
          'that is deliberate, so the register cannot be quietly changed after '
          'the fact.',
    ),
    (
      q: 'How long is my work kept on the phone?',
      a: 'Until it syncs. Nothing queued is removed until the server confirms '
          'it has been received.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      icon: Icons.help_outline_rounded,
      title: 'Help centre',
      subtitle: 'Common questions',
      maxHeightFactor: 0.85,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        shrinkWrap: true,
        children: [
          for (var i = 0; i < _faqs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _FaqTile(
                question: _faqs[i].q,
                answer: _faqs[i].a,
                expanded: _open == i,
                onTap: () => setState(() => _open = _open == i ? null : i),
              ),
            ),
          const SizedBox(height: AppDimensions.spaceSM),
          AppButton(
            label: 'Contact support',
            variant: AppButtonVariant.outline,
            icon: Icons.headset_mic_outlined,
            height: 42,
            onPressed: () {
              Navigator.pop(context);
              showContactSupportSheet(context);
            },
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: expanded
                ? AppColors.primary.withValues(alpha: 0.30)
                : AppColors.borderLight,
            width: AppDimensions.borderNormal,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(question, style: AppTextStyles.h4)),
                const SizedBox(width: 8),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 160),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(answer, style: AppTextStyles.bodySmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact support
// ─────────────────────────────────────────────────────────────────────────────
void showContactSupportSheet(BuildContext context) {
  showAppSheet(context, const _ContactSupportSheet());
}

/// Support contacts come with the worker's profile. If the programme has not
/// configured any, the sheet says so — it does not show an address that nobody
/// reads.
class _ContactSupportSheet extends ConsumerWidget {
  const _ContactSupportSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(currentWorkerProvider);
    final email = worker?.supportEmail;
    final phone = worker?.supportPhone;
    final hasAny = (email != null && email.isNotEmpty) ||
        (phone != null && phone.isNotEmpty);

    return AppSheet(
      icon: Icons.headset_mic_outlined,
      iconColor: AppColors.info,
      title: 'Contact support',
      subtitle: worker?.facility ?? 'Salama Health',
      maxHeightFactor: 0.6,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        shrinkWrap: true,
        children: [
          if (email != null && email.isNotEmpty) ...[
            _CopyRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: email,
            ),
            const SizedBox(height: 6),
          ],
          if (phone != null && phone.isNotEmpty)
            _CopyRow(
              icon: Icons.phone_outlined,
              label: 'Phone / WhatsApp',
              value: phone,
            ),
          if (!hasAny)
            _Note(
              icon: Icons.info_outline_rounded,
              text: 'No support contact has been set for your programme yet. '
                  'Your facility supervisor is the fastest route for anything '
                  'urgent.',
            ),
          const SizedBox(height: AppDimensions.spaceMD),
          _Note(
            icon: Icons.local_hospital_outlined,
            text: 'For anything clinical, or to correct a record, speak to '
                'your facility supervisor first — they can act faster than we '
                'can.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Training materials
// ─────────────────────────────────────────────────────────────────────────────
void showTrainingSheet(BuildContext context) {
  showAppSheet(
    context,
    AppSheet(
      icon: Icons.menu_book_outlined,
      iconColor: AppColors.warningMid,
      title: 'Training materials',
      subtitle: 'Guides for using Salama in the field',
      maxHeightFactor: 0.8,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        shrinkWrap: true,
        children: const [
          _GuideTile(
            icon: Icons.person_add_alt_1_outlined,
            title: 'Registering a child',
            body: 'Taking consent, estimating age when the date of birth is '
                'unknown, and handing over the QR code.',
          ),
          _GuideTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scanning and recording a dose',
            body: 'Confirming identity, choosing the right vaccine and '
                'entering the batch number.',
          ),
          _GuideTile(
            icon: Icons.cloud_off_rounded,
            title: 'Working offline',
            body: 'What the app can and cannot do without a connection, and '
                'when to sync.',
          ),
          _GuideTile(
            icon: Icons.ac_unit_rounded,
            title: 'Reading climate risk',
            body: 'What the CDI score means and how to act on a disruption '
                'window before it opens.',
          ),
          _GuideTile(
            icon: Icons.route_rounded,
            title: 'Running a route',
            body: 'Planning a day of visits and recording outcomes as you go.',
            isLast: true,
          ),
          SizedBox(height: AppDimensions.spaceMD),
          _Note(
            icon: Icons.download_outlined,
            text: 'Downloadable video and printable versions arrive with the '
                'training release. These summaries work offline today.',
          ),
        ],
      ),
    ),
  );
}

class _GuideTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  const _GuideTile({
    required this.icon,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
              color: AppColors.borderLight, width: AppDimensions.borderNormal),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Icon(icon, size: 15, color: AppColors.primary),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About
// ─────────────────────────────────────────────────────────────────────────────
void showAboutAppSheet(BuildContext context) {
  showAppSheet(
    context,
    AppSheet(
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.accentPurple,
      title: 'About Salama Health',
      subtitle: 'Version ${AppConstants.appVersion}',
      maxHeightFactor: 0.8,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMD),
        shrinkWrap: true,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appTagline,
                    style: AppTextStyles.h3
                        .copyWith(color: AppColors.primaryDark)),
                const SizedBox(height: 6),
                Text(AppConstants.appMotto, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          const SheetSectionLabel('Build'),
          _InfoGroup(rows: [
            ('Version', AppConstants.appVersion),
            ('Build', AppConstants.buildNumber),
            ('Server', AppConstants.apiBaseUrl),
          ]),
          const SizedBox(height: AppDimensions.spaceMD),
          const SheetSectionLabel('Data protection'),
          _Note(
            icon: Icons.shield_outlined,
            text: 'Records are collected with caregiver consent, used only for '
                'immunization follow-up, held on the device until they sync, '
                'and shared with your facility and supervisor.',
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          AppButton(
            label: 'Open source licences',
            variant: AppButtonVariant.outline,
            icon: Icons.gavel_rounded,
            height: 42,
            onPressed: () {
              Navigator.pop(context);
              showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
              );
            },
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared pieces
// ─────────────────────────────────────────────────────────────────────────────
class _InfoGroup extends StatelessWidget {
  final List<(String, String)> rows;
  const _InfoGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
            color: AppColors.borderLight, width: AppDimensions.borderNormal),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.cardPaddingSm, vertical: 10),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(
                            color: AppColors.borderLight,
                            width: AppDimensions.borderThin),
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rows[i].$1, style: AppTextStyles.captionMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 6),
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
            color: AppColors.borderLight, width: AppDimensions.borderNormal),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(icon, size: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                Text(subtitle, style: AppTextStyles.captionMuted),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CopyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        _toast(context, '$label copied');
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
              color: AppColors.borderLight, width: AppDimensions.borderNormal),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Icon(icon, size: 15, color: AppColors.info),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.captionMuted),
                  Text(value, style: AppTextStyles.h4),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded,
                size: 15, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color tint;
  final Color surface;

  const _Note({
    required this.icon,
    required this.text,
    this.tint = AppColors.textTertiary,
    this.surface = AppColors.surfaceElevated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child: Text(text, style: AppTextStyles.captionMuted)),
      );
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
