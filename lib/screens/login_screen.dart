import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/validation/form_validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/cinematic_background.dart';
import '../widgets/glass_card.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/movie_provider.dart';
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
  bool _rememberMe = true;

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('🔴 LOGIN - Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors above')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!_rememberMe) {
      debugPrint(
        '🔵 LOGIN - "Remember me" unchecked, session will not persist next launch',
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    final message = auth.lastMessage ?? (ok ? 'Signed in' : 'Login failed');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    if (!ok) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: unawaited_futures
      context.read<MovieProvider>().load(forceRefresh: true);
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: GlassCard(
                    useBlur: true,
                    borderRadius: 26,
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                    child: Column(
                      children: [
                        const AppLogo(fontSize: 64),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome to MovieBuff',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Premium cinema booking — find your seats and enjoy the show.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            height: 1.45,
                            color: scheme.onSurface.withValues(alpha: 0.58),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
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
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'Login',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w800,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pushReplacement(
                                          PageRouteBuilder(
                                            pageBuilder:
                                                (context, animation, _) =>
                                                const SignupScreen(),
                                            transitionsBuilder:
                                                (c, anim, _, child) =>
                                                FadeTransition(
                                                  opacity: anim,
                                                  child: child,
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
                                          'Register',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w700,
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.45,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 26),
                              Text(
                                'Sign in',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter your credentials to continue',
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  color: scheme.onSurface.withValues(alpha: 0.52),
                                ),
                              ),
                              const SizedBox(height: 22),
                              CustomTextField(
                                label: 'Email Address',
                                hint: 'you@example.com',
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
                                maxLength: 100,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(100),
                                ],
                                validator: FormValidators.loginEmail,
                              ),
                              const SizedBox(height: 18),
                              CustomTextField(
                                label: 'Password',
                                hint: '••••••••',
                                isPassword: true,
                                controller: _passwordController,
                                maxLength: 64,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(64),
                                ],
                                validator: FormValidators.loginPassword,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: scheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v ?? true),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Remember me',
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
                                text: 'Sign In',
                                onPressed: _login,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
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
                                          pageBuilder:
                                              (context, animation, _) =>
                                              const SignupScreen(),
                                          transitionsBuilder:
                                              (c, anim, _, child) =>
                                              FadeTransition(
                                                opacity: anim,
                                                child: child,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Create one',
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
                      ],
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
