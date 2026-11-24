import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Shown while the stored session and its profile are checked at startup.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 3, color: context.tokens.accent),
        ),
      ),
    );
  }
}
