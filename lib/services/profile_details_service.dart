import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only profile fields (SharedPreferences), keyed by user email.
/// Never sent to SSP API from this service.
class ProfileDetails {
  const ProfileDetails({
    this.displayNameOverride = '',
    this.phone = '',
    this.preferredCinema = '',
    this.favouriteGenre = '',
  });

  final String displayNameOverride;
  final String phone;
  final String preferredCinema;
  final String favouriteGenre;

  String displayNameOr(String authName) => displayNameOverride.trim().isNotEmpty
      ? displayNameOverride.trim()
      : authName.trim();

  ProfileDetails copyWith({
    String? displayNameOverride,
    String? phone,
    String? preferredCinema,
    String? favouriteGenre,
  }) {
    return ProfileDetails(
      displayNameOverride: displayNameOverride ?? this.displayNameOverride,
      phone: phone ?? this.phone,
      preferredCinema: preferredCinema ?? this.preferredCinema,
      favouriteGenre: favouriteGenre ?? this.favouriteGenre,
    );
  }

  Map<String, dynamic> toJson() => {
    'displayNameOverride': displayNameOverride,
    'phone': phone,
    'preferredCinema': preferredCinema,
    'favouriteGenre': favouriteGenre,
  };

  static ProfileDetails fromJson(Map<String, dynamic> json) {
    return ProfileDetails(
      displayNameOverride: json['displayNameOverride']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      preferredCinema: json['preferredCinema']?.toString() ?? '',
      favouriteGenre: json['favouriteGenre']?.toString() ?? '',
    );
  }
}

class ProfileDetailsService {
  ProfileDetailsService._();

  static String _keyFor(String? email) =>
      'profile_details_v1_${(email ?? '').toLowerCase().trim()}';

  static Future<ProfileDetails> load(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    final logEmail = (email?.trim().isEmpty ?? true) ? '(no email)' : email!.trim();
    final raw = prefs.getString(_keyFor(email));
    if (raw == null || raw.isEmpty) {
      debugPrint('👤 PROFILE - Loaded profile details (empty) for $logEmail');
      return const ProfileDetails();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final d = ProfileDetails.fromJson(map);
      debugPrint('👤 PROFILE - Loaded profile details for $logEmail');
      return d;
    } catch (_) {
      debugPrint('👤 PROFILE - Loaded profile details (parse fallback) for $logEmail');
      return const ProfileDetails();
    }
  }

  static Future<void> save(String? email, ProfileDetails details) async {
    final prefs = await SharedPreferences.getInstance();
    final logEmail = (email?.trim().isEmpty ?? true) ? '(no email)' : email!.trim();
    await prefs.setString(_keyFor(email), jsonEncode(details.toJson()));
    debugPrint('👤 PROFILE - Saved profile details for $logEmail');
  }

  /// After successful API registration — local extras only.
  static Future<void> mergeAfterRegistration({
    required String email,
    String? phone,
    String? preferredCinema,
    String? favouriteGenre,
  }) async {
    final existing = await load(email);
    final merged = existing.copyWith(
      phone: phone?.trim().isNotEmpty == true ? phone!.trim() : existing.phone,
      preferredCinema: preferredCinema?.trim().isNotEmpty == true
          ? preferredCinema!.trim()
          : existing.preferredCinema,
      favouriteGenre: favouriteGenre?.trim().isNotEmpty == true
          ? favouriteGenre!.trim()
          : existing.favouriteGenre,
    );
    await save(email, merged);
  }
}
