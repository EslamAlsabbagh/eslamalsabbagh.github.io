import 'package:flutter/material.dart';

/// Reusable form field label with consistent styling
class FormFieldLabel extends StatelessWidget {
  final String text;
  final bool hasError;
  final bool required;

  const FormFieldLabel({super.key, required this.text, this.hasError = false, this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: hasError ? Colors.red : Theme.of(context).primaryColor,
        ),
        children: [
          TextSpan(text: text),
          if (required) TextSpan(text: ' *', style: TextStyle(color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }
}

/// Styled text field with consistent borders and colors
class StyledTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool hasError;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool obscureText;
  final VoidCallback? onTap;
  final bool readOnly;
  final MouseCursor mouseCursor;

  const StyledTextField({
    super.key,
    this.controller,
    this.hintText,
    this.hasError = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.keyboardType,
    this.enabled = true,
    this.obscureText = false,
    this.onTap,
    this.readOnly = false,
    this.mouseCursor = SystemMouseCursors.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      mouseCursor: mouseCursor,
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
            width: hasError ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
            width: hasError ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hasError ? Colors.red : Theme.of(context).primaryColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.withValues(alpha: 0.05) : null,
      ),
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
    );
  }
}

/// Form field with label, field, and error message
class FormFieldWithLabel extends StatelessWidget {
  final String label;
  final Widget field;
  final String? errorMessage;
  final bool required;

  const FormFieldWithLabel({
    super.key,
    required this.label,
    required this.field,
    this.errorMessage,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: label, hasError: hasError, required: required),
        const SizedBox(height: 8),
        field,
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }
}

/// Container with consistent card styling for forms
class FormContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Widget? header;

  const FormContainer({super.key, required this.child, this.padding, this.header});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (header != null) ...[header!, const SizedBox(height: 24)],
          child,
        ],
      ),
    );
  }
}

/// Form header with icon and title
class FormHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;

  const FormHeader({super.key, required this.icon, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final headerColor = color ?? Theme.of(context).primaryColor;

    return Row(
      children: [
        Icon(icon, color: headerColor, size: 24),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: headerColor)),
      ],
    );
  }
}

/// Read-only field with consistent styling (like in advance on salary)
class ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool required;

  const ReadOnlyField({super.key, required this.label, required this.value, required this.icon, this.required = false});

  @override
  Widget build(BuildContext context) {
    return FormFieldWithLabel(
      label: label,
      required: required,
      field: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(value, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
