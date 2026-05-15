import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/child_model.dart';

void showRecordVaccinationSheet(BuildContext context, ChildModel child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _RecordVaccinationSheet(child: child),
  );
}

class _RecordVaccinationSheet extends StatefulWidget {
  final ChildModel child;
  const _RecordVaccinationSheet({required this.child});

  @override
  State<_RecordVaccinationSheet> createState() =>
      _RecordVaccinationSheetState();
}

class _RecordVaccinationSheetState extends State<_RecordVaccinationSheet> {
  static const _allVaccines = [
    'BCG', 'OPV-0', 'OPV-1', 'OPV-2', 'OPV-3',
    'Penta-1', 'Penta-2', 'Penta-3',
    'Rota-1', 'Rota-2', 'PCV-1', 'PCV-2', 'PCV-3',
    'Measles-1', 'Measles-2', 'Yellow Fever',
  ];

  late String _vaccine;
  DateTime _date = DateTime.now();
  final _batchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _site = 'Left arm';

  @override
  void initState() {
    super.initState();
    _vaccine = widget.child.dueVaccines.isNotEmpty
        ? widget.child.dueVaccines.first
        : _allVaccines.first;
  }

  @override
  void dispose() {
    _batchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // Vaccine options — due ones first, then the rest.
  List<String> get _options {
    final due = widget.child.dueVaccines;
    final rest = _allVaccines.where((v) => !due.contains(v));
    return [...due, ...rest];
  }

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

  void _save() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$_vaccine recorded for ${widget.child.name}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
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
                              '${widget.child.name} • ${widget.child.id}',
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
                    _Label('Vaccine'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _options.map((v) {
                        final selected = _vaccine == v;
                        final due = widget.child.dueVaccines.contains(v);
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
                                    : (due
                                        ? AppColors.primary
                                            .withValues(alpha: 0.4)
                                        : AppColors.borderMedium),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (due) ...[
                                  Icon(Icons.circle,
                                      size: 6,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.primary),
                                  const SizedBox(width: 4),
                                ],
                                Text(v,
                                    style: AppTextStyles.caption.copyWith(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    )),
                              ],
                            ),
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
                  onTap: _save,
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: Row(
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
