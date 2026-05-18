// Basic smoke test. The real MyApp expects MultiProvider above it, so we just
// verify that the widget can be instantiated without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:moviebuff/main.dart';
import 'package:moviebuff/providers/auth_provider.dart';
import 'package:moviebuff/providers/connectivity_provider.dart';
import 'package:moviebuff/providers/movie_provider.dart';
import 'package:moviebuff/providers/theme_provider.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
          ChangeNotifierProvider(create: (_) => MovieProvider()),
        ],
        child: const MyApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
