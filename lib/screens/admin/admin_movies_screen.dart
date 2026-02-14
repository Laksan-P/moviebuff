import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/movie_service.dart';
import '../../services/theatre_service.dart';

class AdminMoviesScreen extends StatefulWidget {
  const AdminMoviesScreen({super.key});

  @override
  State<AdminMoviesScreen> createState() => _AdminMoviesScreenState();
}

class _AdminMoviesScreenState extends State<AdminMoviesScreen> {
  List<Map<String, dynamic>> _movies = [];
  List<Map<String, dynamic>> _theatres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      MovieService.getMovies(),
      TheatreService.getTheatres(),
    ]);
    if (mounted) {
      setState(() {
        _movies = results[0];
        _theatres = results[1];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMovies() async {
    final movies = await MovieService.getMovies();
    if (mounted) {
      setState(() {
        _movies = movies;
      });
    }
  }

  void _showAddMovieDialog() {
    _showMovieFormDialog();
  }

  void _showMovieFormDialog([Map<String, dynamic>? movie]) {
    final titleController = TextEditingController(text: movie?['title'] ?? '');
    final genreController = TextEditingController(text: movie?['genre'] ?? '');
    final imageController = TextEditingController(text: movie?['image'] ?? '');
    final trailerController = TextEditingController(
      text: movie?['trailerUrl'] ?? '',
    );
    final durationController = TextEditingController(
      text: movie?['duration']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: movie?['description'] ?? '',
    );

    String selectedRating = movie?['rating'] ?? 'PG-13';
    String selectedDateStr = movie?['releaseDate'] ?? '';
    String? selectedTheatre = movie?['theatre'];

    List<String> selectedFormats = List<String>.from(
      movie?['formats'] ?? ['2D'],
    );
    List<String> selectedLanguages = List<String>.from(
      movie?['languages'] ?? ['English'],
    );

    final ratings = ['G', 'PG', 'PG-13', 'R', 'NC-17'];
    final allFormats = ['2D', '3D', 'IMAX', '4DX'];
    final allLanguages = ['English', 'Hindi', 'Tamil', 'Telugu'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xffAFB8B9),
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
                      color: const Color(0xFF020617),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildFieldLabel('MOVIE TITLE'),
                  _buildStyledField(titleController),

                  _buildFieldLabel('THEATRE'),
                  _buildTheatreDropdown(
                    selectedTheatre,
                    _theatres,
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
                            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
                      });
                    }
                  }),

                  _buildFieldLabel('IMAGE URL'),
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
                      if (titleController.text.isNotEmpty) {
                        final movieData = {
                          'title': titleController.text,
                          'genre': genreController.text,
                          'image': imageController.text,
                          'trailerUrl': trailerController.text,
                          'rating': selectedRating,
                          'duration':
                              int.tryParse(durationController.text) ?? 0,
                          'releaseDate': selectedDateStr,
                          'description': descriptionController.text,
                          'formats': selectedFormats,
                          'languages': selectedLanguages,
                          'theatre': selectedTheatre,
                        };

                        try {
                          if (movie == null) {
                            await MovieService.addMovie(movieData);
                          } else {
                            await MovieService.updateMovie(
                              movie['title']!,
                              movieData,
                            );
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
                          _loadMovies();
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
          color: const Color(0xFF455A64),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: isMultiline ? 4 : 1,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.outfit(),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          items: options
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: GoogleFonts.outfit()),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: Text('Select Theatre', style: GoogleFonts.outfit()),
          isExpanded: true,
          items: theatres
              .map(
                (t) => DropdownMenuItem<String>(
                  value: t['name'] as String,
                  child: Text(t['name'] as String, style: GoogleFonts.outfit()),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date.isEmpty ? 'Select Date' : date,
              style: GoogleFonts.outfit(
                color: date.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
            const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
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
                    activeColor: const Color(0xFF6D87AE),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF020617),
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
            backgroundColor: const Color(0xFF6D87AE),
            foregroundColor: Colors.white,
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
            foregroundColor: const Color(0xFF6D87AE),
            side: const BorderSide(color: Color(0xFF6D87AE)),
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

  void _showEditMovieDialog(Map<String, dynamic> movie) {
    _showMovieFormDialog(movie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Movies')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMovieDialog,
        backgroundColor: AppColors.cinemaRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _movies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final movie = _movies[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image:
                              movie['image'] != null &&
                                  movie['image']!.isNotEmpty
                              ? DecorationImage(
                                  image: movie['image']!.startsWith('http')
                                      ? NetworkImage(movie['image']!)
                                      : AssetImage(movie['image']!)
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.grey[200],
                        ),
                        child: movie['image'] == null || movie['image']!.isEmpty
                            ? const Icon(Icons.movie, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie['title']!,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              movie['genre']!,
                              style: GoogleFonts.outfit(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditMovieDialog(movie),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Movie'),
                              content: Text('Delete "${movie['title']}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await MovieService.removeMovie(movie['title']!);
                            _loadMovies();
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
