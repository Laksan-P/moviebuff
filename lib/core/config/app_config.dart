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

  /// External JSON over the internet (master list of movies).
  ///
  /// Leave as the placeholder below until you upload your own movies.json
  /// to GitHub (or anywhere else). While it's a placeholder, the app will
  /// skip the network call and use the bundled JSON directly — no HTTP 404.
  static const String externalMoviesUrl = '<PLACEHOLDER>';
  // Example once you publish:
  // 'https://raw.githubusercontent.com/<owner>/<repo>/main/movies.json';

  /// Local bundled asset used as offline fallback when the network is down
  /// or the external URL is unreachable.
  static const String localMoviesAsset = 'assets/data/external_movies.json';

  /// HTTP timeout for network calls. Local dev Laravel can be slow.
  static const Duration httpTimeout = Duration(seconds: 20);

  // ------- helpers -------

  /// True when [externalMoviesUrl] is empty or still the placeholder.
  static bool get externalMoviesConfigured {
    final url = externalMoviesUrl.trim();
    if (url.isEmpty) return false;
    if (url.startsWith('<') && url.endsWith('>')) return false;
    if (!url.startsWith('http')) return false;
    return true;
  }
}
