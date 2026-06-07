import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/movie_provider.dart';
import '../../services/admin_catalog_service.dart';
import '../../services/showtime_service.dart';
import '../../utils/movie_catalog_utils.dart';
import '../../widgets/premium_screen_stack.dart';

class _AdminShowtimePack {
  const _AdminShowtimePack({
    required this.movies,
    required this.theatres,
    required this.showtimes,
  });

  final List<Map<String, dynamic>> movies;
  final List<Map<String, dynamic>> theatres;
  final List<Map<String, dynamic>> showtimes;
}

class AdminShowtimesScreen extends StatefulWidget {
  const AdminShowtimesScreen({super.key});

  @override
  State<AdminShowtimesScreen> createState() => _AdminShowtimesScreenState();
}

class _AdminShowtimesScreenState extends State<AdminShowtimesScreen> {
  Future<_AdminShowtimePack> _loadPack(MovieProvider prov) async {
    final movies = await AdminCatalogService.mergeMoviesForAdmin(prov.movies);
    final theatres = await AdminCatalogService.mergeTheatresForAdmin(
      prov.movies,
    );
    final showtimes = prov.showtimes.isNotEmpty
        ? prov.showtimes
        : await ShowtimeService.getAdminMergedShowtimes(prov.movies);
    final sorted = List<Map<String, dynamic>>.from(showtimes.reversed);
    return _AdminShowtimePack(
      movies: movies,
      theatres: theatres,
      showtimes: sorted,
    );
  }

  Map<String, dynamic>? _movieForTitle(
    String? title,
    List<Map<String, dynamic>> movies,
  ) {
    if (title == null) return null;
    for (final m in movies) {
      if (m['title'] == title) return m;
    }
    return null;
  }

