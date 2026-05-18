import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/movie_provider.dart';
import '../services/customer_catalog_service.dart';
import '../widgets/cinematic_background.dart';
import 'theatre_details_screen.dart';

class TheatresScreen extends StatefulWidget {
  const TheatresScreen({super.key});

  @override
  State<TheatresScreen> createState() => _TheatresScreenState();
}

class _TheatresScreenState extends State<TheatresScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Theatres',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: scheme.surface.withValues(alpha: 0.82),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CinematicBackground(),
          Consumer<MovieProvider>(
            builder: (context, prov, _) {
              if (prov.awaitingCatalogueUi) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading catalogue...',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: CustomerCatalogService.mergeCustomerTheatres(
                  prov.movies,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final displayTheatres = snapshot.data!;
                  final fromCatalogue = prov.movies.isNotEmpty &&
                      prov.movies.any(
                        (m) =>
                            (m['theatre']?.toString().trim() ?? '').isNotEmpty,
                      );

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (fromCatalogue) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: scheme.primary.withValues(alpha: 0.12),
                                    border: Border.all(
                                      color: scheme.primary.withValues(
                                        alpha: 0.28,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Live · synced catalogue',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.primary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Text(
                                'Select your theatre',
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                fromCatalogue
                                    ? 'Includes admin updates and live movie data.'
                                    : 'Browse available theatres and exciting showtimes.',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.58,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      if (displayTheatres.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'No theatres available',
                              style: GoogleFonts.outfit(
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final theatre = displayTheatres[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TheatreDetailsScreen(
                                              theatre: theatre,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Ink(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          color: scheme.surface.withValues(
                                            alpha: 0.88,
                                          ),
                                          border: Border.all(
                                            color: scheme.outline.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.06,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(
                                                12,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                color: scheme.primary
                                                    .withValues(alpha: 0.12),
                                              ),
                                              child: Icon(
                                                Icons.theater_comedy_rounded,
                                                color: scheme.primary,
                                                size: 26,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    theatre['name'] as String,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: scheme.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        size: 16,
                                                        color: scheme.onSurface
                                                            .withValues(
                                                          alpha: 0.5,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          theatre['location']
                                                                  as String? ??
                                                              '',
                                                          style: GoogleFonts
                                                              .outfit(
                                                            color: scheme
                                                                .onSurface
                                                                .withValues(
                                                              alpha: 0.55,
                                                            ),
                                                            fontSize: 13,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 16,
                                              color: scheme.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: displayTheatres.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
