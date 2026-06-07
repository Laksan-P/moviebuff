import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../providers/connectivity_provider.dart';
import '../providers/movie_provider.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/local_db_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/cinematic_background.dart';

enum _LocationDisplayMode { none, realGps, lastKnown }

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  DeviceLocation? _location;
  _LocationDisplayMode _locationMode = _LocationDisplayMode.none;
  String? _locationError;

  String? _nearestTheatre;
  double? _nearestKm;

  BatteryInfo? _battery;
  StreamSubscription<BatteryState>? _batterySub;
  Timer? _batteryPoll;

  bool _loadingLocation = false;

  bool _testingApi = false;
  String? _apiTestResult;
  bool? _apiTestOk;

  int _sqliteBookingsCount = 0;
  int _sqliteFavoritesCount = 0;
  int _sqliteCachedMoviesCount = 0;

  bool? _lastLoggedOnline;
  int? _lastLoggedFavoriteCount;
  ConnectivityProvider? _connectivityForLogListener;
  MovieProvider? _movieProvForLogListener;

  @override
  void initState() {
    super.initState();
    _refreshBattery();
    _loadSqliteStats();
    _batterySub = DeviceService.batteryStateStream().listen(
      (_) => _refreshBattery(),
    );
    _batteryPoll = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshBattery(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = context.read<ConnectivityProvider>();
      final m = context.read<MovieProvider>();
      _connectivityForLogListener = c;
      _movieProvForLogListener = m;
      c.addListener(_logNetworkAndFavoritesIfChanged);
      m.addListener(_logNetworkAndFavoritesIfChanged);
      _logNetworkAndFavoritesIfChanged();
    });
  }

  void _logNetworkAndFavoritesIfChanged() {
    if (!mounted) return;
    final conn = context.read<ConnectivityProvider>();
    final movieProv = context.read<MovieProvider>();
    if (_lastLoggedOnline != conn.isOnline) {
      _lastLoggedOnline = conn.isOnline;
      debugPrint('📡 DEVICE NETWORK - ${conn.isOnline ? 'Online' : 'Offline'}');
    }
    if (_lastLoggedFavoriteCount != movieProv.favorites.length) {
      _lastLoggedFavoriteCount = movieProv.favorites.length;
      debugPrint(
        '⭐ SQFLITE FAVORITES - loaded ${movieProv.favorites.length} favourites',
      );
    }
  }

  @override
  void dispose() {
    _connectivityForLogListener?.removeListener(
      _logNetworkAndFavoritesIfChanged,
    );
    _movieProvForLogListener?.removeListener(_logNetworkAndFavoritesIfChanged);
    _batterySub?.cancel();
    _batteryPoll?.cancel();
    super.dispose();
  }

  Future<void> _refreshBattery() async {
    final info = await DeviceService.getBattery();
    if (mounted) setState(() => _battery = info);
  }

  Future<void> _loadSqliteStats() async {
    final bookings = await LocalDbService.countAllBookings();
    final favorites = (await LocalDbService.getFavorites()).length;
    final cachedMovies = await LocalDbService.countCachedMovieRows();
    if (!mounted) return;
    setState(() {
      _sqliteBookingsCount = bookings;
      _sqliteFavoritesCount = favorites;
      _sqliteCachedMoviesCount = cachedMovies;
    });
    debugPrint(
      '🗄️ DEVICE SQLITE - bookings=$bookings favourites=$favorites '
      'cachedMovies=$cachedMovies',
    );
  }

  void _applyCoordinates(
    DeviceLocation loc, {
    required _LocationDisplayMode mode,
  }) {
    final near = DeviceService.findNearestSriLankanCinema(
      loc.latitude,
      loc.longitude,
    );
    setState(() {
      _location = loc;
      _locationMode = mode;
      _locationError = null;
      _nearestTheatre = near.name.isEmpty ? null : near.name;
      _nearestKm = near.name.isEmpty ? null : near.distanceKm;
      _loadingLocation = false;
    });
  }

  void _clearLocation({required String? error}) {
    setState(() {
      _location = null;
      _locationMode = _LocationDisplayMode.none;
      _locationError = error;
      _nearestTheatre = null;
      _nearestKm = null;
      _loadingLocation = false;
    });
  }

  Future<void> _refreshRealLocation() async {
    setState(() => _loadingLocation = true);

    final result = await DeviceService.acquireRealLocation();
    if (!mounted) return;

    if (!result.success) {
      _clearLocation(error: result.errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Location unavailable.'),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    final kind = result.kind;
    final mode = kind == LocationAcquireKind.realGps
        ? _LocationDisplayMode.realGps
        : _LocationDisplayMode.lastKnown;

    _applyCoordinates(result.location!, mode: mode);

    final label = mode == _LocationDisplayMode.realGps
        ? 'Live GPS'
        : 'Last known';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label · nearest cinema: $_nearestTheatre '
          '(${_nearestKm?.toStringAsFixed(1)} km)',
        ),
      ),
    );
  }

  String get _locationStatusLabel {
    switch (_locationMode) {
      case _LocationDisplayMode.realGps:
        return 'Source: live GPS';
      case _LocationDisplayMode.lastKnown:
        return 'Source: last known location';
      case _LocationDisplayMode.none:
        return '';
    }
  }

  Future<void> _testApi() async {
    setState(() {
      _testingApi = true;
      _apiTestResult = null;
      _apiTestOk = null;
    });
    final result = await ApiService.testConnection();
    if (!mounted) return;
    setState(() {
      _testingApi = false;
      _apiTestOk = result.ok;
      _apiTestResult = result.ok ? (result.data ?? 'OK') : result.error;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.ok
              ? 'SSP API: Reachable'
              : 'SSP API: Unreachable — ${result.error}',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _deviceNetworkTitle(ConnectivityProvider conn) {
    if (!conn.isOnline) return 'Offline Mode';
    return 'Online';
  }

  String _deviceNetworkSubtitle(ConnectivityProvider conn) {
    if (conn.isOnline) {
      return 'Laravel API is primary for movies, theatres, showtimes, and bookings.';
    }
    return 'Offline: Laravel catalogue falls back to sqflite cache, then '
        'offline_catalog.json. External movies use sqflite cache, then '
        'bundled external_movies.json.';
  }

  String _sspApiTitle() {
    if (_apiTestOk == null) return 'SSP API: Not tested yet';
    if (_apiTestOk!) return 'SSP API: Reachable';
    return 'SSP API: Unreachable';
  }

  String _batteryStateSubtitle(BatteryState s) {
    switch (s) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Not charging';
      case BatteryState.full:
        return 'Full';
      case BatteryState.connectedNotCharging:
        return 'Plugged in (not charging)';
      case BatteryState.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityProvider>();
    final movieProv = context.watch<MovieProvider>();
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    final showAdbNote = !conn.isOnline && _apiTestOk == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Device',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(
          alpha: 0.82,
        ),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CinematicBackground(),
          SafeArea(
            top: false,
            child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            _sectionTitle('Data sources'),
            _card(
              icon: Icons.account_tree_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'Multi-source architecture',
              subtitle: movieProv.sourceLabel,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Laravel API → movies, theatres, showtimes, bookings, CRUD\n'
                  'External JSON → read-only movie enrichment (merged list)\n'
                  'Local JSON + sqflite → offline fallback & favorites\n'
                  'SharedPreferences → auth token, theme & profile',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: muted,
                    height: 1.45,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Network'),
            _card(
              icon: conn.isOnline ? Icons.wifi : Icons.wifi_off,
              iconColor: conn.isOnline
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              title: _deviceNetworkTitle(conn),
              subtitle: _deviceNetworkSubtitle(conn),
            ),

            const SizedBox(height: 20),
            _sectionTitle('SSP API'),
            _card(
              icon: _apiTestOk == null
                  ? Icons.cloud_outlined
                  : (_apiTestOk! ? Icons.cloud_done : Icons.cloud_off),
              iconColor: _apiTestOk == null
                  ? Theme.of(context).colorScheme.primary
                  : (_apiTestOk!
                        ? const Color(0xFF10B981)
                        : Theme.of(context).colorScheme.error),
              title: _sspApiTitle(),
              subtitle: _apiTestResult == null
                  ? 'Base: ${AppConfig.apiBaseUrl} · timeout '
                        '${AppConfig.httpTimeout.inSeconds}s · tap to test.'
                  : _apiTestResult!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showAdbNote) ...[
                    const SizedBox(height: 10),
                    Text(
                      'API reachable through local USB/debug connection.',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: muted,
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: CustomButton(
                      text: _testingApi
                          ? 'Testing…'
                          : 'Test SSP API Connection',
                      onPressed: _testingApi ? () {} : _testApi,
                      isLoading: _testingApi,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Location'),
            _locationCard(context),

            const SizedBox(height: 20),
            _sectionTitle('Battery'),
            _card(
              icon: _batteryIcon(),
              iconColor: _battery == null
                  ? Theme.of(context).colorScheme.onSurface
                  : (_battery!.level < 20
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary),
              title: 'Battery status',
              subtitle: _battery == null
                  ? 'Reading battery…'
                  : '${_battery!.level}% · ${_batteryStateSubtitle(_battery!.state)}',
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Useful before long movie browsing or booking sessions.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: muted,
                    height: 1.35,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle('SQLite storage'),
            _card(
              icon: Icons.storage_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'Local database stats',
              subtitle:
                  'Bookings $_sqliteBookingsCount · Favourites $_sqliteFavoritesCount · Cached movies $_sqliteCachedMoviesCount',
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'SQLite bookings: external JSON / offline demo only.\n'
                  'Laravel API remains authoritative for API bookings.',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: muted,
                    height: 1.45,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Saved favourites'),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Profile photo capture is available from the Profile tab.',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: muted,
                  height: 1.35,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (movieProv.favorites.isEmpty)
              _card(
                icon: Icons.favorite_border,
                iconColor: Theme.of(context).colorScheme.primary,
                title: 'No favourites yet',
                subtitle: 'Tap the heart icon on any movie to save it locally.',
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Stored using sqflite for offline access.',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: muted,
                      height: 1.35,
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Stored using sqflite for offline access.',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: muted,
                        height: 1.35,
                      ),
                    ),
                  ),
                  ...movieProv.favorites.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _card(
                        icon: Icons.favorite,
                        iconColor: Theme.of(context).colorScheme.error,
                        title: m['title']?.toString() ?? '',
                        subtitle: () {
                          final g = m['genre']?.toString().trim();
                          return (g != null && g.isNotEmpty)
                              ? g
                              : 'Genre not listed';
                        }(),
                      ),
                    ),
                  ),
                ],
              ),
          ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard(BuildContext context) {
    final loc = _location;
    final hasCoords = loc != null;
    final iconColor = !hasCoords && _locationError != null
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    List<Widget> headerContent;
    if (hasCoords) {
      headerContent = [
        Text(
          'Nearest cinema: ${_nearestTheatre ?? '—'}',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Distance: ${_nearestKm?.toStringAsFixed(1) ?? '—'} km',
          style: GoogleFonts.outfit(fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 4),
        SelectableText(
          'Lat/Lng: ${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}',
          style: GoogleFonts.outfit(fontSize: 13, height: 1.35),
        ),
        if (_locationStatusLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _locationStatusLabel,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ];
    } else if (_locationError != null) {
      headerContent = [
        Text(
          'Find nearest cinema',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          _locationError!,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Theme.of(context).colorScheme.error,
            height: 1.35,
          ),
        ),
      ];
    } else {
      headerContent = [
        Text(
          'Find nearest cinema',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'Use your location to suggest the closest MovieBuff theatre.',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.35,
          ),
        ),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_outlined, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: headerContent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: _loadingLocation ? 'Locating…' : 'Find nearest cinema',
            onPressed: _loadingLocation ? () {} : _refreshRealLocation,
            isLoading: _loadingLocation,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    ),
  );

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.25,
                      ),
                      softWrap: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.35,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (child != null) child,
        ],
      ),
    );
  }

  IconData _batteryIcon() {
    if (_battery == null) return Icons.battery_unknown;
    if (_battery!.state == BatteryState.charging) {
      return Icons.battery_charging_full;
    }
    if (_battery!.level < 20) return Icons.battery_alert;
    if (_battery!.level < 50) return Icons.battery_3_bar;
    if (_battery!.level < 90) return Icons.battery_5_bar;
    return Icons.battery_full;
  }
}
