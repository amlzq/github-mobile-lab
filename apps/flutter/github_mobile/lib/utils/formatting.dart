/// Shared display formatters for search results.
library;

/// Formats a count the way GitHub mobile does: `812`, `8.8k`, `23k`, `1.2m`.
String formatCompactCount(int count) {
  if (count < 1000) return '$count';
  final k = count / 1000;
  if (k < 10) return '${k.toStringAsFixed(1)}k';
  if (k < 1000) return '${k.round()}k';
  final m = k / 1000;
  if (m < 10) return '${m.toStringAsFixed(1)}m';
  return '${m.round()}m';
}

/// Compact relative time used by result rows: `now`, `5m`, `3d`, `2mo`, `1y`.
String timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 30) return '${diff.inDays}d';
  final months = (diff.inDays / 30).round();
  if (months < 12) return '${months}mo';
  return '${(months / 12).round()}y';
}
