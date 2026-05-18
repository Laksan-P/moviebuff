import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class DeviceLocation {
  final double latitude;
  final double longitude;
  DeviceLocation(this.latitude, this.longitude);

  @override
  String toString() =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

/// How a coordinate was obtained (real GPS path only; demo is UI-only).
enum LocationAcquireKind { none, realGps, lastKnown }

class LocationResult {
  final DeviceLocation? location;
  final String? errorMessage;
  final bool servicesEnabled;
  final LocationPermission permission;
  final LocationAcquireKind kind;

  LocationResult({
    this.location,
    this.errorMessage,
    required this.servicesEnabled,
    required this.permission,
    this.kind = LocationAcquireKind.none,
  });

  bool get success => location != null;
}

class CameraResult {
  final String? path;
  final bool cancelled;
  final String? errorMessage;
  CameraResult.success(this.path)
      : cancelled = false,
        errorMessage = null;
  CameraResult.cancelled()
      : path = null,
        cancelled = true,
        errorMessage = null;
  CameraResult.failure(this.errorMessage)
      : path = null,
        cancelled = false;
}

class BatteryInfo {
  final int level;
  final BatteryState state;
  BatteryInfo({required this.level, required this.state});
}

/// Wraps the three required mobile capabilities for the assignment:
///   • Geolocation (geolocator)
///   • Camera        (image_picker, camera source)
///   • Battery       (battery_plus)
class DeviceService {
  static final Battery _battery = Battery();
  static final ImagePicker _picker = ImagePicker();

  // ---------- Location ----------

  /// High-accuracy GPS, then [getLastKnownPosition] fallback. No demo coords.
  static Future<LocationResult> acquireRealLocation() async {
    debugPrint('📍 LOCATION - ───── acquire real ─────');

    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('📍 LOCATION SERVICE ENABLED: $servicesEnabled');
    if (!servicesEnabled) {
      final hint = _isAndroidEmulator()
          ? 'Location service is OFF. Enable location in emulator settings '
              '(Extended controls → Location) or set a mock location.'
          : 'Location service is OFF. Please enable GPS in system settings.';
      debugPrint('❌ LOCATION ERROR: $hint');
      return LocationResult(
        servicesEnabled: false,
        permission: LocationPermission.denied,
        errorMessage: hint,
        kind: LocationAcquireKind.none,
      );
    }

    LocationPermission perm = await Geolocator.checkPermission();
    debugPrint('📍 LOCATION PERMISSION: $perm');

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      debugPrint('📍 LOCATION PERMISSION (after request): $perm');
    }

    if (perm == LocationPermission.deniedForever) {
      const msg =
          'Location permission permanently denied. Enable it from app settings.';
      debugPrint('❌ LOCATION ERROR: $msg');
      return LocationResult(
        servicesEnabled: true,
        permission: perm,
        errorMessage: msg,
        kind: LocationAcquireKind.none,
      );
    }

    if (perm == LocationPermission.denied) {
      const msg = 'Location permission denied. Please allow location access.';
      debugPrint('❌ LOCATION ERROR: $msg');
      return LocationResult(
        servicesEnabled: true,
        permission: perm,
        errorMessage: msg,
        kind: LocationAcquireKind.none,
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      debugPrint('📍 REAL GPS SUCCESS: ${pos.latitude}, ${pos.longitude}');
      return LocationResult(
        servicesEnabled: true,
        permission: perm,
        location: DeviceLocation(pos.latitude, pos.longitude),
        kind: LocationAcquireKind.realGps,
      );
    } catch (e) {
      debugPrint('❌ LOCATION ERROR: getCurrentPosition failed — $e');
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          debugPrint(
            '📍 LAST KNOWN LOCATION USED: ${last.latitude}, ${last.longitude}',
          );
          return LocationResult(
            servicesEnabled: true,
            permission: perm,
            location: DeviceLocation(last.latitude, last.longitude),
            kind: LocationAcquireKind.lastKnown,
          );
        }
      } catch (e2) {
        debugPrint('❌ LOCATION ERROR: getLastKnownPosition failed — $e2');
      }

      const msg =
          'Could not get GPS location. Please enable Location and Precise Location permission.';
      debugPrint('❌ LOCATION ERROR: $msg');
      return LocationResult(
        servicesEnabled: true,
        permission: perm,
        errorMessage: msg,
        kind: LocationAcquireKind.none,
      );
    }
  }

  /// Demo cinema coordinates (Colombo area, Sri Lanka). Call only when the
  /// user explicitly taps the demo location button.
  static DeviceLocation demoCinemaLocation() {
    const lat = 6.9271;
    const lng = 79.8612;
    debugPrint('📍 DEMO LOCATION USED (Sri Lanka): $lat, $lng');
    return DeviceLocation(lat, lng);
  }

  /// Sample Sri Lankan cinema/theatre coordinates for nearest-cinema
  /// calculations on the Device screen (MovieBuff Sri Lanka scenario).
  static const Map<String, List<double>> sriLankanCinemaLocations = {
    'Scope Cinemas Colombo City Centre': [6.9177, 79.8561],
    'PVR Cinemas One Galle Face': [6.9271, 79.8441],
    'Liberty Cinema Colombo': [6.9117, 79.8525],
    'Savoy 3D Cinema Wellawatte': [6.8742, 79.8608],
    'Regal Cinema Colombo': [6.9344, 79.8466],
    'KCC Multiplex Kandy': [7.2936, 80.6350],
  };

  /// Returns the nearest entry in [sriLankanCinemaLocations] by great-circle
  /// distance and logs the result for debugging.
  static ({String name, double distanceKm}) findNearestSriLankanCinema(
    double latitude,
    double longitude,
  ) {
    if (sriLankanCinemaLocations.isEmpty) {
      debugPrint('📍 NEAREST CINEMA CALCULATED: (none), 0.00 km');
      return (name: '', distanceKm: 0.0);
    }

    var nearestName = '';
    var nearestKm = double.infinity;
    for (final entry in sriLankanCinemaLocations.entries) {
      final d = distanceKm(
        latitude,
        longitude,
        entry.value[0],
        entry.value[1],
      );
      if (d < nearestKm) {
        nearestKm = d;
        nearestName = entry.key;
      }
    }

    debugPrint(
      '📍 NEAREST CINEMA CALCULATED: $nearestName, '
      '${nearestKm.toStringAsFixed(2)} km',
    );
    return (name: nearestName, distanceKm: nearestKm);
  }

  static bool _isAndroidEmulator() {
    if (!kIsWeb && Platform.isAndroid) return true;
    return false;
  }

  /// Great-circle distance in km between two lat/lng pairs.
  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0; // earth radius km
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  // ---------- Camera ----------

  static Future<CameraResult> takePhoto() async {
    debugPrint('📷 CAMERA - Opening camera');
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        imageQuality: 80,
      );
      if (file == null) {
        debugPrint('📷 CAMERA - Cancelled by user');
        return CameraResult.cancelled();
      }
      debugPrint('📷 CAMERA - Captured: ${file.path}');
      return CameraResult.success(file.path);
    } catch (e) {
      final msg = e.toString().contains('camera_access_denied')
          ? 'Camera permission denied. Enable Camera in app settings.'
          : 'Camera failed: $e';
      debugPrint('❌ CAMERA ERROR: $msg');
      return CameraResult.failure(msg);
    }
  }

  static Future<CameraResult> pickFromGallery() async {
    debugPrint('🖼️ GALLERY - Opening picker');
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 80,
      );
      if (file == null) {
        debugPrint('🖼️ GALLERY - Cancelled by user');
        return CameraResult.cancelled();
      }
      debugPrint('🖼️ GALLERY - Picked: ${file.path}');
      return CameraResult.success(file.path);
    } catch (e) {
      final msg = e.toString().contains('photo_access_denied')
          ? 'Photos permission denied. Enable Photos in app settings.'
          : 'Gallery failed: $e';
      debugPrint('❌ GALLERY ERROR: $msg');
      return CameraResult.failure(msg);
    }
  }

  // ---------- Battery ----------

  static Future<BatteryInfo> getBattery() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    debugPrint('🔋 BATTERY - $level% ($state)');
    return BatteryInfo(level: level, state: state);
  }

  static Stream<BatteryState> batteryStateStream() =>
      _battery.onBatteryStateChanged;
}
