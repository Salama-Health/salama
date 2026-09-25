import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Labelled input used across the registration and settings forms.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool required;
  final bool obscure;
  final String? suffixText;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.required = false,
    this.obscure = false,
    this.suffixText,
    this.capitalization = TextCapitalization.words,
    this.onChanged,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() {
      if (_node.hasFocus != _focused) {
        setState(() => _focused = _node.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? AppColors.errorMid
        : _focused
            ? AppColors.primary
            : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label, style: AppTextStyles.h4),
            if (widget.required)
              Text(' *',
                  style: AppTextStyles.h4.copyWith(color: AppColors.riskHigh)),
          ],
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(
              color: borderColor,
              width: _focused || hasError
                  ? AppDimensions.borderMedium
                  : AppDimensions.borderNormal,
            ),
          ),
          child: Row(
            crossAxisAlignment: widget.maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (widget.icon != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      11, widget.maxLines > 1 ? 13 : 0, 0, 0),
                  child: Icon(widget.icon,
                      size: 17,
                      color:
                          _focused ? AppColors.primary : AppColors.textTertiary),
                ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _node,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  maxLines: widget.maxLines,
                  obscureText: widget.obscure,
                  textCapitalization: widget.capitalization,
                  onChanged: widget.onChanged,
                  style: AppTextStyles.bodyLarge,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.textMuted),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(
                        widget.icon != null ? 9 : 13, 13, 13, 13),
                  ),
                ),
              ),
              if (widget.suffixText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 13),
                  child: Text(widget.suffixText!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
                ),
            ],
          ),
        ),
        if (hasError || widget.helper != null) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasError
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                size: 12,
                color: hasError ? AppColors.error : AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.errorText ?? widget.helper!,
                  style: AppTextStyles.captionMuted.copyWith(
                    color: hasError ? AppColors.error : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Rounded search box used on Visits and the manual-entry sheet.
class AppSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search',
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
            color: AppColors.borderLight, width: AppDimensions.borderNormal),
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          const Icon(Icons.search_rounded,
              size: 17, color: AppColors.textTertiary),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
              cursorColor: AppColors.primary,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox(width: 13)
                : GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                      onClear?.call();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 11),
                      child: Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textTertiary),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
