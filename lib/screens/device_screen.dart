import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../providers/connectivity_provider.dart';
import '../providers/movie_provider.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../widgets/custom_button.dart';

enum _LocationDisplayMode { none, realGps, lastKnown, demo }

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  static const _profilePicKey = 'profile_pic_path';

  DeviceLocation? _location;
  _LocationDisplayMode _locationMode = _LocationDisplayMode.none;
  String? _locationError;

  String? _nearestTheatre;
  double? _nearestKm;

  BatteryInfo? _battery;
  StreamSubscription<BatteryState>? _batterySub;
  Timer? _batteryPoll;

  String? _profilePicPath;
  bool _loadingLocation = false;

  bool _testingApi = false;
  String? _apiTestResult;
  bool? _apiTestOk;

  @override
  void initState() {
    super.initState();
    _loadProfilePic();
    _refreshBattery();
    _batterySub =
        DeviceService.batteryStateStream().listen((_) => _refreshBattery());
    _batteryPoll =
        Timer.periodic(const Duration(seconds: 20), (_) => _refreshBattery());
  }

  @override
  void dispose() {
    _batterySub?.cancel();
    _batteryPoll?.cancel();
    super.dispose();
  }

  Future<void> _loadProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_profilePicKey);
    if (path != null && File(path).existsSync()) {
      setState(() => _profilePicPath = path);
    }
  }

  Future<void> _refreshBattery() async {
    final info = await DeviceService.getBattery();
    if (mounted) setState(() => _battery = info);
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

    final label =
        mode == _LocationDisplayMode.realGps ? 'Real GPS' : 'Last known';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label · nearest cinema: $_nearestTheatre '
            '(${_nearestKm?.toStringAsFixed(1)} km)'),
      ),
    );
  }

  void _useDemoCinemaLocation() {
    final loc = DeviceService.demoCinemaLocation();
    _applyCoordinates(loc, mode: _LocationDisplayMode.demo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demo location · nearest cinema: $_nearestTheatre '
          '(${_nearestKm?.toStringAsFixed(1)} km)',
        ),
      ),
    );
  }

  String get _locationStatusLabel {
    switch (_locationMode) {
      case _LocationDisplayMode.realGps:
        return 'Real GPS location';
      case _LocationDisplayMode.lastKnown:
        return 'Last known location';
      case _LocationDisplayMode.demo:
        return 'Demo location used for emulator testing';
      case _LocationDisplayMode.none:
        return '';
    }
  }

  Future<void> _capturePhoto({required bool fromCamera}) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = fromCamera
        ? await DeviceService.takePhoto()
        : await DeviceService.pickFromGallery();

    if (result.cancelled) {
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(fromCamera ? 'Camera cancelled' : 'Gallery cancelled'),
        ),
      );
      return;
    }

    if (result.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(result.errorMessage!)));
      return;
    }

    if (result.path == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilePicKey, result.path!);
    if (!mounted) return;
    setState(() => _profilePicPath = result.path);
    messenger.showSnackBar(
      const SnackBar(content: Text('Profile photo saved')),
    );
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
    if (!conn.isOnline) return 'Device Network: Offline';
    if (conn.status.contains(ConnectivityResult.wifi)) {
      return 'Device Network: Online via Wi-Fi';
    }
    if (conn.status.contains(ConnectivityResult.mobile)) {
      return 'Device Network: Online via Mobile data';
    }
    if (conn.status.contains(ConnectivityResult.ethernet)) {
      return 'Device Network: Online via Ethernet';
    }
    if (conn.status.contains(ConnectivityResult.vpn)) {
      return 'Device Network: Online via VPN';
    }
    return 'Device Network: Offline';
  }

  String _deviceNetworkSubtitle(ConnectivityProvider conn) {
    if (conn.isOnline) {
      return 'Whether this device has an active Wi‑Fi or cellular data path.';
    }
    return 'No Wi‑Fi or cellular data path detected on this device.';
  }

  String _sspApiTitle() {
    if (_apiTestOk == null) return 'SSP API: Not tested yet';
    if (_apiTestOk!) return 'SSP API: Reachable';
    return 'SSP API: Unreachable';
  }

  String _batteryStateLabel(BatteryState s) {
    switch (s) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Discharging';
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
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    final showAdbNote = !conn.isOnline && _apiTestOk == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Device',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
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
                      text: _testingApi ? 'Testing…' : 'Test SSP API Connection',
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
              title: _battery == null
                  ? 'Reading battery…'
                  : '${_battery!.level}%',
              subtitle: _battery == null
                  ? '—'
                  : _batteryStateLabel(_battery!.state),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Camera / Gallery Preview'),
            _card(
              icon: Icons.camera_alt_outlined,
              iconColor: Theme.of(context).colorScheme.primary,
              title: _profilePicPath == null
                  ? 'No image selected yet'
                  : p.basename(_profilePicPath!),
              subtitle: _profilePicPath == null
                  ? 'Capture or pick an image below.'
                  : '${_profilePicPath!}\nImage stored in app cache for demo.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  if (_profilePicPath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_profilePicPath!),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Camera',
                          onPressed: () => _capturePhoto(fromCamera: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Gallery',
                          isOutlined: true,
                          onPressed: () => _capturePhoto(fromCamera: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle('My Favorites (sqflite)'),
            if (movieProv.favorites.isEmpty)
              _card(
                icon: Icons.favorite_border,
                iconColor: Theme.of(context).colorScheme.primary,
                title: 'No favorites yet',
                subtitle:
                    'Open any movie and tap the heart icon to save it to the local sqflite DB.',
              )
            else
              ...movieProv.favorites.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _card(
                    icon: Icons.favorite,
                    iconColor: Theme.of(context).colorScheme.error,
                    title: m['title']?.toString() ?? '',
                    subtitle: m['genre']?.toString() ?? '',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard(BuildContext context) {
    final loc = _location;
    final hasCoords = loc != null;
    final iconColor = !hasCoords && _locationError != null
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    final body = <Widget>[];
    if (hasCoords) {
      body.addAll([
        Text(
          _locationStatusLabel,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Latitude: ${loc.latitude.toStringAsFixed(6)}',
          style: GoogleFonts.outfit(fontSize: 13),
        ),
        Text(
          'Longitude: ${loc.longitude.toStringAsFixed(6)}',
          style: GoogleFonts.outfit(fontSize: 13),
        ),
        if (_nearestTheatre != null && _nearestKm != null) ...[
          const SizedBox(height: 6),
          Text(
            'Nearest cinema: $_nearestTheatre '
            '(${_nearestKm!.toStringAsFixed(2)} km)',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ]);
    } else if (_locationError != null) {
      body.add(
        Text(
          _locationError!,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    } else {
      body.add(
        Text(
          'Use the buttons below for live GPS or a demo cinema location '
          'near Colombo, Sri Lanka.',
          style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
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
                  children: body,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: _loadingLocation ? 'Locating…' : 'Refresh real location',
            onPressed: _loadingLocation ? () {} : _refreshRealLocation,
            isLoading: _loadingLocation,
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Use demo cinema location',
            isOutlined: true,
            onPressed: _loadingLocation ? () {} : _useDemoCinemaLocation,
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
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
