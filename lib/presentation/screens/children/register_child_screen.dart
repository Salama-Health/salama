import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/id_gen.dart';
import '../../../core/utils/immunization_schedule.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/facility_model.dart';
import '../../../data/repositories/consent_log_repository.dart';
import '../../../data/repositories/outbox_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_sheet.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/brand_header.dart';
import 'child_registered_screen.dart';

/// Register a child into the immunization register.
///
/// Built for the field: the form works with no connection, estimates a date of
/// birth when the caregiver only knows an age, computes the doses already due
/// from the national schedule, and will not submit without recorded consent.
class RegisterChildScreen extends ConsumerStatefulWidget {
  const RegisterChildScreen({super.key});

  @override
  ConsumerState<RegisterChildScreen> createState() =>
      _RegisterChildScreenState();
}

class _RegisterChildScreenState extends ConsumerState<RegisterChildScreen> {
  final _name = TextEditingController();
  final _caregiver = TextEditingController();
  final _phone = TextEditingController();
  final _village = TextEditingController();
  final _distance = TextEditingController();
  final _notes = TextEditingController();

  String? _sex; // 'F' | 'M'
  DateTime? _dob;
  bool _dobEstimated = false;
  FacilityModel? _facility;
  Set<String> _dueVaccines = {};
  bool _consent = false;
  bool _saving = false;

