import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Admin Portal',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const CustomTextField(label: 'Username', hint: 'admin'),
            const SizedBox(height: 16),
            const CustomTextField(
              label: 'Password',
              hint: 'password',
              isPassword: true,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Login',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
