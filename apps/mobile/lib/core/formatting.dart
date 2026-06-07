/// Duration formatting helper.
///
/// `intl.DurationFormat` was removed in 0.19+, so we provide a small helper
/// for building duration strings using l10n placeholders.
library;

import 'package:sayr_mobile/l10n/app_localizations.dart';

/// Format a [Duration] using localized [AppLocalizations].
///
/// Returns e.g. "2 ساعة 15 دقيقة" or "45 دقيقة" in Arabic.
String formatDurationAr(AppLocalizations l10n, Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours > 0) return l10n.durationHoursMinutes(hours, minutes);
  return l10n.durationMinutesOnly(minutes);
}
