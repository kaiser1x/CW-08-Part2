import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/folder.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';

/// Export screen allowing users to export card decks in various formats.
/// Supports CSV and JSON export formats that can be shared or saved.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final FolderRepository _folderRepository = FolderRepository();
  final CardRepository _cardRepository = CardRepository();
  List<Folder> _folders = [];
  bool _isLoading = true;
  String? _selectedFolderId;
  String _exportFormat = 'json'; // 'json' or 'csv'

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  /// Load all folders.
  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    try {
      final folders = await _folderRepository.getAllFolders();
      setState(() {
        _folders = folders;
        if (folders.isNotEmpty) {
          _selectedFolderId = folders.first.id.toString();
        }
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

  /// Generate JSON export for selected folder.
  Future<String> _generateJsonExport(int folderId) async {
    try {
      final folder = await _folderRepository.getFolderById(folderId);
      final cards = await _cardRepository.getCardsByFolderId(folderId);

      final exportData = {
        'folder': folder?.toMap(),
        'cards': cards.map((c) => c.toMap()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'totalCards': cards.length,
      };

      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      throw 'Error generating JSON: $e';
    }
  }

  /// Generate CSV export for selected folder.
  Future<String> _generateCsvExport(int folderId) async {
    try {
      final folder = await _folderRepository.getFolderById(folderId);
      final cards = await _cardRepository.getCardsByFolderId(folderId);

      final buffer = StringBuffer();

      // Header
      buffer.writeln('Folder,Card ID,Card Name,Suit,Image URL');

      // Rows
      for (var card in cards) {
        final folderName = folder?.folderName ?? 'Unknown';
        final cardName = card.cardName.replaceAll(',', ';');
        final suit = card.suit;
        final imageUrl = (card.imageUrl ?? '').replaceAll(',', ';');

        buffer.writeln(
          '$folderName,${card.id},$cardName,$suit,$imageUrl',
        );
      }

      return buffer.toString();
    } catch (e) {
      throw 'Error generating CSV: $e';
    }
  }

  /// Export and share the deck.
  Future<void> _export() async {
    if (_selectedFolderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a folder')),
      );
      return;
    }

    try {
      final folderId = int.parse(_selectedFolderId!);
      final folder = await _folderRepository.getFolderById(folderId);

      String content;
      if (_exportFormat == 'json') {
        content = await _generateJsonExport(folderId);
      } else {
        content = await _generateCsvExport(folderId);
      }

      // Show export content in dialog with copy option
      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text('${folder?.folderName} - ${_exportFormat.toUpperCase()}'),
              content: SingleChildScrollView(
                child: SelectableText(content),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                    Navigator.pop(dialogContext);
                  },
                  icon: const Icon(Icons.content_copy),
                  label: const Text('Copy'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Deck'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Card(
                    color: Colors.blue.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Your Deck',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Export your card deck in JSON or CSV format. '
                            'The exported file can be shared or imported later.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Folder selection
                  const Text(
                    'Select Folder',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedFolderId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.folder),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _folders.map((folder) {
                      return DropdownMenuItem(
                        value: folder.id.toString(),
                        child: Text(folder.folderName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedFolderId = value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Format selection
                  const Text(
                    'Export Format',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('JSON Format'),
                        subtitle: const Text('Human-readable JSON file'),
                        value: 'json',
                        groupValue: _exportFormat,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _exportFormat = value);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('CSV Format'),
                        subtitle: const Text('Comma-separated values (spreadsheet)'),
                        value: 'csv',
                        groupValue: _exportFormat,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _exportFormat = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Export button
                  ElevatedButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.share),
                    label: const Text('Export & Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Format examples
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Format Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'JSON: Preserves all deck information including folder metadata '
                            'and can be re-imported to restore the deck.',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'CSV: Spreadsheet-friendly format. Open in Excel, Google Sheets, '
                            'or any spreadsheet application.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
