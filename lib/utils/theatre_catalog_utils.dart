/// Builds customer theatre lists from external-catalogue movies (Sri Lanka first).
class TheatreCatalogUtils {
  TheatreCatalogUtils._();

  /// Normalizes theatre names for matching (case, unicode dashes, spaces).
  static String normalizeTheatreKey(String name) {
    return name
        .toLowerCase()
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Default address when JSON has no per-row address; covers known SL venues.
  static String locationForTheatreName(String displayName) {
    final k = normalizeTheatreKey(displayName);

    if (k.contains('scope') &&
        (k.contains('multiplex') || k.contains('colombo city'))) {
      return 'Colombo City Centre, Colombo';
    }
    if (k.contains('pvr') && k.contains('galle face')) {
      return 'One Galle Face Mall, Colombo';
    }
    if (k.contains('liberty') && k.contains('cinema')) {
      return 'Kollupitiya, Colombo';
    }
    if (k.contains('liberty') && k.contains('scope')) {
      return 'Kollupitiya, Colombo';
    }
    if (k.contains('savoy') &&
        (k.contains('wellawat') || k.contains('wellawatte'))) {
      return 'Wellawatte, Colombo';
    }
    if (k.contains('regal') && k.contains('colombo')) {
      return 'Slave Island, Colombo';
    }
    if (k.contains('kcc') && k.contains('kandy')) {
      return 'Kandy City Centre, Kandy';
    }

    return 'Colombo, Sri Lanka';
  }

  /// Unique theatres from movie rows (`theatre` field). Sorted by name.
  /// Optional `theatreLocation` in JSON overrides the mapped default.
  static List<Map<String, dynamic>> buildTheatresFromMovies(
    List<Map<String, dynamic>> movies,
  ) {
    final byKey = <String, String>{};
    final locations = <String, String?>{};

    for (final m in movies) {
      final theatre = (m['theatre']?.toString() ?? '').trim();
      if (theatre.isEmpty) continue;

      final key = normalizeTheatreKey(theatre);
      byKey.putIfAbsent(key, () => theatre);

      final loc = m['theatreLocation']?.toString().trim();
      if (loc != null && loc.isNotEmpty) {
        locations[key] = loc;
      }
    }

    final out = byKey.entries
        .map(
          (e) => <String, dynamic>{
            'name': e.value,
            'location':
                locations[e.key] ?? locationForTheatreName(e.value),
          },
        )
        .toList();
    out.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return out;
  }
}
