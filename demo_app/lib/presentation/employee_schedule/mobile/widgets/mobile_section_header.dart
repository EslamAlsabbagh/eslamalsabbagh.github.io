import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:flutter/material.dart';

/// Horizontal section label row with an optional action link on the trailing side.
class MobileSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const MobileSectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MT.text3, letterSpacing: 0.4),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MT.brand)),
            ),
        ],
      ),
    );
  }
}
