import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Lowercased location names (as stored on the request) that entitle the
/// employee to transportation fees.
///
/// Add/remove entries here to change which business-trip locations qualify.
/// Locations are stored locale-dependently — historically as the English enum
/// label (e.g. "NORTH SQUARE") but sometimes as the localized Arabic label
/// (e.g. "نورث سكوير") — so list every stored spelling of each qualifying
/// location. Comparison is case-insensitive via [locationDeservesTransportationFees].
///
/// KEEP IN SYNC with TRANSPORTATION_FEE_LOCATIONS in
/// supabase/functions/_shared/transportation-fees.ts
const List<String> kTransportationFeeLocations = ['north square', 'نورث سكوير'];

/// Whether [location] (the stored business-trip location string) entitles the
/// employee to transportation fees.
bool locationDeservesTransportationFees(String? location) =>
    location != null && kTransportationFeeLocations.contains(location.trim().toLowerCase());

enum BusinessTrips {
  riverside(label: "RIVERSIDE"),
  riversidePark(label: "RIVERSIDE PARK"),
  north(label: "NORTH SQUARE"),
  other(label: "Other");

  final String label;

  const BusinessTrips({required this.label});
  String localizedLabel(BuildContext context) {
    switch (this) {
      case BusinessTrips.riverside:
        return AppLocalizations.of(context)!.riverside;
      case BusinessTrips.riversidePark:
        return AppLocalizations.of(context)!.riversidePark;
      case BusinessTrips.north:
        return AppLocalizations.of(context)!.northSquare;
      case BusinessTrips.other:
        return AppLocalizations.of(context)!.other;
    }
  }
}
