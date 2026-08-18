import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Approve / Decline pair for one row of a server-paged request table.
///
/// Reads the in-flight id from the bloc HERE, inside the row's own subtree,
/// rather than taking a bool from the data source. That is not a style choice:
/// an `AsyncDataTableSource` materialises every `DataRow` at fetch time and
/// caches the result, so a flag captured there cannot change again until the
/// next fetch. A selector in the subtree rebuilds in place on a bloc emit, with
/// no extra round trip.
///
/// Generic over the bloc so every request type can share it. Each screen passes
/// an [isProcessing] predicate that reads whichever of its own processing-id
/// fields applies to the row — trip vs cancellation ids live in different id
/// spaces, so the caller, not this widget, decides which one to match.
///
/// Used by the leave screens (`user_requests_content.dart`) and the
/// business-trip screens (`user_businesstrip_requests_content.dart`).
class RowApproveDeclineActions<B extends StateStreamable<S>, S> extends StatelessWidget {
  const RowApproveDeclineActions({
    super.key,
    required this.isProcessing,
    required this.onApprove,
    required this.onDecline,
    this.legacyIsLoading = false,
  });

  /// True when this row is the one currently being mutated.
  final bool Function(S state) isProcessing;

  final VoidCallback onApprove;
  final VoidCallback onDecline;

  /// The client-paged path's whole-source loading flag, kept so that path
  /// behaves exactly as it did before.
  final bool legacyIsLoading;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<B, S, bool>(
      selector: isProcessing,
      builder: (context, processing) {
        // ONE spinner for the pair, not `isLoading:` on both buttons: two
        // spinners would imply two operations, and the cell would jump from the
        // pair's ~176px to ~72px. The SizedBox holds that width so the column
        // does not resize mid-flight. Replacing both buttons also removes any
        // target for a second tap, which the full-screen overlay used to block
        // implicitly.
        if (processing || legacyIsLoading) {
          return const SizedBox(
            width: 176,
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppButton(
              width: 80,
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.all(4),
              onPressed: onApprove,
              label: AppLocalizations.of(context)!.approve,
              color: Colors.green,
            ),
            AppButton(
              width: 80,
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.all(4),
              label: AppLocalizations.of(context)!.decline,
              onPressed: onDecline,
              color: Colors.redAccent,
            ),
          ],
        );
      },
    );
  }
}
