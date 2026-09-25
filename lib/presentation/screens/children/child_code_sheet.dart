import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/child_model.dart';
import '../../providers/core_providers.dart';
import '../scan/scanned_child_sheet.dart';

/// Look a child up by the code on their card, typed in.
///
/// Replaces the camera scanner: a code entered by hand works on any handset,
/// in poor light, with a worn or photocopied card, and with no camera
/// permission - all common in the field, and each one a case where scanning
/// simply fails.
void showChildCodeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => const _ChildCodeSheet(),
  );
}

class _ChildCodeSheet extends ConsumerStatefulWidget {
  const _ChildCodeSheet();

  @override
  ConsumerState<_ChildCodeSheet> createState() => _ChildCodeSheetState();
}

class _ChildCodeSheetState extends ConsumerState<_ChildCodeSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _looking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The worker opened this to type; give them the keyboard without a tap.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty || _looking) return;

    // Cards printed for the scanner carry a SALAMA:CHILD: prefix. A worker
    // reading the code off the card should not have to know that.
    final code = raw.replaceFirst(RegExp(r'^SALAMA:CHILD:', caseSensitive: false), '');

    setState(() {
      _looking = true;
      _error = null;
    });

    ChildModel child;
    try {
      child = await ref.read(childrenRepositoryProvider).lookupByQr(code);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _looking = false;
        _error = e.statusCode == 404
            ? 'No child has the code "$code". Check the card and try again.'
            : e.message;
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _looking = false;
        _error = 'Could not look that up. $e';
      });
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
    showScannedChildSheet(context, child);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
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
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimensions.screenPadding,
                    0,
                    AppDimensions.screenPadding,
                    AppDimensions.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find a child',
                        style: AppTextStyles.h3
                            .copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Enter the code printed on the child\'s card.',
                        style: AppTextStyles.captionMuted),
                    const SizedBox(height: AppDimensions.spaceLG),
                    TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _lookup(),
                      inputFormatters: [
                        // Codes are printed uppercase; accepting lower case and
                        // normalising avoids a "not found" that is really a
                        // keyboard problem.
                        TextInputFormatter.withFunction((_, next) =>
                            next.copyWith(text: next.text.toUpperCase())),
                      ],
                      style: AppTextStyles.bodyLargeSemibold
                          .copyWith(letterSpacing: 1.2),
                      decoration: InputDecoration(
                        hintText: 'C-00001',
                        hintStyle: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        prefixIcon: const Icon(Icons.tag_rounded,
                            size: 18, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMD),
                          borderSide: const BorderSide(
                              color: AppColors.borderMedium, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMD),
                          borderSide: const BorderSide(
                              color: AppColors.borderMedium, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMD),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.4),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppDimensions.spaceSM),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 15, color: AppColors.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_error!,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.error)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spaceLG),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _looking ? null : _lookup,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMD),
                          ),
                        ),
                        child: _looking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Find child',
                                style: AppTextStyles.buttonMedium
                                    .copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
