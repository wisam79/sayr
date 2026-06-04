/// Arabic duration formatting helpers.
///
/// `intl.DurationFormat` was removed in 0.19+, so we provide a small helper
/// for the only shape we render: "X ساعة Y دقيقة" / "X دقيقة".
library;

/// Format a [Duration] in Arabic (e.g. "2 ساعة 15 دقيقة" or "45 دقيقة").
String formatDurationAr(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours > 0) return '$hours ساعة $minutes دقيقة';
  return '$minutes دقيقة';
}
