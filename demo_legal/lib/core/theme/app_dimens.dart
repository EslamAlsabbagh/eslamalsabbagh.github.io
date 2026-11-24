/// Radii from `docs/design/DESIGN_SPEC.md` §1 "Shape & spacing".
abstract final class AppRadii {
  static const double row = 12;
  static const double card = 14;
  static const double button = 10;
  static const double input = 10;
  static const double tabTrack = 12;
  static const double tab = 9;
  static const double modal = 16;
  static const double flag = 6;
  static const double pill = 999;
}

/// Spacing, sizes and breakpoints from `docs/design/DESIGN_SPEC.md` §1 and §5.
abstract final class AppSpacing {
  static const double contentMaxWidth = 1200;
  static const double sidePadding = 20;

  static const double rowGap = 8;
  static const double sectionGap = 30;
  static const double rowPaddingV = 14;
  static const double rowPaddingH = 16;
  static const double cardPadding = 16;

  /// Forms, from the new-task modal: padding 20, 16 between fields,
  /// 6 between a label and its input.
  static const double modalPadding = 20;
  static const double formGap = 16;
  static const double labelGap = 6;

  /// Task drawer: at most this wide (full width on a phone), padding 20,
  /// 22 between its blocks.
  static const double drawerMaxWidth = 520;
  static const double drawerPadding = 20;
  static const double drawerGap = 22;

  static const double touchTarget = 44;
  static const double chipHeight = 40;

  /// Below this width the layout is a single column.
  static const double mobileBreakpoint = 720;
}
