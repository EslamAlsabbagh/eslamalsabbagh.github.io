import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../tasks/view/widgets/confirm_dialog.dart';
import '../../bloc/contract_export_bloc.dart';

/// «تصدير» at the `end` of the filter row (DESIGN_SPEC §4 View 4 "Export
/// and print"): a quiet outline button whose menu holds «تنزيل ملف Excel»
/// and «طباعة». [onSelected] null disables it (the list is loading, or
/// shows nothing). While an export runs, a small spinner takes the icon's
/// place; a failure shows «تعذّر تصدير العقود.».
class ContractExportMenu extends StatelessWidget {
  const ContractExportMenu({super.key, required this.onSelected});

  final ValueChanged<ContractExportFormat>? onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<ContractExportBloc, ContractExportState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && current.status == ContractExportStatus.failed,
      listener: (context, _) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.contractExportError))),
      builder: (context, state) {
        final select = state.working ? null : onSelected;
        return MenuAnchor(
          menuChildren: [
            MenuItemButton(
              key: const Key('contract-export-xlsx'),
              leadingIcon: const Icon(Icons.table_view_outlined, size: 20),
              onPressed: select == null ? null : () => select(ContractExportFormat.xlsx),
              child: Text(l10n.contractExportXlsx, style: AppTextStyles.body.copyWith(color: tokens.ink)),
            ),
            MenuItemButton(
              key: const Key('contract-export-print'),
              leadingIcon: const Icon(Icons.print_outlined, size: 20),
              onPressed: select == null ? null : () => select(ContractExportFormat.print),
              child: Text(l10n.contractExportPrint, style: AppTextStyles.body.copyWith(color: tokens.ink)),
            ),
          ],
          builder: (context, controller, _) => OutlinedButton.icon(
            key: const Key('contract-export'),
            onPressed: select == null ? null : () => controller.isOpen ? controller.close() : controller.open(),
            style: quietOutlineButtonStyle(context).copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(0, AppSpacing.chipHeight)),
              padding: const WidgetStatePropertyAll(EdgeInsetsDirectional.symmetric(horizontal: 14)),
            ),
            icon: state.working
                ? SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: tokens.accent),
                  )
                : const Icon(Icons.file_download_outlined, size: 18),
            label: Text(l10n.contractExport),
          ),
        );
      },
    );
  }
}
