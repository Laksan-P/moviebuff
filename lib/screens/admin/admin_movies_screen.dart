import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/movie_provider.dart';
import '../../services/admin_catalog_service.dart';
import '../../services/movie_service.dart';

class AdminMoviesScreen extends StatefulWidget {
  const AdminMoviesScreen({super.key});

  @override
  State<AdminMoviesScreen> createState() => _AdminMoviesScreenState();
}

class _AdminMoviesScreenState extends State<AdminMoviesScreen> {
  Future<void> _openMovieForm([Map<String, dynamic>? movie]) async {
    final prov = context.read<MovieProvider>();
    final theatres =
        await AdminCatalogService.mergeTheatresForAdmin(prov.movies);
    if (!mounted) return;
    _showMovieFormDialog(movie, theatres);
  }

  void _showMovieFormDialog(
    Map<String, dynamic>? movie,
    List<Map<String, dynamic>> theatres,
  ) {
    final titleController = TextEditingController(text: movie?['title'] ?? '');
    final genreController = TextEditingController(text: movie?['genre'] ?? '');
    final imageController =
        TextEditingController(text: movie?['image'] ?? movie?['posterUrl'] ?? '');
    final trailerController = TextEditingController(
      text: movie?['trailerUrl'] ?? '',
    );
    final durationController = TextEditingController(
      text: movie?['duration']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: (movie?['price'] ?? movie?['ticketPrice'])?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: movie?['description'] ?? '',
    );

    String selectedRating = movie?['rating'] ?? 'PG-13';
    String selectedDateStr = movie?['releaseDate'] ?? '';
    String? selectedTheatre = movie?['theatre']?.toString();

    List<String> selectedFormats = List<String>.from(
      movie?['formats'] ?? ['2D'],
    );
    List<String> selectedLanguages = List<String>.from(
      movie?['languages'] ?? ['English'],
    );

    final ratings = ['G', 'PG', 'PG-13', 'R', 'NC-17'];
    final allFormats = ['2D', '3D', 'IMAX', '4DX'];
    final allLanguages = [
      'English',
      'Hindi',
      'Tamil',
      'Telugu',
      'Sinhala',
      'Japanese',
      'French',
      'Korean',
      'Mandarin',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie == null ? 'Add Movie' : 'Update Movie',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFieldLabel('MOVIE TITLE'),
                  _buildStyledField(titleController),
                  _buildFieldLabel('THEATRE'),
                  _buildTheatreDropdown(
                    selectedTheatre,
                    theatres,
                    (val) => setDialogState(() => selectedTheatre = val),
                  ),
                  _buildFieldLabel('GENRE'),
                  _buildStyledField(genreController),
                  _buildFieldLabel('RATING'),
                  _buildRatingDropdown(
                    selectedRating,
                    ratings,
                    (val) => setDialogState(() => selectedRating = val!),
                  ),
                  _buildFieldLabel('DURATION (MIN)'),
                  _buildStyledField(durationController, isNumber: true),
                  _buildFieldLabel('PRICE (LKR)'),
                  _buildStyledField(priceController, isNumber: true),
                  _buildFieldLabel('RELEASE DATE'),
                  _buildDatePickerField(selectedDateStr, () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDateStr =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      });
                    }
                  }),
                  _buildFieldLabel('IMAGE / POSTER URL'),
                  _buildStyledField(imageController),
                  _buildFieldLabel('TRAILER URL'),
                  _buildStyledField(trailerController),
                  _buildFieldLabel('DESCRIPTION'),
                  _buildStyledField(descriptionController, isMultiline: true),
                  _buildFieldLabel('FORMATS'),
                  _buildCheckboxGroup(allFormats, selectedFormats, (
                    val,
                    checked,
                  ) {
                    setDialogState(() {
                      if (checked!) {
                        selectedFormats.add(val);
                      } else {
                        selectedFormats.remove(val);
                      }
                    });
                  }),
                  _buildFieldLabel('LANGUAGES'),
                  _buildCheckboxGroup(allLanguages, selectedLanguages, (
                    val,
                    checked,
                  ) {
                    setDialogState(() {
                      if (checked!) {
                        selectedLanguages.add(val);
                      } else {
                        selectedLanguages.remove(val);
                      }
                    });
                  }),
                  const SizedBox(height: 32),
                  _buildDialogButtons(
                    isUpdate: movie != null,
                    onCancel: () => Navigator.pop(context),
                    onAction: () async {
                      if (titleController.text.isEmpty) return;
                      final img = imageController.text.trim();
                      final priceNum =
                          num.tryParse(priceController.text.trim()) ?? 750;
                      final movieData = <String, dynamic>{
                        'title': titleController.text,
                        'genre': genreController.text,
                        'image': img,
                        'posterUrl': img,
                        'trailerUrl': trailerController.text,
                        'rating': selectedRating,
                        'duration':
                            int.tryParse(durationController.text) ?? 0,
                        'releaseDate': selectedDateStr,
                        'description': descriptionController.text,
                        'formats': selectedFormats,
                        'languages': selectedLanguages,
                        'theatre': selectedTheatre,
                        'price': priceNum,
                      };
                      if (movie?['id'] != null) {
                        movieData['id'] = movie!['id'];
                      }

                      try {
                        if (movie == null) {
                          await MovieService.addMovie(movieData);
                        } else {
                          final src =
                              movie['_adminSource'] as String? ?? 'seed';
                          if (src == 'catalogue') {
                            await MovieService.addMovie(movieData);
                          } else {
                            await MovieService.updateMovie(
                              movie['title']! as String,
                              movieData,
                            );
                          }
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                movie == null
                                    ? 'Movie added successfully'
                                    : 'Movie updated successfully',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                        if (mounted) setState(() {});
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving movie: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStyledField(
    TextEditingController controller, {
    bool isNumber = false,
    bool isMultiline = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: isMultiline ? 4 : 1,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.outfit(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildRatingDropdown(
    String selected,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          items: options
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTheatreDropdown(
    String? selected,
    List<Map<String, dynamic>> theatres,
    Function(String?) onChanged,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: Text(
            'Select Theatre',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          items: theatres
              .map(
                (t) => DropdownMenuItem<String>(
                  value: t['name'] as String,
                  child: Text(
                    t['name'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                date.isEmpty ? 'Select Date' : date,
                style: GoogleFonts.outfit(
                  color: date.isEmpty
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxGroup(
    List<String> all,
    List<String> selected,
    Function(String, bool?) onChanged,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: all.map((item) {
        final isChecked = selected.contains(item);
        return InkWell(
          onTap: () => onChanged(item, !isChecked),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isChecked,
                    onChanged: (val) => onChanged(item, val),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDialogButtons({
    required bool isUpdate,
    required VoidCallback onCancel,
    required VoidCallback onAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            isUpdate ? 'Update' : 'Add',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Cancel',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> movie) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Movie'),
        content: Text(
          'Remove "${movie['title']}" from the admin list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final src = movie['_adminSource'] as String? ?? 'seed';
    if (src == 'catalogue') {
      await AdminCatalogService.suppressMovie(movie['title'] as String);
    } else {
      await MovieService.removeMovie(movie['title'] as String);
    }
    if (mounted) setState(() {});
  }

  Widget _thumb(Map<String, dynamic> movie) {
    final url = (movie['image'] ?? movie['posterUrl'])?.toString() ?? '';
    if (url.isEmpty) {
      return Container(
        width: 50,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Icon(
          Icons.movie,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    if (url.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 50,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 50,
            height: 70,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        url,
        width: 50,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 50,
          height: 70,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.movie,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Movies')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openMovieForm(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      body: Consumer<MovieProvider>(
        builder: (context, prov, _) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: AdminCatalogService.mergeMoviesForAdmin(prov.movies),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final movies = snapshot.data!;
              if (movies.isEmpty) {
                return Center(
                  child: Text(
                    'No movies in this view',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await prov.load(forceRefresh: true);
                  if (mounted) setState(() {});
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  itemCount: movies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _thumb(movie),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie['title']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  movie['genre']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _openMovieForm(movie),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                padding: EdgeInsets.zero,
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(movie),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
