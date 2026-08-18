import 'package:hrms_demo/l10n/locale_cubit.dart';
import 'package:hrms_demo/presentation/widgets/sidebar_navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageToggleWidget extends StatelessWidget {
  final double? width;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? borderColor;
  final Color? textColor;
  final Color? backgroundColor;
  final double? borderRadius;
  final FontWeight? fontWeight;
  final double? fontSize;
  final Function? onTap;

  const LanguageToggleWidget({
    super.key,
    this.width = 150,
    this.padding = const EdgeInsets.all(8),
    this.margin,
    this.borderColor,
    this.textColor,
    this.backgroundColor = Colors.transparent,
    this.borderRadius = 8,
    this.fontWeight = FontWeight.w500,
    this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            // Freeze sidebar state before changing locale
            context.read<SidebarNavigationCubit>().freezeState();
            context.read<LocaleCubit>().toggleLocale();
          }
        },
        child: Container(
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
            border: Border.all(color: borderColor ?? Colors.blue[200]!),
          ),
          child: Center(
            child: Text(
              Localizations.localeOf(context).languageCode == 'en' ? 'عربي' : 'English',
              style: TextStyle(color: textColor ?? Colors.blue, fontWeight: fontWeight, fontSize: fontSize),
            ),
          ),
        ),
      ),
    );
  }
}