  // Field-level errors, populated on submit.
  final Map<String, String> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _caregiver.dispose();
    _phone.dispose();
    _village.dispose();
    _distance.dispose();
    _notes.dispose();
    super.dispose();
  }

  // ── Date of birth ──────────────────────────────────────────────────────────
  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(now.year - 6),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) _applyDob(picked, estimated: false);
  }

  void _applyDob(DateTime date, {required bool estimated}) {
    setState(() {
      _dob = date;
      _dobEstimated = estimated;
      _errors.remove('dob');
      // Recompute the schedule; keep it fully selected by default so the
      // worker unticks what was already given rather than hunting for what is due.
      _dueVaccines = ImmunizationSchedule.dueFor(date).toSet();
    });
  }

  /// Ages a caregiver is likely to know when they do not know the date.
  static const _ageShortcuts = <({String label, int days})>[
    (label: 'Newborn', days: 0),
    (label: '6 weeks', days: 42),
    (label: '10 weeks', days: 70),
    (label: '14 weeks', days: 98),
    (label: '9 months', days: 274),
    (label: '18 months', days: 548),
  ];

  // ── Facility ───────────────────────────────────────────────────────────────
  Future<void> _pickFacility(List<FacilityModel> facilities) async {
    if (facilities.isEmpty) return;
    final picked = await showAppSheet<FacilityModel>(
      context,
      AppSheet(
        icon: Icons.local_hospital_outlined,
        title: 'Registering facility',
        subtitle: '${facilities.length} within reach',
        maxHeightFactor: 0.7,
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppDimensions.spaceMD),
          itemCount: facilities.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final f = facilities[i];
            final selected = f.id == _facility?.id;
            return GestureDetector(
              onTap: () => Navigator.pop(context, f),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primarySurface
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
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
                          Text(f.name, style: AppTextStyles.h4),
                          Text(f.county, style: AppTextStyles.captionMuted),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    if (picked != null) setState(() => _facility = picked);
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  bool _validate() {
    final errors = <String, String>{};
    if (_name.text.trim().length < 2) {
      errors['name'] = "Enter the child's name.";
    }
    if (_sex == null) errors['sex'] = 'Select the sex.';
    if (_dob == null) errors['dob'] = 'Enter or estimate the date of birth.';
    if (_caregiver.text.trim().length < 2) {
      errors['caregiver'] = "Enter the caregiver's name.";
    }
    if (_village.text.trim().isEmpty) {
      errors['village'] = 'Enter the village or settlement.';
    }
    final d = _distance.text.trim();
    if (d.isNotEmpty && double.tryParse(d) == null) {
      errors['distance'] = 'Enter a number, for example 3.5';
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    if (!_validate()) {
      _toast('Check the highlighted fields.', error: true);
      return;
    }
    if (!_consent) {
      _toast('Record the caregiver’s consent before registering.', error: true);
      return;
    }

    setState(() => _saving = true);

    final worker = ref.read(currentWorkerProvider);
    final code = IdGen.childCode();
    final clientUuid = IdGen.uuid();
    final now = DateTime.now().toUtc();

    final payload = <String, dynamic>{
      'clientUuid': clientUuid,
      'qrCode': code,
      'name': _name.text.trim(),
      'gender': _sex,
      'bornDate': _dob!.toIso8601String().split('T').first,
      'bornDateEstimated': _dobEstimated,
      'parentName': _caregiver.text.trim(),
      'parentPhone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'currentLocation': _village.text.trim(),
      'distanceKm': double.tryParse(_distance.text.trim()) ?? 0,
      'facilityId': _facility?.id,
      'dueVaccines': _dueVaccines.toList(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'consentGiven': true,
      'consentAt': now.toIso8601String(),
      'registeredBy': worker?.workerId,
      'registeredAt': now.toIso8601String(),
    };

    // Record the consent locally first. The server accepts consentGiven and
    // consentAt but does not store them yet, and the outbox discards a payload
    // once it is accepted — so this is the only lasting evidence until it does.
    await ref.read(consentLogRepositoryProvider).record(
          ConsentRecord(
            childCode: code,
            childName: _name.text.trim(),
            caregiverName: _caregiver.text.trim(),
            workerId: worker?.workerId,
            consentAt: now,
          ),
        );

    // One call covers both paths: sent if the network allows, durably queued
    // if not. Only a rejection from the server surfaces as an error.
    final WriteResult<ChildModel> result;
    try {
      result = await ref.read(outboxRepositoryProvider).submit<ChildModel>(
            kind: OutboxKind.child,
            payload: payload,
            request: () =>
                ref.read(childrenRepositoryProvider).create(payload),
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message, error: true);
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('$e', error: true);
      return;
    }

    // A queued registration has to appear in the caseload straight away, or the
    // child the worker just created is invisible to the app that created them.
    if (result.queued) {
      await ref.read(childrenRepositoryProvider).addLocal(payload);
    }
    final synced = result.synced;
    final resultCode = result.value?.code ?? code;

    ref.invalidate(childrenProvider);
    ref.invalidate(syncStatusProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(alertsProvider);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChildRegisteredScreen(
          name: _name.text.trim(),
          code: resultCode,
          ageLabel: ImmunizationSchedule.ageLabel(_dob!),
          village: _village.text.trim(),
          dueVaccines: _dueVaccines.toList(),
          synced: synced,
        ),
      ),
    );
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final facilities =
        ref.watch(facilitiesProvider).valueOrNull ?? const <FacilityModel>[];
    final worker = ref.watch(currentWorkerProvider);
    final next = _dob == null ? null : ImmunizationSchedule.nextFor(_dob!);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _Header(onBack: () => Navigator.pop(context)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                AppDimensions.spaceMD,
                AppDimensions.screenPadding,
                AppDimensions.spaceLG,
              ),
              children: [
                // ── Child ──────────────────────────────────────────────────
                _FormSection(
                  icon: Icons.child_care_rounded,
                  title: 'Child',
                  subtitle: 'Who you are registering',
                  children: [
                    AppTextField(
                      label: 'Full name',
                      controller: _name,
                      required: true,
                      icon: Icons.person_outline_rounded,
                      hint: 'e.g. Nyawal Gatluak',
                      errorText: _errors['name'],
                      onChanged: (_) => _clearError('name'),
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    _SexSelector(
                      value: _sex,
                      error: _errors['sex'],
                      onChanged: (v) => setState(() {
                        _sex = v;
                        _errors.remove('sex');
                      }),
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    _DobField(
                      dob: _dob,
                      estimated: _dobEstimated,
                      error: _errors['dob'],
                      onPick: _pickDob,
                      shortcuts: _ageShortcuts,
                      onShortcut: (days) => _applyDob(
                        DateTime.now().subtract(Duration(days: days)),
                        estimated: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // ── Caregiver ──────────────────────────────────────────────
                _FormSection(
                  icon: Icons.family_restroom_rounded,
                  title: 'Caregiver',
                  subtitle: 'Who to contact for follow-up',
                  children: [
                    AppTextField(
                      label: 'Caregiver name',
                      controller: _caregiver,
                      required: true,
                      icon: Icons.person_outline_rounded,
                      hint: 'Parent or guardian',
                      errorText: _errors['caregiver'],
                      onChanged: (_) => _clearError('caregiver'),
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    AppTextField(
                      label: 'Phone number',
                      controller: _phone,
                      icon: Icons.phone_outlined,
                      hint: '+211 9xx xxx xxx',
                      keyboardType: TextInputType.phone,
                      capitalization: TextCapitalization.none,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                      ],
                      helper: 'Optional — used for visit reminders only.',
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // ── Location ───────────────────────────────────────────────
                _FormSection(
                  icon: Icons.place_outlined,
                  title: 'Where they live',
                  subtitle: 'Used to plan and order visits',
                  children: [
                    AppTextField(
                      label: 'Village or settlement',
                      controller: _village,
                      required: true,
                      icon: Icons.home_outlined,
                      hint: 'e.g. Rubkona',
                      errorText: _errors['village'],
                      onChanged: (_) => _clearError('village'),
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    AppTextField(
                      label: 'Distance from facility',
                      controller: _distance,
                      icon: Icons.straighten_rounded,
                      hint: '0.0',
                      suffixText: 'km',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      capitalization: TextCapitalization.none,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      errorText: _errors['distance'],
                      onChanged: (_) => _clearError('distance'),
                    ),
                    const SizedBox(height: AppDimensions.spaceMD),
                    _FacilityField(
                      facility: _facility,
                      fallback: worker?.facility,
                      enabled: facilities.isNotEmpty,
                      onTap: () => _pickFacility(facilities),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // ── Doses due ──────────────────────────────────────────────
                _FormSection(
                  icon: Icons.vaccines_outlined,
                  title: 'Doses due now',
                  subtitle: _dob == null
                      ? 'Set a date of birth to calculate'
                      : 'From the national EPI schedule',
                  children: [
                    if (_dob == null)
                      _Hint(
                        text: 'Once you enter the date of birth, the doses this '
                            'child should already have received are worked out '
                            'for you.',
                      )
                    else ...[
                      _VaccineChips(
                        all: ImmunizationSchedule.dueFor(_dob!),
                        selected: _dueVaccines,
                        onToggle: (v) => setState(() {
                          _dueVaccines.contains(v)
                              ? _dueVaccines.remove(v)
                              : _dueVaccines.add(v);
                        }),
                      ),
                      if (next != null) ...[
                        const SizedBox(height: AppDimensions.spaceSM),
                        _Hint(
                          icon: Icons.event_outlined,
                          text: 'Next after today: ${next.vaccine} in '
                              '${next.inWeeks} ${next.inWeeks == 1 ? "week" : "weeks"}.',
                        ),
                      ],
                    ],
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // ── Notes ──────────────────────────────────────────────────
                _FormSection(
                  icon: Icons.sticky_note_2_outlined,
                  title: 'Notes',
                  subtitle: 'Anything the next worker should know',
                  children: [
                    AppTextField(
                      label: 'Notes',
                      controller: _notes,
                      maxLines: 3,
                      hint: 'Optional — allergies, twin sibling, seasonal move…',
                      capitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMD),

                // ── Consent ────────────────────────────────────────────────
                _ConsentCard(
                  value: _consent,
                  onChanged: (v) => setState(() => _consent = v),
                ),
                const SizedBox(height: AppDimensions.spaceSM),
              ],
            ),
          ),
          _SubmitBar(
            saving: _saving,
            consented: _consent,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) setState(() => _errors.remove(key));
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, AppDimensions.screenPadding, 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
              color: AppColors.borderLight, width: AppDimensions.borderThin),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 20),
            tooltip: 'Back',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Register a child',
                    style: AppTextStyles.h1.copyWith(fontSize: 17)),
                Text('Adds them to the immunization register',
                    style: AppTextStyles.captionMuted),
              ],
            ),
          ),
          const ConnectionPill(),
        ],
      ),
    );
  }
}

// ── Section shell ────────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
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
                    Text(title, style: AppTextStyles.h3),
                    Text(subtitle, style: AppTextStyles.captionMuted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          ...children,
        ],
      ),
    );
  }
}

// ── Sex selector ─────────────────────────────────────────────────────────────
class _SexSelector extends StatelessWidget {
  final String? value;
  final String? error;
  final ValueChanged<String> onChanged;

  const _SexSelector({
    required this.value,
    required this.onChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Sex', style: AppTextStyles.h4),
            Text(' *',
                style: AppTextStyles.h4.copyWith(color: AppColors.riskHigh)),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: _SexOption(
                label: 'Female',
                icon: Icons.female_rounded,
                selected: value == 'F',
                onTap: () => onChanged('F'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SexOption(
                label: 'Male',
                icon: Icons.male_rounded,
                selected: value == 'M',
                onTap: () => onChanged('M'),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 12, color: AppColors.error),
              const SizedBox(width: 4),
              Text(error!,
                  style:
                      AppTextStyles.captionMuted.copyWith(color: AppColors.error)),
            ],
          ),
        ],
      ],
    );
  }
}

class _SexOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SexOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 46,
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primarySurface : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected
                ? AppDimensions.borderMedium
                : AppDimensions.borderNormal,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 17,
                color: selected ? AppColors.primary : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySemibold.copyWith(
                color:
                    selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date of birth ────────────────────────────────────────────────────────────
class _DobField extends StatelessWidget {
  final DateTime? dob;
  final bool estimated;
  final String? error;
  final VoidCallback onPick;
  final List<({String label, int days})> shortcuts;
  final ValueChanged<int> onShortcut;

  const _DobField({
    required this.dob,
    required this.estimated,
    required this.onPick,
    required this.shortcuts,
    required this.onShortcut,
    this.error,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final label = dob == null
        ? 'Select a date'
        : '${dob!.day} ${_months[dob!.month - 1]} ${dob!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Date of birth', style: AppTextStyles.h4),
            Text(' *',
                style: AppTextStyles.h4.copyWith(color: AppColors.riskHigh)),
            const Spacer(),
            if (dob != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  ImmunizationSchedule.ageLabel(dob!),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary, fontSize: 10.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onPick,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                color: hasError ? AppColors.errorMid : AppColors.borderLight,
                width: hasError
                    ? AppDimensions.borderMedium
                    : AppDimensions.borderNormal,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 15,
                    color: dob == null
                        ? AppColors.textTertiary
                        : AppColors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: dob == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (estimated)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text('Estimated',
                        style: AppTextStyles.captionMuted.copyWith(
                            color: AppColors.warning, fontSize: 10)),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text("Or estimate from the caregiver's answer",
            style: AppTextStyles.captionMuted),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: shortcuts
              .map((s) => GestureDetector(
                    onTap: () => onShortcut(s.days),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                        border: Border.all(
                            color: AppColors.borderLight, width: 0.75),
                      ),
                      child: Text(s.label,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                  ))
              .toList(),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 12, color: AppColors.error),
              const SizedBox(width: 4),
              Text(error!,
                  style: AppTextStyles.captionMuted
                      .copyWith(color: AppColors.error)),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Facility picker field ────────────────────────────────────────────────────
class _FacilityField extends StatelessWidget {
  final FacilityModel? facility;
  final String? fallback;
  final bool enabled;
  final VoidCallback onTap;

  const _FacilityField({
    required this.facility,
    required this.enabled,
    required this.onTap,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final label = facility?.name ?? fallback ?? 'Select a facility';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registering facility', style: AppTextStyles.h4),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                  color: AppColors.borderLight,
                  width: AppDimensions.borderNormal),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_outlined,
                    size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge),
                ),
                if (enabled)
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        if (!enabled) ...[
          const SizedBox(height: 4),
          Text('Using your assigned facility — the full list needs a connection.',
              style: AppTextStyles.captionMuted),
        ],
      ],
    );
  }
}

// ── Vaccine chips ────────────────────────────────────────────────────────────
class _VaccineChips extends StatelessWidget {
  final List<String> all;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _VaccineChips({
    required this.all,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) {
      return _Hint(
        icon: Icons.check_circle_outline_rounded,
        text: 'Nothing is due yet — the first doses are given at birth.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: all.map((v) {
            final on = selected.contains(v);
            return GestureDetector(
              onTap: () => onToggle(v),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: on ? AppColors.primary : AppColors.surfaceElevated,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: on ? AppColors.primary : AppColors.borderLight,
                    width: 0.75,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      on
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      size: 13,
                      color: on
                          ? AppColors.textOnPrimary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      v,
                      style: AppTextStyles.caption.copyWith(
                        color: on
                            ? AppColors.textOnPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 7),
        Text(
          '${selected.length} of ${all.length} marked as still due. '
          'Untick any the child has already received.',
          style: AppTextStyles.captionMuted,
        ),
      ],
    );
  }
}

// ── Consent ──────────────────────────────────────────────────────────────────
class _ConsentCard extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConsentCard({required this.value, required this.onChanged});

  @override
  State<_ConsentCard> createState() => _ConsentCardState();
}

class _ConsentCardState extends State<_ConsentCard> {
  bool _expanded = false;

  static const _collected = [
    "The child's name, sex and date of birth",
    'The caregiver’s name and phone number',
    'The village and distance from the facility',
    'Doses given, with date and batch number',
  ];

  @override
  Widget build(BuildContext context) {
    final on = widget.value;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: on ? AppColors.successLight : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: on
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.primary.withValues(alpha: 0.22),
          width: AppDimensions.borderNormal,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => widget.onChanged(!on),
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: on ? AppColors.success : AppColors.cardBackground,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXS + 2),
                    border: Border.all(
                      color: on ? AppColors.success : AppColors.borderMedium,
                      width: AppDimensions.borderMedium,
                    ),
                  ),
                  child: on
                      ? const Icon(Icons.check_rounded,
                          size: 15, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Caregiver consent', style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Text(
                        'The caregiver has been told what is recorded and why, '
                        'and agrees to this child being registered.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  _expanded ? 'Hide what is collected' : 'What is collected?',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._collected.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Icon(Icons.circle,
                                size: 4, color: AppColors.textTertiary),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child:
                                Text(line, style: AppTextStyles.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Records are held for immunization follow-up only, stored '
                    'on this device until they sync, and are visible to your '
                    'facility and supervisor.',
                    style: AppTextStyles.captionMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Submit bar ───────────────────────────────────────────────────────────────
class _SubmitBar extends StatelessWidget {
  final bool saving;
  final bool consented;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.saving,
    required this.consented,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppDimensions.screenPadding, 10, AppDimensions.screenPadding, 10),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(
              color: AppColors.borderLight, width: AppDimensions.borderThin),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: ConnectivityService.instance.isOnline,
              builder: (_, online, _) => Row(
                children: [
                  Icon(
                    online
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_rounded,
                    size: 13,
                    color: online
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      online
                          ? 'Will be saved to the register straight away.'
                          : 'No connection — saved on this phone and uploaded '
                              'at the next sync.',
                      style: AppTextStyles.captionMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: consented ? 1 : 0.55,
              child: AppButton(
                label: 'Register child',
                icon: Icons.person_add_alt_1_rounded,
                isLoading: saving,
                onPressed: onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small hint row ───────────────────────────────────────────────────────────
class _Hint extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Hint({required this.text, this.icon = Icons.info_outline_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
