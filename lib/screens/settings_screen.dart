import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../database_helper.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';

/// Settings screen allowing users to:
/// - Configure the number of suits (2, 3, or 4)
/// - Reset the database to initial state
/// - View app information
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FolderRepository _folderRepository = FolderRepository();
  final CardRepository _cardRepository = CardRepository();
  bool _isResetting = false;

  /// Reset the database and recreate folders and cards.
  /// New folders are added based on the selected suit count.
  Future<void> _resetDatabase(int suitCount) async {
    final BuildContext primaryContext = context as BuildContext;
    
    final confirmed = await showDialog<bool>(
      context: primaryContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Database'),
          content: Text(
            'This will delete all folders and cards, then recreate the database '
            'with $suitCount suits (${suitCount * 13} cards).\n\nAre you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isResetting = true);

    try {
      // Close and delete database
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.close();

      // Delete the database file
      final dbPath = await sqflite.getDatabasesPath();
      final path = join(dbPath, 'card_organizer.db');
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }

      // Reinitialize database (will run onCreate)
      await dbHelper.database;

      if (mounted) {
        ScaffoldMessenger.of(primaryContext).showSnackBar(
          SnackBar(
            content: Text('Database reset to $suitCount suits (${ suitCount * 13} cards)'),
          ),
        );
        Navigator.pop(primaryContext, true); // Signal success to refresh home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(primaryContext).showSnackBar(
          SnackBar(content: Text('Error resetting database: $e')),
        );
      }
    } finally {
      setState(() => _isResetting = false);
    }
  }

  /// Get current folder count from database.
  Future<int> _getFolderCount() async {
    try {
      final folders = await _folderRepository.getAllFolders();
      return folders.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total card count from database.
  Future<int> _getTotalCardCount() async {
    try {
      final cards = await _cardRepository.getAllCards();
      return cards.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Database Statistics Section
            const Text(
              'Database Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    FutureBuilder<int>(
                      future: _getFolderCount(),
                      builder: (context, snapshot) {
                        return ListTile(
                          leading: const Icon(Icons.folder),
                          title: const Text('Total Folders'),
                          trailing: Text(
                            snapshot.hasData ? '${snapshot.data}' : 'Loading...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    FutureBuilder<int>(
                      future: _getTotalCardCount(),
                      builder: (context, snapshot) {
                        return ListTile(
                          leading: const Icon(Icons.credit_card),
                          title: const Text('Total Cards'),
                          trailing: Text(
                            snapshot.hasData ? '${snapshot.data}' : 'Loading...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Configure Database Section
            const Text(
              'Configure Database',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select the number of suits to prepopulate:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Reset buttons for 2, 3, 4 suits
            ...[2, 3, 4].map((suits) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: _isResetting ? null : () => _resetDatabase(suits),
                  icon: _isResetting ? const SizedBox() : const Icon(Icons.refresh),
                  label: Text(
                    'Reset with $suits suits (${suits * 13} cards)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 32),

            // About Section
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info),
                      title: Text('App Name'),
                      trailing: Text('Card Organizer'),
                    ),
                    const Divider(),
                    const ListTile(
                      leading: Icon(Icons.storage),
                      title: Text('Storage'),
                      trailing: Text('SQLite'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.key),
                      title: const Text('Features'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        _showFeatures();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                'Card Organizer v1.0.0',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show a dialog listing all app features.
  void _showFeatures() {
    final BuildContext primaryContext = context as BuildContext;
    
    showDialog(
      context: primaryContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Features'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFeatureItem('🂡 Organize cards into suit folders'),
                _buildFeatureItem('📋 CRUD operations (Create, Read, Update, Delete)'),
                _buildFeatureItem('💾 SQLite database with foreign keys'),
                _buildFeatureItem('🔒 Cascade delete protection'),
                _buildFeatureItem('🖼️  Card image support (online URLs)'),
                _buildFeatureItem('🔍 Search and filter cards'),
                _buildFeatureItem('📊 Database statistics'),
                _buildFeatureItem('⚙️  Configurable suit count (2-4)'),
                _buildFeatureItem('🗑️  Database reset functionality'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Helper to build a feature list item.
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}

