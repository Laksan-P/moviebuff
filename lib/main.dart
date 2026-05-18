import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/movie_service.dart';
import 'services/showtime_service.dart';
import 'services/theatre_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed local storage on first run (existing behaviour, untouched).
  await MovieService.initMovies();
  await TheatreService.initTheatres();
  // Avoid injecting Sem 1 template showtimes before MovieProvider merges catalogue.
  await ShowtimeService.initShowtimes(applySem1Templates: false);

  // Create providers, hydrate the ones that need it before runApp.
  final themeProvider = ThemeProvider();
  final authProvider = AuthProvider();
  final connectivityProvider = ConnectivityProvider();
  final movieProvider = MovieProvider();

  await Future.wait([
    themeProvider.load(),
    authProvider.hydrate(),
    connectivityProvider.init(),
  ]);

  // Kick off the external movie load asynchronously so the UI can paint.
  // ignore: unawaited_futures
  movieProvider.load();

  debugPrint(
    '🚀 APP START - loggedIn=${authProvider.isLoggedIn} admin=${authProvider.isAdmin} email=${authProvider.email}',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: connectivityProvider),
        ChangeNotifierProvider.value(value: movieProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'MovieBuff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.mode,
      home: auth.isLoggedIn
          ? (auth.isAdmin ? const AdminDashboardScreen() : const HomeScreen())
          : const LoginScreen(),
    );
  }
}
