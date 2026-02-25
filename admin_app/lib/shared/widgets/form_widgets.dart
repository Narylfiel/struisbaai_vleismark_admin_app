import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// Reusable form widgets for consistent UI across the app
class FormWidgets {
  /// Primary text form field
  static Widget textFormField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? helperText,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLines = 1,
    int? maxLength,
    bool enabled = true,
    Widget? prefixIcon,
    Widget? suffixIcon,
    VoidCallback? onTap,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          onTap: onTap,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Dropdown form field
  static Widget dropdownFormField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    String? hint,
    String? helperText,
    String? Function(T?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Date picker form field
  static Widget dateFormField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
    String? hint,
    String? helperText,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return FormWidgets.textFormField(
      label: label,
      controller: controller,
      hint: hint ?? 'Select date',
      helperText: helperText,
      validator: validator,
      enabled: enabled,
      suffixIcon: const Icon(
        Icons.calendar_today,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(2000),
                lastDate: lastDate ?? DateTime(2100),
              );
              if (picked != null) {
                controller.text = '${picked.day.toString().padLeft(2, '0')}/'
                    '${picked.month.toString().padLeft(2, '0')}/'
                    '${picked.year}';
              }
            }
          : null,
    );
  }

  /// Time picker form field
  static Widget timeFormField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
    String? hint,
    String? helperText,
    TimeOfDay? initialTime,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return FormWidgets.textFormField(
      label: label,
      controller: controller,
      hint: hint ?? 'Select time',
      helperText: helperText,
      validator: validator,
      enabled: enabled,
      suffixIcon: const Icon(
        Icons.access_time,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onTap: enabled
          ? () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: initialTime ?? TimeOfDay.now(),
              );
              if (picked != null) {
                controller.text = '${picked.hour.toString().padLeft(2, '0')}:'
                    '${picked.minute.toString().padLeft(2, '0')}';
              }
            }
          : null,
    );
  }

  /// Numeric input field
  static Widget numericFormField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? helperText,
    int? min,
    int? max,
    String? Function(String?)? validator,
    bool enabled = true,
    bool allowDecimals = false,
  }) {
    return FormWidgets.textFormField(
      label: label,
      controller: controller,
      hint: hint,
      helperText: helperText,
      keyboardType: allowDecimals ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimals ? RegExp(r'^\d*\.?\d*$') : RegExp(r'^\d*$'),
        ),
      ],
      validator: (value) {
        if (validator != null) {
          final result = validator(value);
          if (result != null) return result;
        }

        if (value != null && value.isNotEmpty) {
          final numValue = allowDecimals ? double.tryParse(value) : int.tryParse(value);
          if (numValue == null) {
            return 'Please enter a valid number';
          }
          if (min != null && numValue < min) {
            return 'Value must be at least $min';
          }
          if (max != null && numValue > max) {
            return 'Value must be at most $max';
          }
        }
        return null;
      },
      enabled: enabled,
    );
  }

  /// Currency input field
  static Widget currencyFormField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? helperText,
    double? min,
    double? max,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return FormWidgets.textFormField(
      label: label,
      controller: controller,
      hint: hint ?? '0.00',
      helperText: helperText,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      validator: (value) {
        if (validator != null) {
          final result = validator(value);
          if (result != null) return result;
        }

        if (value != null && value.isNotEmpty) {
          final numValue = double.tryParse(value);
          if (numValue == null) {
            return 'Please enter a valid amount';
          }
          if (min != null && numValue < min) {
            return 'Amount must be at least R${min.toStringAsFixed(2)}';
          }
          if (max != null && numValue > max) {
            return 'Amount must be at most R${max.toStringAsFixed(2)}';
          }
        }
        return null;
      },
      enabled: enabled,
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: 16, right: 8),
        child: Text(
          'R',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Checkbox form field
  static Widget checkboxFormField({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
    String? helperText,
    bool enabled = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: AppColors.primary,
          checkColor: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (helperText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    helperText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Switch form field
  static Widget switchFormField({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    String? helperText,
    bool enabled = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (helperText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    helperText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withOpacity(0.3),
        ),
      ],
    );
  }

  /// Form section divider
  static Widget formSection({
    required String title,
    String? subtitle,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(vertical: 16),
  }) {
    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
        ],
      ),
    );
  }
}