  void _showShowtimeDialog(
    _AdminShowtimePack pack, {
    Map<String, dynamic>? existing,
  }) {
    String? selectedMovie =
        existing?['movie']?.toString() ??
        (pack.movies.isNotEmpty ? pack.movies.first['title']?.toString() : null);
    String? selectedTheatre =
        existing?['theatre']?.toString() ??
        (pack.theatres.isNotEmpty
            ? pack.theatres.first['name']?.toString()
            : null);

    final m0 = _movieForTitle(selectedMovie, pack.movies);
    DateTime selectedDate = () {
      final d = existing?['date']?.toString();
      if (d != null && d.isNotEmpty) {
        try {
          return DateTime.parse(d);
        } catch (_) {}
      }
      return DateTime.now();
    }();

    final timeController = TextEditingController(
      text: existing?['time']?.toString() ?? '10:00 AM',
    );
    final priceController = TextEditingController(
      text: (existing?['price'] is num)
          ? (existing!['price'] as num).toString()
          : (existing?['price']?.toString() ?? '750'),
    );

    var selectedFormat = existing?['format']?.toString() ?? '2D';
    var selectedLanguage = existing?['language']?.toString() ?? 'English';

    if (m0 != null) {
      final fmts = m0['formats'];
      if (fmts is List && fmts.isNotEmpty) {
        selectedFormat = fmts.first.toString();
      }
      final langs = m0['languages'];
      if (langs is List && langs.isNotEmpty) {
        selectedLanguage = langs.first.toString();
      }
      priceController.text =
          MovieCatalogUtils.priceFromMovie(m0).toStringAsFixed(0);
    }

    final allFormats = ['2D', '3D', 'IMAX', '4DX'];
    final baseLangs = [
      'English',
      'Tamil',
      'Sinhala',
      'Hindi',
      'Japanese',
      'French',
      'Korean',
      'Mandarin',
      'Telugu',
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final bottomInset = MediaQuery.viewInsetsOf(dialogContext).bottom;
            final selM = _movieForTitle(selectedMovie, pack.movies);
            List<String> langOpts = List<String>.from(baseLangs);
            List<String> fmtOpts = List<String>.from(allFormats);
            if (selM != null) {
              final l = selM['languages'];
              if (l is List && l.isNotEmpty) {
                langOpts = l.map((e) => e.toString()).toList();
              }
              final f = selM['formats'];
              if (f is List && f.isNotEmpty) {
                fmtOpts = f.map((e) => e.toString()).toList();
              }
            }

            void onMovieChanged(String? v) {
              setDialogState(() {
                selectedMovie = v;
                final mm = _movieForTitle(v, pack.movies);
                if (mm != null) {
                  priceController.text = MovieCatalogUtils.priceFromMovie(mm)
                      .toStringAsFixed(0);
                  final fmts = mm['formats'];
                  if (fmts is List && fmts.isNotEmpty) {
                    selectedFormat = fmts.first.toString();
                  }
                  final langs = mm['languages'];
                  if (langs is List && langs.isNotEmpty) {
                    selectedLanguage = langs.first.toString();
                  }
                }
              });
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Dialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    maxHeight: MediaQuery.sizeOf(context).height * 0.88,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          existing == null ? 'Add New Showtime' : 'Edit Showtime',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Movie *',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'admin-st-movie-${selectedMovie ?? ''}',
                          ),
                          isExpanded: true,
                          initialValue: selectedMovie,
                          items: pack.movies
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m['title'] as String?,
                                  child: Text(
                                    m['title']?.toString() ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: onMovieChanged,
                          decoration: _fieldDeco(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Theatre *',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'admin-st-theatre-${selectedTheatre ?? ''}',
                          ),
                          isExpanded: true,
                          initialValue: selectedTheatre,
                          items: pack.theatres
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t['name'] as String?,
                                  child: Text(
                                    t['name']?.toString() ?? '',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedTheatre = v),
                          decoration: _fieldDeco(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Time *',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: dialogContext,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              final h = picked.hourOfPeriod == 0
                                  ? 12
                                  : picked.hourOfPeriod;
                              final mi = picked.minute.toString().padLeft(2, '0');
                              final p =
                                  picked.period == DayPeriod.am ? 'AM' : 'PM';
                              setDialogState(
                                () => timeController.text = '$h:$mi $p',
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: _boxDeco(context),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    timeController.text,
                                    style: GoogleFonts.outfit(fontSize: 16),
                                  ),
                                ),
                                const Icon(Icons.schedule, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Date *',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: _boxDeco(context),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.outfit(fontSize: 16),
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Language',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'admin-st-lang-${selectedMovie ?? ''}-${langOpts.join('|')}-$selectedLanguage',
                          ),
                          isExpanded: true,
                          initialValue: langOpts.contains(selectedLanguage)
                              ? selectedLanguage
                              : (langOpts.isNotEmpty ? langOpts.first : null),
                          items: langOpts
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l,
                                  child: Text(l),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setDialogState(
                            () => selectedLanguage = v ?? 'English',
                          ),
                          decoration: _fieldDeco(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Format',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'admin-st-fmt-${selectedMovie ?? ''}-${fmtOpts.join('|')}-$selectedFormat',
                          ),
                          isExpanded: true,
                          initialValue: fmtOpts.contains(selectedFormat)
                              ? selectedFormat
                              : (fmtOpts.isNotEmpty ? fmtOpts.first : null),
                          items: fmtOpts
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedFormat = v ?? '2D'),
                          decoration: _fieldDeco(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Price (LKR) *',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _fieldDeco(context).copyWith(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: () async {
                                  if (selectedMovie == null ||
                                      selectedMovie!.isEmpty ||
                                      selectedTheatre == null ||
                                      selectedTheatre!.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Movie and theatre are required',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (timeController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Time is required'),
                                      ),
                                    );
                                    return;
                                  }
                                  final price =
                                      double.tryParse(priceController.text) ??
                                          0;
                                  if (price <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Price must be a positive number',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final dateStr =
                                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

                                  final selM =
                                      _movieForTitle(selectedMovie, pack.movies);
                                  final selT = pack.theatres.firstWhere(
                                    (t) => t['name'] == selectedTheatre,
                                    orElse: () => {},
                                  );
                                  final row = <String, dynamic>{
                                    'movie': selectedMovie,
                                    'theatre': selectedTheatre,
                                    if (selM?['id'] != null)
                                      'movie_id': selM!['id'],
                                    if (selT['id'] != null)
                                      'theatre_id': selT['id'],
                                    'time': timeController.text.trim(),
                                    'date': dateStr,
                                    'format': selectedFormat,
                                    'language': selectedLanguage,
                                    'label': selectedFormat,
                                    'price': price,
                                  };

                                  if (existing == null) {
                                    await ShowtimeService.addShowtime(row);
                                  } else {
                                    await ShowtimeService.updateShowtime(
                                      existing['id']!.toString(),
                                      row,
                                    );
                                  }

                                  if (!mounted) return;
                                  await context
                                      .read<MovieProvider>()
                                      .refreshAfterAdminEdit();
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                  if (mounted) setState(() {});
                                },
                                child: Text(
                                  existing == null ? 'Add' : 'Save',
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
            );
          },
        );
      },
    );
  }

  InputDecoration _fieldDeco(BuildContext context) {
    return InputDecoration(
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }

  BoxDecoration _boxDeco(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(Map<String, dynamic> st, _AdminShowtimePack pack) {
    final price = st['price'];
    final priceStr =
        price is num ? 'LKR ${price.toStringAsFixed(0)}' : '${st['price']}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.25
                  : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        st['theatre']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFF6482AD)
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        st['movie']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ACTIVE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _detailRow(
              'FORMAT / LANG',
              '${st['format'] ?? '2D'} · ${(st['language'] ?? 'English').toUpperCase()}',
            ),
            const SizedBox(height: 8),
            _detailRow(
              'DATE & TIME',
              '${_formatExactDate(st['date']?.toString() ?? '')} ${st['time'] ?? ''}',
            ),
            const SizedBox(height: 8),
            _detailRow('PRICE', priceStr),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showShowtimeDialog(pack, existing: st),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () => _confirmDelete(st['id']?.toString() ?? ''),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatExactDate(String dateStr) {
    try {
      DateTime date;
      if (dateStr == 'Today') {
        date = DateTime.now();
      } else if (dateStr == 'Tomorrow') {
        date = DateTime.now().add(const Duration(days: 1));
      } else {
        date = DateTime.parse(dateStr);
      }
      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _confirmDelete(String id) {
    if (id.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Showtime'),
        content: const Text('Remove this showtime?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ShowtimeService.deleteShowtime(id);
              if (!mounted) return;
              await context.read<MovieProvider>().refreshAfterAdminEdit();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.82),
        elevation: 0,
        foregroundColor: scheme.onSurface,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: scheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Back to Dashboard',
            style: GoogleFonts.outfit(
              color: scheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      floatingActionButton: Consumer<MovieProvider>(
        builder: (context, prov, _) {
          return FloatingActionButton(
            onPressed: () async {
              final pack = await _loadPack(prov);
              if (mounted) _showShowtimeDialog(pack);
            },
            backgroundColor: scheme.primary,
            child: Icon(
              Icons.add,
              color: scheme.onPrimary,
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: PremiumScreenStack(
        child: Consumer<MovieProvider>(
          builder: (context, prov, _) {
            return FutureBuilder<_AdminShowtimePack>(
              future: _loadPack(prov),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pack = snap.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    await prov.load(forceRefresh: true);
                    if (mounted) setState(() {});
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    children: [
                      Text(
                        'Showtime Management',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Schedules synced with the active movie catalogue.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (pack.showtimes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Center(
                            child: Text(
                              'No showtimes in this view',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        ...pack.showtimes.map(
                          (st) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _card(st, pack),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
