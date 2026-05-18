import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/device_service.dart';
import '../services/profile_photo_service.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadPhotoPath();
  }

  Future<void> _loadPhotoPath() async {
    final path = await ProfilePhotoService.getValidPath();
    if (mounted) setState(() => _photoPath = path);
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = fromCamera
        ? await DeviceService.takePhoto()
        : await DeviceService.pickFromGallery();

    if (result.cancelled) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            fromCamera ? 'Camera cancelled.' : 'Gallery cancelled.',
          ),
        ),
      );
      return;
    }

    if (result.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(result.errorMessage!)));
      return;
    }

    if (result.path == null) return;
    await ProfilePhotoService.savePath(result.path!);
    if (!mounted) return;
    setState(() => _photoPath = result.path);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Profile photo saved locally on this device.'),
      ),
    );
  }

  Future<void> _removePhoto() async {
    await ProfilePhotoService.clear();
    if (!mounted) return;
    setState(() => _photoPath = null);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile photo removed.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final userName = auth.name ?? 'User';
    final userEmail = auth.email ?? '';
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.65);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Set your MovieBuff profile photo',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    backgroundImage:
                        _photoPath != null && File(_photoPath!).existsSync()
                        ? FileImage(File(_photoPath!))
                        : null,
                    child: _photoPath != null && File(_photoPath!).existsSync()
                        ? null
                        : Icon(
                            Icons.person_outline,
                            size: 56,
                            color: scheme.primary,
                          ),
                  ),
                  const SizedBox(height: 12),
                  if (_photoPath == null)
                    Text(
                      'Add profile photo',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    )
                  else
                    Text(
                      'Profile photo',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'This profile photo is saved locally on this device.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: muted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Take Photo',
                          onPressed: () => _pickPhoto(fromCamera: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Choose from Gallery',
                          isOutlined: true,
                          onPressed: () => _pickPhoto(fromCamera: false),
                        ),
                      ),
                    ],
                  ),
                  if (_photoPath != null && File(_photoPath!).existsSync()) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _removePhoto,
                        child: Text(
                          'Remove Photo',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: scheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    userName,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: GoogleFonts.outfit(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          auth.isAdmin ? 'Role: Admin' : 'Role: Customer',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          auth.source == AuthSource.api
                              ? 'Signed in via SSP API'
                              : auth.source == AuthSource.local
                              ? 'Signed in locally (offline mode)'
                              : 'Not signed in',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Defaults to your device setting. You can override below.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('System'),
                              icon: Icon(Icons.brightness_auto),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Light'),
                              icon: Icon(Icons.light_mode),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Dark'),
                              icon: Icon(Icons.dark_mode),
                            ),
                          ],
                          selected: {themeProv.mode},
                          onSelectionChanged: (s) {
                            themeProv.setMode(s.first);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Theme mode: ${s.first.name}'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomButton(
                      text: 'Logout',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      textColor: Theme.of(context).colorScheme.primary,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
