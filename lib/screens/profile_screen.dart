import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/validation/form_validators.dart';
import '../providers/auth_provider.dart';
import '../providers/movie_provider.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../widgets/theme_toggle_button.dart';
import '../services/local_db_service.dart';
import '../services/profile_details_service.dart';
import '../services/profile_photo_service.dart';
import '../services/booking_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/cinematic_background.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.visibilityToken = 0});

  /// Bumped by [HomeScreen] when the Profile tab becomes active.
  final int visibilityToken;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  String? _photoPath;
  ProfileDetails _details = const ProfileDetails();
  int _bookingCount = 0;
  AuthProvider? _authForListener;
  MovieProvider? _movieProvForListener;
  VoidCallback? _bookingRefreshListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachListeners());
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visibilityToken != oldWidget.visibilityToken) {
      _scheduleProfileReload();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleProfileReload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleProfileReload();
    }
  }

  void _attachListeners() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    _authForListener ??= auth..addListener(_onAuthSessionChanged);

    final movieProv = context.read<MovieProvider>();
    _movieProvForListener ??= movieProv..addListener(_onMovieProvChanged);

    _bookingRefreshListener ??= _onBookingsRefreshSignal;
    BookingService.refresh.addListener(_bookingRefreshListener!);

    _scheduleProfileReload();
  }

  void _onBookingsRefreshSignal() {
    _scheduleProfileReload();
  }

  void _onAuthSessionChanged() {
    _scheduleProfileReload();
  }

  void _onMovieProvChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _scheduleProfileReload() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _reloadProfile();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authForListener?.removeListener(_onAuthSessionChanged);
    _movieProvForListener?.removeListener(_onMovieProvChanged);
    if (_bookingRefreshListener != null) {
      BookingService.refresh.removeListener(_bookingRefreshListener!);
    }
    super.dispose();
  }

  String _localBookingsLabel(int count) => '$count saved on device';

  Future<void> _reloadProfile() async {
    final auth = context.read<AuthProvider>();
    final movieProv = context.read<MovieProvider>();
    final mail = (await AuthService.getUserEmail())?.trim() ?? '';
    final logEmail = mail.isEmpty ? '(no email)' : mail;
    debugPrint('👤 PROFILE - Loading data for $logEmail');

    final details = await ProfileDetailsService.load(auth.email);
    final path = await ProfilePhotoService.getValidPath(auth.email);

    var bookings = 0;
    if (mail.isNotEmpty) {
      try {
        debugPrint('👤 PROFILE BOOKING COUNT SOURCE: sqflite/local storage');
        final rows = await LocalDbService.getBookingsByUser(mail);
        bookings = rows.length;
      } catch (_) {
        bookings = 0;
      }
    }

    final favCount = movieProv.favorites.length;
    debugPrint(
      '👤 PROFILE ACTIVITY REFRESHED: bookings=$bookings favourites=$favCount',
    );

    if (mounted) {
      setState(() {
        _details = details;
        _bookingCount = bookings;
        _photoPath = mail.isEmpty ? null : path;
      });
    }
  }

  String _notAdded(String? s) {
    final t = s?.trim() ?? '';
    return t.isEmpty ? 'Not added yet' : t;
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    final messenger = ScaffoldMessenger.of(context);
    final email = context.read<AuthProvider>().email;
    final result = fromCamera
        ? await DeviceService.takePhoto()
        : await DeviceService.pickFromGallery();

    if (result.cancelled) return;

    if (result.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(result.errorMessage!)));
      return;
    }

    if (result.path == null) return;

    if (email == null || email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in to save a profile photo.')),
      );
      return;
    }

    await ProfilePhotoService.savePath(email, result.path!);
    if (!mounted) return;
    setState(() => _photoPath = result.path);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Profile photo saved locally on this device.'),
      ),
    );
  }

  Future<void> _removePhoto() async {
    final email = context.read<AuthProvider>().email;
    if (email == null || email.isEmpty) return;
    await ProfilePhotoService.clear(email);
    if (!mounted) return;
    setState(() => _photoPath = null);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile photo removed.')));
  }

  void _openPhotoOptionsSheet() {
    final scheme = Theme.of(context).colorScheme;
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profile photo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saved on this device for your account only',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _photoSheetOption(
                  sheetCtx,
                  icon: Icons.photo_camera_outlined,
                  label: 'Take Photo',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickPhoto(fromCamera: true);
                  },
                ),
                const SizedBox(height: 8),
                _photoSheetOption(
                  sheetCtx,
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickPhoto(fromCamera: false);
                  },
                ),
                if (hasPhoto) ...[
                  const SizedBox(height: 8),
                  _photoSheetOption(
                    sheetCtx,
                    icon: Icons.delete_outline,
                    label: 'Remove Photo',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _removePhoto();
                    },
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photoSheetOption(
    BuildContext sheetCtx, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final scheme = Theme.of(sheetCtx).colorScheme;
    final color = isDestructive ? scheme.error : scheme.onSurface;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: isDestructive ? scheme.error : scheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileAvatar(ColorScheme scheme, bool hasPhoto) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: scheme.onPrimary.withValues(alpha: 0.25),
          backgroundImage:
              hasPhoto ? FileImage(File(_photoPath!)) : null,
          child: hasPhoto
              ? null
              : Icon(
                  Icons.person_rounded,
                  size: 52,
                  color: scheme.onPrimary,
                ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            color: scheme.surface,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _openPhotoOptionsSheet,
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                    width: 2.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openEditProfile() {
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final initialDisplayName = _details.displayNameOr(auth.name ?? 'User');

    showModalBottomSheet<ProfileDetails?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return _EditProfileSheet(
          theme: theme,
          readOnlyEmail: auth.email,
          isAdmin: auth.isAdmin,
          initialDisplayName: initialDisplayName,
          initialPhone: _details.phone,
          initialCinema: _details.preferredCinema,
          initialGenre: _details.favouriteGenre,
        );
      },
    ).then((saved) {
      if (!mounted || saved == null) return;
      setState(() => _details = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile details saved.')),
      );
    });
  }

  Widget _sectionHeader(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _roundedCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _detailLine(String label, String value) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityLine(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary.withValues(alpha: 0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final movieProv = context.watch<MovieProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final displayName = _details.displayNameOr(auth.name ?? 'User');
    final userEmail = auth.email ?? '';
    final membershipLine = auth.isAdmin
        ? 'MovieBuff Admin'
        : 'MovieBuff Member';
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CinematicBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _reloadProfile,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    pinned: false,
                    elevation: 0,
                    backgroundColor: scheme.surface.withValues(alpha: 0.75),
                    foregroundColor: scheme.onSurface,
                    title: Text(
                      'My profile',
                      style:
                          GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    actions: const [
                      Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Center(child: ThemeToggleButton(compact: true)),
                      ),
                    ],
                  ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary,
                            scheme.primary.withValues(alpha: 0.82),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                        child: Column(
                          children: [
                            _profileAvatar(scheme, hasPhoto),
                            const SizedBox(height: 14),
                            Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: scheme.onPrimary,
                                height: 1.15,
                              ),
                            ),
                            if (userEmail.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                userEmail,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: scheme.onPrimary.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _headerChip(
                                  scheme.onPrimary,
                                  auth.isAdmin ? 'Admin' : 'Customer',
                                  Icons.badge_outlined,
                                ),
                                _headerChip(
                                  scheme.onPrimary,
                                  auth.source == AuthSource.api
                                      ? 'Signed in via SSP API'
                                      : auth.source == AuthSource.local
                                      ? 'Signed in locally (offline)'
                                      : 'Not signed in',
                                  Icons.verified_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              membershipLine,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: scheme.onPrimary.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _roundedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _sectionHeader(
                                  'Personal details',
                                  icon: Icons.person_outline,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _openEditProfile,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: Text(
                                  'Edit',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _detailLine('Full name', displayName),
                          _detailLine(
                            'Email',
                            userEmail.isEmpty ? 'Not added yet' : userEmail,
                          ),
                          _detailLine(
                            'Phone number',
                            _notAdded(_details.phone),
                          ),
                          _detailLine(
                            'Preferred cinema',
                            _notAdded(_details.preferredCinema),
                          ),
                          _detailLine(
                            'Favourite genre',
                            _notAdded(_details.favouriteGenre),
                          ),
                          _detailLine(
                            'Role',
                            auth.isAdmin ? 'Admin' : 'Customer',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _roundedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            'My MovieBuff activity',
                            icon: Icons.local_movies_outlined,
                          ),
                          const SizedBox(height: 14),
                          _activityLine(
                            Icons.favorite_outline,
                            'Saved favourites',
                            '${movieProv.favorites.length} in sqflite',
                          ),
                          _activityLine(
                            Icons.confirmation_number_outlined,
                            'Local bookings',
                            _localBookingsLabel(_bookingCount),
                          ),
                          _activityLine(
                            Icons.theaters_outlined,
                            'Preferred cinema',
                            _notAdded(_details.preferredCinema),
                          ),
                          _activityLine(
                            Icons.category_outlined,
                            'Favourite genre',
                            _notAdded(_details.favouriteGenre),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _roundedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            'Account actions',
                            icon: Icons.logout_rounded,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                await context.read<AuthProvider>().logout();
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Signed out')),
                                );
                                navigator.pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              icon: Icon(Icons.logout, color: scheme.primary),
                              label: Text(
                                'Log out',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _headerChip(Color onPrimary, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onPrimary.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: onPrimary),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.theme,
    required this.readOnlyEmail,
    required this.isAdmin,
    required this.initialDisplayName,
    required this.initialPhone,
    required this.initialCinema,
    required this.initialGenre,
  });

  final ThemeData theme;
  final String? readOnlyEmail;
  final bool isAdmin;
  final String initialDisplayName;
  final String initialPhone;
  final String initialCinema;
  final String initialGenre;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameC;
  late final TextEditingController _phoneC;
  late final TextEditingController _cinemaC;
  late final TextEditingController _genreC;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.initialDisplayName);
    _phoneC = TextEditingController(text: widget.initialPhone);
    _cinemaC = TextEditingController(text: widget.initialCinema);
    _genreC = TextEditingController(text: widget.initialGenre);
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _cinemaC.dispose();
    _genreC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    final nameErr = FormValidators.name(_nameC.text);
    if (nameErr != null) {
      messenger.showSnackBar(SnackBar(content: Text(nameErr)));
      return;
    }
    final phoneErr = FormValidators.phoneOptional(_phoneC.text);
    if (phoneErr != null) {
      messenger.showSnackBar(SnackBar(content: Text(phoneErr)));
      return;
    }
    final cinemaErr = FormValidators.preferredCinemaOptional(_cinemaC.text);
    if (cinemaErr != null) {
      messenger.showSnackBar(SnackBar(content: Text(cinemaErr)));
      return;
    }
    final genreErr = FormValidators.favouriteGenreOptional(_genreC.text);
    if (genreErr != null) {
      messenger.showSnackBar(SnackBar(content: Text(genreErr)));
      return;
    }

    final auth = context.read<AuthProvider>();
    final email = auth.email;
    if (email == null || email.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cannot save: missing account email.')),
      );
      return;
    }

    final updated = ProfileDetails(
      displayNameOverride: _nameC.text.trim(),
      phone: _phoneC.text.trim(),
      preferredCinema: _cinemaC.text.trim(),
      favouriteGenre: _genreC.text.trim(),
    );

    await ProfileDetailsService.save(email, updated);

    if (!mounted) return;
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit profile',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Email and role come from your login and cannot be changed here.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Email (read-only)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.readOnlyEmail ?? '—',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Role (read-only)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.isAdmin ? 'Admin' : 'Customer',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameC,
              maxLength: 50,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full name',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneC,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: 'Phone number (optional)',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cinemaC,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Preferred cinema',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genreC,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Favourite genre',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Save changes',
              onPressed: () {
                _save();
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
