import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard_screen.dart';
import '../widgets/app_logo.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _termsAccepted = false;

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept the terms of service')),
        );
        return;
      }
      setState(() => _isLoading = true);

      final isRegisteringAsAdmin = _emailController.text.toLowerCase().contains(
        'admin@moviebuff.com',
      );

      // Register User Permanently
      final success = await AuthService.registerUser(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        role: isRegisteringAsAdmin ? 'admin' : 'user',
      );

      if (!success) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email already registered!')),
          );
        }
        return;
      }

      // Save Current Session
      await AuthService.saveLoginSession(
        _nameController.text,
        _emailController.text,
        isAdmin: isRegisteringAsAdmin,
      );

      setState(() => _isLoading = false);
      if (mounted) {
        if (isRegisteringAsAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin account created! Welcome to the dashboard.'),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Logging you in...')),
          );
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
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => const LoginScreen(),
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
                                  color: Colors.transparent,
                                  child: Text(
                                    'Login',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ),
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
                                  'Register',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        Text(
                          'Create Account',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start your journey with us today',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 32),

                        CustomTextField(
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          controller: _nameController,
                          validator: (value) =>
                              value!.isEmpty ? 'Name required' : null,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Email Address',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          validator: (value) =>
                              !value!.contains('@') ? 'Invalid email' : null,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Phone Number',
                          hint: 'Your phone number',
                          keyboardType: TextInputType.phone,
                          controller: _phoneController,
                          validator: (value) =>
                              value!.isEmpty ? 'Phone required' : null,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Password',
                          hint: 'Create a strong password',
                          isPassword: true,
                          controller: _passwordController,
                          validator: (value) =>
                              value!.length < 6 ? 'Too short' : null,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Confirm Password',
                          hint: 'Confirm your password',
                          isPassword: true,
                          controller: _confirmPasswordController,
                          validator: (value) =>
                              value != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              activeColor: AppColors.primaryBlue,
                              onChanged: (v) =>
                                  setState(() => _termsAccepted = v!),
                            ),
                            Expanded(
                              child: Text(
                                'I agree to the terms of service',
                                style: GoogleFonts.outfit(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        CustomButton(
                          text: 'Create Account',
                          onPressed: _signup,
                          isLoading: _isLoading,
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
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
                                        ) => const LoginScreen(),
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
                                'Sign In',
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
