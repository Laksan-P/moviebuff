import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import 'theatre_details_screen.dart';
import '../services/theatre_service.dart';

class TheatresScreen extends StatefulWidget {
  const TheatresScreen({super.key});

  @override
  State<TheatresScreen> createState() => _TheatresScreenState();
}

class _TheatresScreenState extends State<TheatresScreen> {
  List<Map<String, dynamic>> _theatres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTheatres();
  }

  Future<void> _loadTheatres() async {
    final theatres = await TheatreService.getTheatres();
    if (mounted) {
      setState(() {
        _theatres = theatres;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Theatres',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Your Theatre',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Browse available theatres and select from exciting movies with multiple showtimes',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final theatre = _theatres[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TheatreDetailsScreen(theatre: theatre),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        theatre['name'] as String,
                                        style: GoogleFonts.outfit(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.headerBackground,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            theatre['location'] as String,
                                            style: GoogleFonts.outfit(
                                              color: AppColors.textMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.headerBackground,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: _theatres.length),
                  ),
                ),
              ],
            ),
    );
  }
}
