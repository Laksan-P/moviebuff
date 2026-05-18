/// Safe string/date helpers for admin UI (avoid RangeError on substring, etc.).
class TextSafety {
  TextSafety._();

  static String safeBookingIdSuffix(dynamic id, {int tailLength = 6}) {
    final s = id?.toString().trim() ?? '';
    if (s.isEmpty) return '#N/A';
    if (s.length <= tailLength) return '#$s';
    return '#${s.substring(s.length - tailLength)}';
  }

  static String safeInitials(String? name) {
    final parts =
        (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return 'U';

    final a = list[0];
    if (list.length == 1) {
      return a.isNotEmpty ? a[0].toUpperCase() : 'U';
    }
    final b = list[1];
    return '${a[0]}${b[0]}'.toUpperCase();
  }

  static String safeShortText(
    String? text,
    int maxLength, {
    String fallback = 'N/A',
  }) {
    final s = (text ?? '').trim();
    if (s.isEmpty) return fallback;
    if (maxLength <= 0) return fallback;
    if (s.length <= maxLength) return s;
    return '${s.substring(0, maxLength)}…';
  }

  static String safeDateText(DateTime? date, {String fallback = '-'}) {
    if (date == null) return fallback;
    try {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return fallback;
    }
  }
}
