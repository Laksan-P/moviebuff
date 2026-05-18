import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/connectivity_banner.dart';
import 'theatres_screen.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'movie_details_screen.dart';
import 'signup_screen.dart';
import 'profile_screen.dart';
import 'device_screen.dart';
import '../services/auth_service.dart';
import '../services/external_movie_service.dart';
import '../providers/movie_provider.dart';
import '../utils/movie_catalog_utils.dart';
import '../widgets/app_logo.dart';
import '../widgets/cinematic_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentSliderIndex = 0;
  int _bottomNavIndex = 0;
  int _tabTransitionToken = 0;
  String? _userName;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final name = await AuthService.getUserName();
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CinematicBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const ConnectivityBanner(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_tabTransitionToken),
                      child: _buildNavStack(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 400;
          final scheme = Theme.of(context).colorScheme;
          return SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 6 : 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    0,
                    Icons.home_outlined,
                    Icons.home,
                    'Home',
                    compact: narrow,
                  ),
                  _buildNavItem(
                    1,
                    Icons.movie_outlined,
                    Icons.movie,
                    'Theatres',
                    compact: narrow,
                  ),
                  _buildNavItem(
                    2,
                    Icons.confirmation_number_outlined,
                    Icons.confirmation_number,
                    'Bookings',
                    compact: narrow,
                  ),
                  _buildNavItem(
                    3,
                    Icons.smartphone_outlined,
                    Icons.smartphone,
                    'Device',
                    compact: narrow,
                  ),
                  _buildNavItem(
                    4,
                    Icons.person_outline,
                    Icons.person,
                    'Profile',
                    compact: narrow,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectNavTab(int index) {
    if (_bottomNavIndex == index) return;
    setState(() {
      _bottomNavIndex = index;
      _tabTransitionToken++;
    });
  }

  Widget _buildNavStack() {
    return IndexedStack(
      index: _bottomNavIndex,
      sizing: StackFit.expand,
      children: [
        KeyedSubtree(
          key: const ValueKey<String>('nav_home'),
          child: _buildHomeContent(),
        ),
        const KeyedSubtree(
          key: ValueKey<String>('nav_theatres'),
          child: TheatresScreen(),
        ),
        const KeyedSubtree(
          key: ValueKey<String>('nav_bookings'),
          child: MyBookingsScreen(),
        ),
        const KeyedSubtree(
          key: ValueKey<String>('nav_device'),
          child: DeviceScreen(),
        ),
        const KeyedSubtree(
          key: ValueKey<String>('nav_profile'),
          child: ProfileScreen(),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    final movieProv = context.watch<MovieProvider>();
    final waiting = movieProv.awaitingCatalogueUi;
    final mergedMovies = movieProv.movies;
    final sliderSource =
        waiting ? <Map<String, dynamic>>[] : mergedMovies.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 900;
        double contentWidth = isWide ? 1200 : double.infinity;
        final narrow = constraints.maxWidth < 400;
        final hPad = narrow ? 16.0 : 24.0;

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
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.38,
                            ),
                            child: Text(
                              'Hello, $_userName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
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
                  padding: EdgeInsets.symmetric(horizontal: hPad),
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
                          _buildCarousel(
                            height: isWide ? 500 : 400,
                            movies: sliderSource,
                            catalogueLoading: waiting,
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ───── External JSON master list (MAD II) ─────
                      _buildExternalMoviesSection(movieProv, isWide, narrow),

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

  Widget _buildCarousel({
    required double height,
    required List<Map<String, dynamic>> movies,
    required bool catalogueLoading,
  }) {
    if (catalogueLoading || movies.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                catalogueLoading
                    ? 'Loading catalogue...'
                    : 'No movies to display yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RepaintBoundary(
      child: Stack(
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
          items: movies.map((movie) {
            return GestureDetector(
              onTap: () {
                final normalized = MovieCatalogUtils.normalizeCustomerMovie(
                  Map<String, dynamic>.from(movie),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsScreen(movie: normalized),
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
                    // Network (image → posterUrl via normalize) or asset fallback
                    _carouselPoster(context, movie),
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
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      (movie['title'] ?? '').toUpperCase(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    movie['genre'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                for (int i = 0; i < movies.length; i++)
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
      ),
    );
  }

  Widget _carouselPoster(BuildContext context, Map<String, dynamic> movie) {
    return _HomeCatalogPoster(movie: movie, boxFit: BoxFit.cover);
  }

  Widget _cataloguePosterTile(BuildContext context, Map<String, dynamic> m) {
    return _HomeCatalogPoster(movie: m, boxFit: BoxFit.cover);
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    bool compact = false,
  }) {
    final isActive = _bottomNavIndex == index;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectNavTab(index),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 5 : 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? scheme.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? scheme.primary.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.52),
                size: 23,
              ),
              if (isActive) ...[
                const SizedBox(width: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Scrollable master list driven by the external JSON (MAD II requirement).
  Widget _buildExternalMoviesSection(
    MovieProvider prov,
    bool isWide,
    bool narrow,
  ) {
    if (prov.awaitingCatalogueUi) {
      final headerColor = Theme.of(context).colorScheme.onSurface;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Catalogue',
            style: GoogleFonts.outfit(
              fontSize: isWide ? 32 : (narrow ? 20 : 22),
              fontWeight: FontWeight.bold,
              color: headerColor,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading catalogue...'),
              ],
            ),
          ),
        ],
      );
    }

    final movies = prov.movies;
    final headerColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = headerColor.withValues(alpha: 0.6);

    String badgeLabel;
    Color badgeColor;
    switch (prov.source) {
      case MovieSource.network:
        badgeLabel = 'LIVE · external JSON';
        badgeColor = const Color(0xFF10B981);
        break;
      case MovieSource.cache:
        badgeLabel = 'CACHED · sqflite';
        badgeColor = Theme.of(context).colorScheme.secondary;
        break;
      case MovieSource.asset:
        badgeLabel = 'OFFLINE · bundled JSON';
        badgeColor = Theme.of(context).colorScheme.error;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    'Live Catalogue',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: isWide ? 32 : (narrow ? 20 : 22),
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: narrow ? 8 : 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeLabel,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: narrow ? 9 : 10,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh from internet',
              icon: prov.awaitingCatalogueUi
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: prov.awaitingCatalogueUi
                  ? null
                  : () async {
                      await prov.load(forceRefresh: true);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${prov.movies.length} movies loaded · ${prov.sourceLabel}',
                          ),
                        ),
                      );
                    },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          prov.sourceLabel,
          style: GoogleFonts.outfit(fontSize: 12, color: mutedColor),
        ),
        const SizedBox(height: 16),
        if (movies.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No movies in the catalogue right now.',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: mutedColor,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: movies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final m = movies[i];
                final isFav = prov.isFavorite(m['title']?.toString() ?? '');
                return GestureDetector(
                  onTap: () {
                    final normalized = MovieCatalogUtils.normalizeCustomerMovie(
                      Map<String, dynamic>.from(m),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MovieDetailsScreen(movie: normalized),
                      ),
                    );
                  },
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _cataloguePosterTile(context, m),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      await prov.toggleFavorite(m);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isFav
                                                ? 'Removed ${m['title']} from favorites'
                                                : 'Saved ${m['title']} to sqflite favorites',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['title']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                m['genre']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String desc) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              height: 1.45,
              color: scheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prefer `image`, then `posterUrl` on network failure; then local asset; then placeholder.
class _HomeCatalogPoster extends StatefulWidget {
  const _HomeCatalogPoster({
    required this.movie,
    required this.boxFit,
  });

  final Map<String, dynamic> movie;
  final BoxFit boxFit;

  @override
  State<_HomeCatalogPoster> createState() => _HomeCatalogPosterState();
}

class _HomeCatalogPosterState extends State<_HomeCatalogPoster> {
  late final List<String> _urls;
  int _index = 0;

  static String? _httpUrl(dynamic v) {
    final t = v?.toString().trim() ?? '';
    if (t.isEmpty || t == 'null') return null;
    if (t.startsWith('http')) return t;
    return null;
  }

  String get _title => widget.movie['title']?.toString() ?? 'Movie';

  @override
  void initState() {
    super.initState();
    final img = _httpUrl(widget.movie['image']);
    final poster = _httpUrl(widget.movie['posterUrl']);
    _urls = [];
    if (img != null) _urls.add(img);
    if (poster != null && poster != img) _urls.add(poster);
  }

  @override
  Widget build(BuildContext context) {
    if (_index < _urls.length) {
      final url = _urls[_index];
      return Image.network(
        url,
        key: ValueKey<String>(url),
        fit: widget.boxFit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          MovieCatalogUtils.logPosterLoadFailed(_title, error);
          final next = _index + 1;
          if (next < _urls.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _index = next);
            });
          }
          return _placeholder(context);
        },
      );
    }

    final asset = widget.movie['image']?.toString() ?? '';
    if (asset.isNotEmpty && !asset.startsWith('http')) {
      return Image.asset(
        asset,
        fit: widget.boxFit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          MovieCatalogUtils.logPosterLoadFailed(_title, error);
          return _placeholder(context);
        },
      );
    }

    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 32,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 6),
          Text(
            _title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
