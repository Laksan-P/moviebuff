import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../services/theatre_service.dart';

class AdminTheatresScreen extends StatefulWidget {
  const AdminTheatresScreen({super.key});

  @override
  State<AdminTheatresScreen> createState() => _AdminTheatresScreenState();
}

class _AdminTheatresScreenState extends State<AdminTheatresScreen> {
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

  void _showTheatreDialog({Map<String, dynamic>? theatre, int? index}) {
    final nameController = TextEditingController(text: theatre?['name']);
    final locationController = TextEditingController(
      text: theatre?['location'],
    );
    final descriptionController = TextEditingController(
      text: theatre?['description'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(
          0xFFAFB8B9,
        ), // Slate grey as per user screenshot
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 32,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                theatre == null ? 'Add New Theatre' : 'Edit Theatre',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF020617),
                ),
              ),
              const SizedBox(height: 24),

              _buildFieldLabel('THEATRE NAME'),
              _buildTextField(nameController, 'Enter Name'),

              const SizedBox(height: 16),
              _buildFieldLabel('LOCATION'),
              _buildTextField(locationController, 'Enter Location'),

              const SizedBox(height: 16),

              const SizedBox(height: 16),
              _buildFieldLabel('DESCRIPTION'),
              _buildTextField(
                descriptionController,
                'Enter Description',
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final newTheatre = {
                        'name': nameController.text,
                        'location': locationController.text,
                        'description': descriptionController.text,
                      };

                      if (theatre == null) {
                        await TheatreService.addTheatre(newTheatre);
                      } else if (index != null) {
                        await TheatreService.updateTheatre(index, newTheatre);
                      }

                      if (context.mounted) Navigator.pop(context);
                      _loadTheatres();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D87AE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    theatre == null ? 'Create Theatre' : 'Update Theatre',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6D87AE)),
                    foregroundColor: const Color(0xFF020617),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF455A64),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumeric = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      style: GoogleFonts.outfit(fontSize: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Theatres'),
        backgroundColor: const Color(0xFF020617),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTheatreDialog(),
        backgroundColor: AppColors.cinemaRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _theatres.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final theatre = _theatres[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theatre['name'] as String,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              theatre['location'] as String,
                              style: GoogleFonts.outfit(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showTheatreDialog(theatre: theatre, index: index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text(
                                'Are you sure you want to delete "${theatre['name']}"? This cannot be undone.',
                              ),
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
                            await TheatreService.removeTheatre(index);
                            _loadTheatres();
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
