import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.validator,
    this.autofocus = true,
    this.width,
    this.onChanged,
    this.isReasonField = false,
    this.hint,
    this.autofillHints,
    this.focusNode,
    this.textInputAction,
    this.inputFormatters,
  });

  final String? label;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final double? width;
  final bool isReasonField;
  final String? hint;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? context.maxInputWidth,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        obscureText: _obscureText,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        onChanged: widget.onChanged,
        autofillHints: widget.autofillHints,
        validator:
            widget.validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context)!.fieldRequired;
              }

              // Apply reason field validation if isReasonField is true
              if (widget.isReasonField) {
                final trimmedValue = value.trim();
                if (trimmedValue.length < 25) {
                  return AppLocalizations.of(context)!.reasonMinimum25;
                }
              }

              return null;
            },
        decoration: InputDecoration(
          labelText: widget.label,
          hint: Text(widget.hint ?? ''),
          border: OutlineInputBorder(),
          suffixIcon:
              widget.obscureText
                  ? IconButton(
                    iconSize: 18,
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                    onPressed: _togglePasswordVisibility,
                  )
                  : null,
        ),
      ),
    );
  }
}
