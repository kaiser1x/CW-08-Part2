import 'package:flutter/material.dart';

import '../models/folder.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';

/// Statistics screen showing a summary of the card collection.
/// Displays total cards, card count per suit, and deck composition.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FolderRepository _folderRepository = FolderRepository();
  final CardRepository _cardRepository = CardRepository();
  List<Folder> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// Load all folders and prepare statistics data.
  Future<void> _loadStatistics() async {
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
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  /// Get card count for a specific folder.
  Future<int> _getCardCount(int folderId) async {
    try {
      return await _cardRepository.getCardCountByFolder(folderId);
    } catch (e) {
      return 0;
    }
  }

  /// Get total card count.
  Future<int> _getTotalCards() async {
    int total = 0;
    for (var folder in _folders) {
      total += await _getCardCount(folder.id!);
    }
    return total;
  }

  /// Get color for suit name.
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
        title: const Text('Statistics'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Cards Summary
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.bar_chart, size: 48, color: Colors.blue),
                          const SizedBox(height: 12),
                          const Text(
                            'Total Cards',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<int>(
                            future: _getTotalCards(),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.hasData ? '${snapshot.data}' : '0',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Suit Breakdown Header
                  const Text(
                    'Suit Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Suit cards
                  ..._folders.map((folder) {
                    return _buildSuitStatCard(folder);
                  }).toList(),

                  const SizedBox(height: 24),

                  // Deck Composition Info
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Standard Deck Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Cards per suit:', '13'),
                          _buildInfoRow('Number of suits:', '${_folders.length}'),
                          FutureBuilder<int>(
                            future: _getTotalCards(),
                            builder: (context, snapshot) {
                              return _buildInfoRow(
                                'Total cards:',
                                snapshot.hasData ? '${snapshot.data}' : '0',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Card Names Reference
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card Names in Deck',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Ace', '2', '3', '4', '5', '6', '7',
                              '8', '9', '10', 'Jack', 'Queen', 'King'
                            ]
                                .map((card) => Chip(
                                      label: Text(card),
                                      backgroundColor: Colors.blue.shade100,
                                    ))
                                .toList(),
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

  /// Build a card showing statistics for a single suit.
  Widget _buildSuitStatCard(Folder folder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Suit icon background
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getSuitColor(folder.folderName).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getSuitIcon(folder.folderName),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Suit name and card count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.folderName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: _getCardCount(folder.id!),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.hasData
                            ? '${snapshot.data} cards'
                            : 'Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          color: _getSuitColor(folder.folderName),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Card count badge
            FutureBuilder<int>(
              future: _getCardCount(folder.id!),
              builder: (context, snapshot) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getSuitColor(folder.folderName).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    snapshot.hasData ? '${snapshot.data}' : '0',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getSuitColor(folder.folderName),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build an info row in the deck information card.
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Get suit icon emoji.
  String _getSuitIcon(String suitName) {
    return switch (suitName.toLowerCase()) {
      'hearts' => '♥️',
      'diamonds' => '♦️',
      'clubs' => '♣️',
      'spades' => '♠️',
      _ => '🂠',
    };
  }
}
