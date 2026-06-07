/// Central configuration. Update these URLs to point at your own backend
/// and your own external movies JSON.
class AppConfig {
  /// Laravel SSP API base URL (Jetstream + Sanctum token endpoints).
  ///
  /// **Edit this one line** to match how you run the server and how the device
  /// reaches your laptop/PC:
  ///
  /// - **Android emulator** (API on host machine): use the special alias to
  ///   the host loopback — e.g. `http://10.0.2.2:8000/api` (not `127.0.0.1`
  ///   on the emulator; that points inside the emulator itself).
  ///
  /// - **Real phone + USB + `adb reverse`** (forward host port to phone): you
  ///   can use `http://127.0.0.1:8000/api` on the device **after** running
  ///   something like: `adb reverse tcp:8000 tcp:8000`.
  ///
  /// - **Real phone on same Wi-Fi** (no adb reverse): use your computer's LAN
  ///   IP — e.g. `http://192.168.1.5:8000/api` (replace with `ipconfig` /
  ///   `ifconfig` / Settings value for your machine).
  ///
  /// Keep the `/api` suffix if your Laravel routes are under that prefix.
  static const String apiBaseUrl = "http://127.0.0.1:8000/api";

  /// External JSON over the internet (read-only movie catalogue enrichment).
  ///
  /// When set to a valid `http(s)` URL, the app fetches this list first, then
  /// falls back to **sqflite cache**, then **bundled** [localMoviesAsset].
  static const String externalMoviesUrl =
      'https://raw.githubusercontent.com/Laksan-P/moviebuff/main/external_movies.json';

  /// Local bundled asset used as offline fallback when the network is down
  /// or the external URL is unreachable.
  static const String localMoviesAsset = 'assets/data/external_movies.json';

  /// Offline fallback for core catalogue when Laravel API is unreachable.
  /// Shape: `{ "movies": [], "theatres": [], "showtimes": [] }`.
  static const String localOfflineCatalogAsset =
      'assets/data/offline_catalog.json';

  /// HTTP timeout for network calls. Local dev Laravel can be slow.
  static const Duration httpTimeout = Duration(seconds: 20);

  // ------- helpers -------

  static bool _isHttpUrl(String url) {
    final u = url.trim();
    if (u.isEmpty) return false;
    if (u.startsWith('<') && u.endsWith('>')) return false;
    return u.startsWith('http');
  }

  /// True when [externalMoviesUrl] is a valid HTTP(S) URL.
  static bool get externalMoviesConfigured => _isHttpUrl(externalMoviesUrl);
}
