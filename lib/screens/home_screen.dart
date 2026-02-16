import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_button.dart';
import 'theatres_screen.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'movie_details_screen.dart';
import 'signup_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import '../services/movie_service.dart';
import '../widgets/app_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentSliderIndex = 0;
  int _bottomNavIndex = 0;
  String? _userName;
  List<Map<String, dynamic>> _sliderMovies = [];
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final name = await AuthService.getUserName();
    final movies = await MovieService.getMovies();
    if (mounted) {
      setState(() {
        _userName = name;
        _sliderMovies = movies.take(3).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(1, Icons.movie_outlined, Icons.movie, 'Theatres'),
            _buildNavItem(
              2,
              Icons.confirmation_number_outlined,
              Icons.confirmation_number,
              'Bookings',
            ),
            _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_bottomNavIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const TheatresScreen();
      case 2:
        return const MyBookingsScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 900;
        double contentWidth = isWide ? 1200 : double.infinity;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Navbar container for wide screens
              Container(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: AppBar(
                  automaticallyImplyLeading: false,
                  title: const AppLogo(fontSize: 48),
                  actions: [
                    if (_userName != null) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Text(
                            'Hello, $_userName',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Login',
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 16,
                          top: 8,
                          bottom: 8,
                        ),
                        child: CustomButton(
                          text: 'Sign Up',
                          width: 90,
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          textColor: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Section
                      // Unified Layout (Vertical Stack for both Mobile & Landscape)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isWide) SizedBox(height: 40),
                          Text(
                            'Experience Cinema Your Way',
                            style: GoogleFonts.outfit(
                              fontSize: isWide ? 48 : 32, // Adaptive font size
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Experience movies your way—book instantly, choose your seats, and enjoy the show exactly how you like it!',
                            style: GoogleFonts.outfit(
                              fontSize: isWide ? 18 : 15,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          CustomButton(
                            text: 'Book Tickets Now →',
                            width: double.infinity, // Full width button
                            height: 56,
                            onPressed: () {
                              setState(() => _bottomNavIndex = 1);
                            },
                          ),
                          const SizedBox(height: 40),
                          _buildCarousel(height: isWide ? 500 : 400),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Why Choose Section
                      Text(
                        'Why Choose MovieBuff?',
                        style: GoogleFonts.outfit(
                          fontSize: isWide ? 32 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isWide ? 32 : 20),

                      if (constraints.maxWidth > 600)
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 3,
                          childAspectRatio: constraints.maxWidth > 900
                              ? 2.5
                              : 2.0,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildFeatureCard(
                              'Easy Booking',
                              'Book tickets in just 3 simple steps',
                            ),
                            _buildFeatureCard(
                              'Multiple Theatres',
                              'Choose from quality theatres',
                            ),
                            _buildFeatureCard(
                              'Flexible Cancellation',
                              '50% refund available',
                            ),
                            _buildFeatureCard(
                              'Secure Payments',
                              'Encrypted transactions',
                            ),
                            _buildFeatureCard(
                              'Live Availability',
                              'Real-time seat updates',
                            ),
                            _buildFeatureCard(
                              'User Dashboard',
                              'Manage bookings easily',
                            ),
                          ],
                        )
                      else ...[
                        _buildFeatureCard(
                          'Easy Booking',
                          'Book tickets in just 3 simple steps',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          'Multiple Theatres',
                          'Choose from quality theatres',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          'Flexible Cancellation',
                          '50% refund available',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          'Secure Payments',
                          'Encrypted transactions',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          'Live Availability',
                          'Real-time seat updates',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          'User Dashboard',
                          'Manage bookings easily',
                        ),
                      ],

                      // Footer
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: isWide ? 60 : 40,
                          horizontal: 24,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Ready to Experience Cinema ?',
                              style: GoogleFonts.outfit(
                                fontSize: isWide ? 28 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join thousands of movie lovers today',
                              style: GoogleFonts.outfit(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: isWide ? 16 : 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              text: 'Start Booking Now →',
                              width: 220,
                              onPressed: () {
                                setState(() => _bottomNavIndex = 1);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCarousel({required double height}) {
    return Stack(
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: height,
            viewportFraction: 0.9,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            scrollPhysics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index, reason) {
              setState(() => _currentSliderIndex = index);
            },
          ),
          items: _sliderMovies.map((movie) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsScreen(movie: movie),
                  ),
                );
              },
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Network or Asset Image
                    movie['image'] != null && movie['image']!.startsWith('http')
                        ? Image.network(
                            movie['image']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.3),
                                  size: 48,
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            movie['image'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.movie,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.3),
                                  size: 48,
                                ),
                              );
                            },
                          ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    // Movie Info
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'NOW SHOWING',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    (movie['title'] ?? '').toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    movie['genre'] ?? '',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (int i = 0; i < _sliderMovies.length; i++)
                                  Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: _currentSliderIndex == i
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        Positioned(
          left: 32,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(12),
              ),
              onPressed: () {
                _carouselController.previousPage();
              },
            ),
          ),
        ),
        Positioned(
          right: 32,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton(
              icon: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(12),
              ),
              onPressed: () {
                _carouselController.nextPage();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    bool isActive = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _bottomNavIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
