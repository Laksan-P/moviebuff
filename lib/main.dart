import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';

import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/movie_service.dart';
import 'services/theatre_service.dart';
import 'services/showtime_service.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Storage Diagnostic
  await MovieService.initMovies(); // Seeding default movies if first run
  await TheatreService.initTheatres(); // Seeding default theatres if first run
  await ShowtimeService.initShowtimes(); // Seeding default showtimes if first run
  final bool loggedIn = await AuthService.isLoggedIn();
  final bool isAdmin = await AuthService.isAdmin();
  final String? email = await AuthService.getUserEmail();

  debugPrint(
    '🚀 APP START - Login Status: $loggedIn (Admin: $isAdmin, Email: $email)',
  );

  runApp(MyApp(isLoggedIn: loggedIn, isAdmin: isAdmin));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isAdmin;
  const MyApp({super.key, required this.isLoggedIn, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieBuff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isLoggedIn
          ? (isAdmin ? const AdminDashboardScreen() : const HomeScreen())
          : const LoginScreen(),
    );
  }
}
