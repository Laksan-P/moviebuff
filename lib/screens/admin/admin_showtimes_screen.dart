import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/showtime_service.dart';
import '../../services/movie_service.dart';
import '../../services/theatre_service.dart';

class AdminShowtimesScreen extends StatefulWidget {
  const AdminShowtimesScreen({super.key});

  @override
  State<AdminShowtimesScreen> createState() => _AdminShowtimesScreenState();
}

class _AdminShowtimesScreenState extends State<AdminShowtimesScreen> {
  List<Map<String, dynamic>> _showtimes = [];
  List<Map<String, dynamic>> _movies = [];
  List<Map<String, dynamic>> _theatres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final showtimes = await ShowtimeService.getShowtimes();
    final movies = await MovieService.getMovies();
    final theatres = await TheatreService.getTheatres();

    if (mounted) {
      setState(() {
        _showtimes = showtimes.reversed.toList();
        _movies = movies;
        _theatres = theatres;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Back to Dashboard',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        titleSpacing: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddShowtimeDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Showtime\nManagement',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage movie schedules and timings',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _showtimes.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            itemCount: _showtimes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final st = _showtimes[index];
                              return _buildShowtimeCard(st);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildShowtimeCard(Map<String, dynamic> st) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        st['theatre'] ?? 'Unknown Theatre',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFF6482AD)
                              : Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        st['movie'] ?? 'Unknown Movie',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15803D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            _buildDetailRow(
              'FORMAT/LANG',
              '${st['format'] ?? '2D'} • ${(st['language'] ?? 'English').toUpperCase()}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'DATE & TIME',
              '${_formatExactDate(st['date'] ?? '')} ${st['time'] ?? 'N/A'}'
                  .toUpperCase(),
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _confirmDelete(st['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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

      final months = [
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
    } catch (e) {
      return dateStr.toUpperCase();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No showtimes scheduled',
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Showtime'),
        content: const Text('Are you sure you want to delete this showtime?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ShowtimeService.deleteShowtime(id);
              if (context.mounted) {
                Navigator.pop(context);
                _loadData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Showtime deleted successfully!',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddShowtimeDialog() {
    String? selectedMovie = _movies.isNotEmpty ? _movies[0]['title'] : null;
    String? selectedTheatre = _theatres.isNotEmpty
        ? _theatres[0]['name']
        : null;
    DateTime selectedDate = DateTime.now();
    String? selectedFormat = '2D';
    String? selectedLanguage = 'English';
    final priceController = TextEditingController(text: '750.0');
    final timeController = TextEditingController(text: '10:00 AM');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (modalContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Add New Showtime',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Movie Section
                  Text(
                    'Movie',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      // ignore: deprecated_member_use
                      value: selectedMovie,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                        hintText: 'Select Movie',
                        hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      items: _movies.map((m) {
                        return DropdownMenuItem(
                          value: m['title'] as String,
                          child: Text(
                            m['title'] as String,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => selectedMovie = v),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Theatre Section
                  Text(
                    'Theatre',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      // ignore: deprecated_member_use
                      value: selectedTheatre,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                        hintText: 'Select Theatre',
                        hintStyle: GoogleFonts.outfit(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      items: _theatres.map((t) {
                        return DropdownMenuItem(
                          value: t['name'] as String,
                          child: Text(
                            t['name'] as String,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedTheatre = v),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Time Section
                  Text(
                    'Time (e.g. 10:00 AM)',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return child!;
                        },
                      );
                      if (picked != null) {
                        // Format time to AM/PM
                        final hour = picked.hourOfPeriod == 0
                            ? 12
                            : picked.hourOfPeriod;
                        final minute = picked.minute.toString().padLeft(2, '0');
                        final period = picked.period == DayPeriod.am
                            ? 'AM'
                            : 'PM';
                        setDialogState(() {
                          timeController.text = '$hour:$minute $period';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeController.text,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Section
                  Text(
                    'Select Date',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Language Section
                  Text(
                    'Language',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      // ignore: deprecated_member_use
                      value: selectedLanguage,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                        hintText: 'Select Language',
                        hintStyle: GoogleFonts.outfit(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      items: ['English', 'Tamil', 'Sinhala', 'Hindi'].map((l) {
                        return DropdownMenuItem(
                          value: l,
                          child: Text(l, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedLanguage = v),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Format Section
                  Text(
                    'Format',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      // ignore: deprecated_member_use
                      value: selectedFormat,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                        hintText: 'Select Format',
                        hintStyle: GoogleFonts.outfit(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      items: ['2D', '3D', 'IMAX', '4DX'].map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedFormat = v),
                    ),
                  ),
                  // Price Section
                  Text(
                    'Price (LKR)',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                        hintText: 'Enter Price',
                        hintStyle: GoogleFonts.outfit(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedMovie != null &&
                                  selectedTheatre != null) {
                                final showtimeData = {
                                  'movie': selectedMovie,
                                  'theatre': selectedTheatre,
                                  'time': timeController.text,
                                  'date':
                                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                                  'format': selectedFormat,
                                  'language': selectedLanguage,
                                  'label': selectedFormat,
                                  'price':
                                      double.tryParse(priceController.text) ??
                                      0.0,
                                };

                                debugPrint(
                                  '🎬 ADMIN - Adding showtime: $showtimeData',
                                );
                                await ShowtimeService.addShowtime(showtimeData);

                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                                await _loadData();

                                if (mounted) {
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Showtime added successfully!',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Add',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      ),
    );
  }
}
