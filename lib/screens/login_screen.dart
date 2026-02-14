import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import '../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _rememberMe = true; // Remember me checkbox state

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Authenticate against local registry
      final user = await AuthService.authenticateUser(
        _emailController.text,
        _passwordController.text,
      );

      if (user == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
        }
        return;
      }

      final isAdmin = user['role'] == 'admin';

      // Save Session with actual user details ONLY if "Remember me" is checked
      if (_rememberMe) {
        await AuthService.saveLoginSession(
          user['name']!,
          user['email']!,
          isAdmin: isAdmin,
        );
      }

      setState(() => _isLoading = false);
      if (mounted) {
        if (isAdmin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Welcome Banner (Top on mobile)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 48,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Use AppLogo widget
                      const AppLogo(fontSize: 72),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to MovieBuff!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your gateway to premium cinema experiences. Find the best seats at the best theatres.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Auth Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Toggle Switch
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => const SignupScreen(),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  color: Colors.transparent, // Hit test
                                  child: Text(
                                    'Register',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        Text(
                          'Sign In',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your credentials to continue',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 32),

                        CustomTextField(
                          label: 'Email Address',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          validator: (value) =>
                              value == null || !value.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Password',
                          hint: '••••••••',
                          isPassword: true,
                          controller: _passwordController,
                          validator: (value) =>
                              value == null || value.length < 6
                              ? 'Password too short'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.primaryBlue,
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? true),
                            ),
                            Text(
                              'Remember me',
                              style: GoogleFonts.outfit(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        CustomButton(
                          text: 'Sign In',
                          onPressed: _login,
                          isLoading: _isLoading,
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.outfit(
                                color: Colors.grey[500],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const SignupScreen(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                              child: Text(
                                'Create one',
                                style: GoogleFonts.outfit(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
