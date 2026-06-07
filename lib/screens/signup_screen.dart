import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/validation/form_validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/movie_provider.dart';
import '../services/profile_details_service.dart';
import 'admin/admin_dashboard_screen.dart';
import '../widgets/app_logo.dart';
import '../widgets/cinematic_background.dart';
import '../widgets/glass_card.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _preferredCinemaController = TextEditingController();
  final _favouriteGenreController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _termsAccepted = false;

  void _signup() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('🔴 SIGNUP - Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors above')),
      );
      return;
    }
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms of service')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final message =
        auth.lastMessage ?? (ok ? 'Account created' : 'Registration failed');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    if (!ok) return;

    await ProfileDetailsService.mergeAfterRegistration(
      email: auth.email!,
      phone: _phoneController.text.trim(),
      preferredCinema: _preferredCinemaController.text.trim(),
      favouriteGenre: _favouriteGenreController.text.trim(),
    );

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: unawaited_futures
      final online = context.read<ConnectivityProvider>().isOnline;
      context.read<MovieProvider>().load(forceRefresh: true, isOnline: online);
      if (auth.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CinematicBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: GlassCard(
                    useBlur: true,
                    borderRadius: 26,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const AppLogo(fontSize: 60),
                          const SizedBox(height: 18),
                          Text(
                            'Create your account',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join MovieBuff — optional details stay on this device only.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              height: 1.4,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(
                                alpha: scheme.brightness == Brightness.dark
                                    ? 0.15
                                    : 0.4,
                              ),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.15),
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      PageRouteBuilder(
                                        pageBuilder: (c, a, _) =>
                                            const LoginScreen(),
                                        transitionsBuilder: (c, anim, _, ch) =>
                                            FadeTransition(
                                              opacity: anim,
                                              child: ch,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      'Login',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.surface,
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.06,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Register',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomTextField(
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            controller: _nameController,
                            maxLength: 50,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(50),
                            ],
                            validator: FormValidators.name,
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: 'Email Address',
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            maxLength: 100,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(100),
                            ],
                            validator: FormValidators.registerEmail,
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: 'Phone Number (optional)',
                            hint: '10 digits',
                            keyboardType: TextInputType.phone,
                            controller: _phoneController,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: FormValidators.phoneOptional,
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: 'Preferred cinema (optional)',
                            hint: 'e.g. Scope Cinemas Colombo',
                            controller: _preferredCinemaController,
                            maxLength: 60,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(60),
                            ],
                            validator: FormValidators.preferredCinemaOptional,
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: 'Favourite genre (optional)',
                            hint: 'e.g. Action, Drama',
                            controller: _favouriteGenreController,
                            maxLength: 40,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(40),
                            ],
                            validator: FormValidators.favouriteGenreOptional,
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: 'Password',
                            hint: 'Create a strong password',
                            isPassword: true,
                            controller: _passwordController,
                            maxLength: 64,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(64),
                            ],
                            validator: FormValidators.registerPassword,
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: 'Confirm Password',
                            hint: 'Confirm your password',
                            isPassword: true,
                            controller: _confirmPasswordController,
                            maxLength: 64,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(64),
                            ],
                            validator: (value) =>
                                FormValidators.confirmPassword(
                              value,
                              _passwordController.text,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Checkbox(
                                value: _termsAccepted,
                                activeColor: scheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                onChanged: (v) => setState(
                                  () => _termsAccepted = v ?? false,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'I agree to the terms of service',
                                  style: GoogleFonts.outfit(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.68,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'Create Account',
                            onPressed: _signup,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.outfit(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (c, a, _) =>
                                          const LoginScreen(),
                                      transitionsBuilder: (c, anim, _, ch) =>
                                          FadeTransition(
                                            opacity: anim,
                                            child: ch,
                                          ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign In',
                                  style: GoogleFonts.outfit(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
