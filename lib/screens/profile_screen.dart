import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<String?>>(
        future: Future.wait([
          AuthService.getUserName(),
          AuthService.getUserEmail(),
        ]),
        builder: (context, snapshot) {
          final userName = snapshot.data?[0] ?? 'User';
          final userEmail = snapshot.data?[1] ?? '';
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryBlue.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 50,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      userName,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headerBackground,
                      ),
                    ),
                    if (userEmail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: GoogleFonts.outfit(
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const SizedBox(height: 48),
                    const SizedBox(height: 64),

                    // removed unnecessary items as per request
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CustomButton(
                        text: 'Logout',
                        color: const Color(0xFFEFF6FF), // Light blue info color
                        textColor: AppColors.primaryBlue,
                        onPressed: () async {
                          await AuthService.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
