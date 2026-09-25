import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/child_model.dart';
import '../../../data/models/vaccination_record.dart';
import '../../../data/repositories/outbox_repository.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';

void showRecordVaccinationSheet(BuildContext context, ChildModel child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _RecordVaccinationSheet(child: child),
  );
}

class _RecordVaccinationSheet extends ConsumerStatefulWidget {
  final ChildModel child;
  const _RecordVaccinationSheet({required this.child});

  @override
  ConsumerState<_RecordVaccinationSheet> createState() =>
      _RecordVaccinationSheetState();
}

class _RecordVaccinationSheetState
    extends ConsumerState<_RecordVaccinationSheet> {
  bool _saving = false;

  // Null when the child has nothing due. The sheet then offers no vaccine to
  // record rather than defaulting to one the server would reject.
  String? _vaccine;
  DateTime _date = DateTime.now();
  final _batchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _site = 'Left arm';

  @override
  void initState() {
    super.initState();
    final due = widget.child.dueVaccines;
    _vaccine = due.isEmpty ? null : due.first;
  }

  @override
  void dispose() {
    _batchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Only what is actually due. A vaccine already given, or not yet reached on
  /// the schedule, is refused by the server (409 / 400), so offering it here
  /// would only produce an error the worker cannot act on.
  List<String> get _options => widget.child.dueVaccines;

  String get _dateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_date.day} ${months[_date.month - 1]} ${_date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    final vaccine = _vaccine;
    if (vaccine == null) {
      _toast('Nothing is due for this child right now.', AppColors.warning);
      return;
    }
    setState(() => _saving = true);

    final child = widget.child;
    final batch = _batchCtrl.text.trim();
    final payload = <String, dynamic>{
      'childId': child.id,
      'vaccine': vaccine,
      'status': 'given',
      'batchNumber': batch.isEmpty ? null : batch,
      'site': _site,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'dateGiven': _date.toUtc().toIso8601String(),
      'clientUuid':
          '${child.id}-$vaccine-${DateTime.now().millisecondsSinceEpoch}',
    };

    final WriteResult<VaccinationRecord> result;
    try {
      result =
          await ref.read(outboxRepositoryProvider).submit<VaccinationRecord>(
                kind: OutboxKind.vaccination,
                payload: payload,
                request: () =>
                    ref.read(vaccinationsRepositoryProvider).record(payload),
              );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Could not save: ${e.message}', AppColors.error);
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Could not save: $e', AppColors.error);
      return;
    }

    // Refresh anything that depends on this child's doses.
    ref.invalidate(childrenProvider);
    ref.invalidate(childDetailProvider(child.id));
    ref.invalidate(vaccinationHistoryProvider(child.id));
    ref.invalidate(administeredDosesProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(syncStatusProvider);
    ref.invalidate(alertsProvider);

    // Confirm the dose on the device. Deliberately not awaited and never
    // allowed to throw: a notification is a confirmation of work already
    // done, so it must not delay the sheet closing or fail the save.
    unawaited(NotificationService.instance.doseRecorded(
      childName: child.name,
      vaccine: vaccine,
      pending: !result.synced,
    ));

    if (!mounted) return;
    Navigator.pop(context);
    _toast(
      result.synced
          ? '$vaccine recorded for ${child.name}'
          : '$vaccine saved on this phone — will sync later',
      result.synced ? AppColors.success : AppColors.warning,
    );
  }

  void _toast(String message, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final child = widget.child;
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                      child: const Icon(Icons.vaccines_rounded,
                          color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Record vaccination',
                              style: AppTextStyles.h3),
                          Text(
                              '${widget.child.name} • ${widget.child.code}',
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
              // Form
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.all(AppDimensions.spaceMD),
                  shrinkWrap: true,
                  children: [
                    // What the child already has, and who gave it. Shown
                    // before the picker so the worker decides against the
                    // record rather than from memory.
                    Consumer(
                      builder: (context, ref, _) {
                        final given =
                            ref.watch(vaccinationHistoryProvider(child.id));
                        final doses = (given.valueOrNull ?? const [])
                            .where((d) => d.status == DoseStatus.given)
                            .toList();
                        if (doses.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Already given'),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final d in doses)
                                  _GivenChip(
                                    vaccine: d.vaccine,
                                    date: d.date,
                                    by: d.administeredBy,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                        );
                      },
                    ),

                    _Label('Due now'),
                    const SizedBox(height: 6),
                    if (_options.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spaceMD),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMD),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 16, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${child.name} is up to date. Nothing is due '
                                'right now.',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _options.map((v) {
                          final selected = _vaccine == v;
                          return GestureDetector(
                            onTap: () => setState(() => _vaccine = v),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusFull),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.primary
                                          .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(v,
                                  style: AppTextStyles.caption.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 14),
                    _Label('Date administered'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickDate,
                      child: _FieldBox(
                        child: Row(
                          children: [
                            const Icon(Icons.event_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(_dateLabel,
                                style: AppTextStyles.bodySemibold),
                            const Spacer(),
                            const Icon(Icons.expand_more_rounded,
                                size: 16, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Label('Injection site'),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Left arm', 'Right arm', 'Oral', 'Thigh']
                          .map((s) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                  onTap: () => setState(() => _site = s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _site == s
                                          ? AppColors.primarySurface
                                          : AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusSM),
                                      border: Border.all(
                                        color: _site == s
                                            ? AppColors.primary
                                            : AppColors.borderMedium,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(s,
                                        style:
                                            AppTextStyles.caption.copyWith(
                                          color: _site == s
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10.5,
                                        )),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    _Label('Batch / lot number'),
                    const SizedBox(height: 6),
                    _FieldBox(
                      child: TextField(
                        controller: _batchCtrl,
                        style: AppTextStyles.bodySemibold,
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'e.g. PEN-3340',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Label('Notes (optional)'),
                    const SizedBox(height: 6),
                    _FieldBox(
                      child: TextField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        style: AppTextStyles.bodySmall,
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Any reactions or observations…',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Save bar
              Container(
                padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceMD, 9, AppDimensions.spaceMD, 9),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(
                      top: BorderSide(
                          color: AppColors.borderMedium, width: 1)),
                ),
                child: GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _saving
                          ? AppColors.primary.withValues(alpha: 0.6)
                          : AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save_rounded,
                                  size: 17, color: Colors.white),
                              const SizedBox(width: 7),
                              Text('Save record',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  )),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ));
  }
}

class _FieldBox extends StatelessWidget {
  final Widget child;
  const _FieldBox({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderMedium, width: 1),
      ),
      child: child,
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

// ── Already-given dose ───────────────────────────────────────────────────────
/// A dose the child already has. Read-only by design: the server refuses a
/// repeat with a 409, so showing it as selectable would only produce an error.
class _GivenChip extends StatelessWidget {
  final String vaccine;
  final String date;
  final String? by;

  const _GivenChip({required this.vaccine, required this.date, this.by});

  @override
  Widget build(BuildContext context) {
    final who = (by == null || by!.isEmpty) ? '' : ' · $by';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded,
                  size: 12, color: AppColors.success),
              const SizedBox(width: 4),
              Text(vaccine,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  )),
            ],
          ),
          Text('$date$who',
              style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
