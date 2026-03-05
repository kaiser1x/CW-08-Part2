import 'package:flutter/material.dart';

import '../models/card.dart';
import '../models/folder.dart';
import '../repositories/card_repository.dart';
import 'add_edit_card_screen.dart';

/// Displays all 13 cards for a selected suit folder.
/// Users can view card images, names, suits, and edit/delete individual cards.
/// Also provides a button to add new cards to the folder.
class CardsScreen extends StatefulWidget {
  final Folder folder;

  const CardsScreen({super.key, required this.folder});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final CardRepository _cardRepository = CardRepository();
  List<PlayingCard> _cards = [];
  List<PlayingCard> _filteredCards = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCards();
    _searchController.addListener(_filterCards);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load all cards for this folder from the database.
  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final cards = await _cardRepository.getCardsByFolderId(widget.folder.id!);
      setState(() {
        _cards = cards;
        _filteredCards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cards: $e')),
        );
      }
    }
  }

  /// Filter cards based on search query (case-insensitive name match).
  void _filterCards() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredCards = _cards);
    } else {
      setState(() {
        _filteredCards = _cards
            .where((card) => card.cardName.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  /// Delete a card with confirmation.
  Future<void> _deleteCard(PlayingCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Card'),
          content: Text('Delete ${card.cardName} of ${card.suit}?'),
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
        await _cardRepository.deleteCard(card.id!);
        await _loadCards();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${card.cardName} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting card: $e')),
          );
        }
      }
    }
  }

  /// Navigate to add/edit card screen.
  void _navigateToAddEditCard([PlayingCard? card]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCardScreen(folder: widget.folder, card: card),
      ),
    ).then((_) => _loadCards()); // Refresh list on return
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folder.folderName} Cards'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search cards (e.g., Ace, King)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Cards grid or empty state
                Expanded(
                  child: _filteredCards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.credit_card,
                                  size: 80, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No cards found'
                                    : 'No cards match "${_searchController.text}"',
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: _filteredCards.length,
                          itemBuilder: (context, index) {
                            final card = _filteredCards[index];
                            return _buildCardTile(card);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditCard(),
        tooltip: 'Add new card',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build a card tile with image, name, suit, and action buttons.
  Widget _buildCardTile(PlayingCard card) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card image or placeholder
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                color: Colors.grey[200],
                child: card.imageUrl != null && card.imageUrl!.isNotEmpty
                    ? Image.network(
                        card.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                                const SizedBox(height: 4),
                                Text(
                                  card.cardName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              '${card.cardName} of\n${card.suit}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          // Card details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.cardName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  card.suit,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Edit and Delete buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _navigateToAddEditCard(card),
                    tooltip: 'Edit',
                  ),
                ),
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _deleteCard(card),
                    tooltip: 'Delete',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
