import 'package:flutter/material.dart';

import '../models/folder.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';
import 'cards_screen.dart';
import 'export_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

/// The main screen that displays 2-4 suit folders in a grid.
/// Each folder card shows the suit icon, name, card count, and delete button.
/// Tapping a folder navigates to the cards view for that suit.
class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final FolderRepository _folderRepository = FolderRepository();
  List<Folder> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  /// Load all folders from the database.
  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    try {
      final folders = await _folderRepository.getAllFolders();
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading folders: $e')),
        );
      }
    }
  }

  /// Delete a folder and all its associated cards (cascade delete).
  /// Shows a confirmation dialog before deletion.
  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text(
            'Are you sure you want to delete "${folder.folderName}"? '
            'All cards in this folder will be deleted.',
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
        );
      },
    );

    if (confirmed == true) {
      try {
        await _folderRepository.deleteFolder(folder.id!);
        await _loadFolders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${folder.folderName} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting folder: $e')),
          );
        }
      }
    }
  }

  /// Map suit names to emoji icons and colors.
  String _getSuitIcon(String suitName) {
    return switch (suitName.toLowerCase()) {
      'hearts' => '♥️',
      'diamonds' => '♦️',
      'clubs' => '♣️',
      'spades' => '♠️',
      _ => '🂠',
    };
  }

  Color _getSuitColor(String suitName) {
    return switch (suitName.toLowerCase()) {
      'hearts' => Colors.red,
      'diamonds' => Colors.red,
      'clubs' => Colors.black,
      'spades' => Colors.black,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          // Export button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export deck',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              );
            },
          ),
          // Statistics button
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((result) {
                if (result == true) {
                  // Database was reset, refresh folders
                  _loadFolders();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No folders found'),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    return _buildFolderCard(folder);
                  },
                ),
    );
  }

  /// Build a single folder card displaying suit, name, card count, and delete.
  Widget _buildFolderCard(Folder folder) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to cards screen for this folder
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CardsScreen(folder: folder),
            ),
          ).then((_) => _loadFolders()); // Refresh on return
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Suit icon
            Text(
              _getSuitIcon(folder.folderName),
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 8),
            // Suit name
            Text(
              folder.folderName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Card count (will be fetched from DB)
            FutureBuilder<int>(
              future: _getCardCount(folder.id!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    '${snapshot.data} cards',
                    style: TextStyle(
                      fontSize: 14,
                      color: _getSuitColor(folder.folderName),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return const Text('Loading...');
              },
            ),
            const SizedBox(height: 12),
            // Delete button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: () => _deleteFolder(folder),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to get card count for a folder.
  Future<int> _getCardCount(int folderId) async {
    try {
      final cardRepo = CardRepository();
      return await cardRepo.getCardCountByFolder(folderId);
    } catch (e) {
      return 0;
    }
  }
}
