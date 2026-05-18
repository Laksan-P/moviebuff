import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/movie_provider.dart';
import '../../services/admin_catalog_service.dart';
import '../../services/theatre_service.dart';

class AdminTheatresScreen extends StatefulWidget {
  const AdminTheatresScreen({super.key});

  @override
  State<AdminTheatresScreen> createState() => _AdminTheatresScreenState();
}

class _AdminTheatresScreenState extends State<AdminTheatresScreen> {
  void _showTheatreDialog({Map<String, dynamic>? theatre}) {
    final nameController = TextEditingController(text: theatre?['name']?.toString());
    final locationController = TextEditingController(
      text: theatre?['location']?.toString(),
    );
    final descriptionController = TextEditingController(
      text: theatre?['description']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _buildFieldLabel('THEATRE NAME'),
              _buildTextField(nameController, 'Enter Name'),
              const SizedBox(height: 16),
              _buildFieldLabel('LOCATION'),
              _buildTextField(locationController, 'Enter Location'),
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
                    if (nameController.text.isEmpty) return;
                    final newTheatre = {
                      'name': nameController.text,
                      'location': locationController.text,
                      'description': descriptionController.text,
                    };

                    if (theatre == null) {
                      await TheatreService.addTheatre(newTheatre);
                    } else {
                      final src = theatre['_adminSource'] as String? ?? 'seed';
                      if (src == 'catalogue') {
                        await TheatreService.addTheatre(newTheatre);
                      } else {
                        final raw = await TheatreService.getTheatres();
                        final idx = raw.indexWhere(
                          (t) => t['name'] == theatre['name'],
                        );
                        if (idx >= 0) {
                          await TheatreService.updateTheatre(idx, newTheatre);
                        } else {
                          await TheatreService.addTheatre(newTheatre);
                        }
                      }
                    }

                    if (!context.mounted) return;
                    await context.read<MovieProvider>().refreshAfterAdminEdit();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
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
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        fillColor: Theme.of(context).colorScheme.surface,
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

  Future<void> _confirmDelete(Map<String, dynamic> theatre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to remove "${theatre['name']}" from the admin list?',
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

    final src = theatre['_adminSource'] as String? ?? 'seed';
    if (src == 'catalogue') {
      await AdminCatalogService.suppressTheatre(theatre['name'] as String);
    } else {
      await TheatreService.removeTheatreByName(theatre['name'] as String);
    }
    if (mounted) {
      await context.read<MovieProvider>().refreshAfterAdminEdit();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Theatres'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTheatreDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
      body: Consumer<MovieProvider>(
        builder: (context, prov, _) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: AdminCatalogService.mergeTheatresForAdmin(prov.movies),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final theatres = snapshot.data!;
              if (theatres.isEmpty) {
                return Center(
                  child: Text(
                    'No theatres in this view',
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
                  if (context.mounted) setState(() {});
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  itemCount: theatres.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final theatre = theatres[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theatre['name']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  theatre['location']?.toString() ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showTheatreDialog(theatre: theatre),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(theatre),
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
