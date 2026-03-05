import 'package:flutter/material.dart';

import '../models/card.dart';
import '../models/folder.dart';
import '../repositories/card_repository.dart';

/// Form screen to create a new card or edit an existing one.
/// Fields: card name, suit selection, image URL, folder assignment, save/cancel buttons.
/// Used in the context of a specific folder and can auto-populate fields for editing.
class AddEditCardScreen extends StatefulWidget {
  final Folder folder;
  final PlayingCard? card; // If provided, we're editing; otherwise creating

  const AddEditCardScreen({
    super.key,
    required this.folder,
    this.card,
  });

  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final CardRepository _cardRepository = CardRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cardNameController;
  late TextEditingController _imageUrlController;
  late TextEditingController _notesController;
  late String _selectedSuit;
  bool _isSaving = false;

  final List<String> _suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];

  @override
  void initState() {
    super.initState();
    _cardNameController = TextEditingController(
      text: widget.card?.cardName ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.card?.imageUrl ?? '',
    );
    _notesController = TextEditingController(
      text: widget.card?.notes ?? '',
    );
    _selectedSuit = widget.card?.suit ?? widget.folder.folderName;
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _imageUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Save the card (insert or update) to the database.
  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (widget.card == null) {
        // Create new card
        final newCard = PlayingCard(
          cardName: _cardNameController.text.trim(),
          suit: _selectedSuit,
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          folderId: widget.folder.id!,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        await _cardRepository.insertCard(newCard);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${newCard.cardName} added to ${widget.folder.folderName}'),
            ),
          );
        }
      } else {
        // Update existing card
        final updatedCard = widget.card!.copyWith(
          cardName: _cardNameController.text.trim(),
          suit: _selectedSuit,
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        await _cardRepository.updateCard(updatedCard);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${updatedCard.cardName} updated')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving card: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.card != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Card' : 'Add New Card'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Folder info
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, color: Colors.blue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Folder:', style: TextStyle(fontSize: 12)),
                          Text(
                            widget.folder.folderName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Card name field
              TextFormField(
                controller: _cardNameController,
                decoration: InputDecoration(
                  labelText: 'Card Name',
                  hintText: 'e.g., Ace, King, 2...',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a card name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Suit selection dropdown
              DropdownButtonFormField<String>(
                value: _selectedSuit,
                decoration: InputDecoration(
                  labelText: 'Suit',
                  prefixIcon: const Icon(Icons.casino),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _suits.map((suit) {
                  return DropdownMenuItem(
                    value: suit,
                    child: Text(suit),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSuit = value);
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a suit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image URL field
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Image URL or asset path (optional)',
                  hintText: 'https://example.com/card.png or assets/cards/AS.png',
                  prefixIcon: const Icon(Icons.image),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText:
                      'Leave empty for placeholder. Example:\nhttps://deckofcardsapi.com/static/img/AS.png',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes field
              TextFormField(
                controller: _notesController,
                maxLines: null,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add personal notes about this card...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: 'Personal notes - 500 characters max',
                ),
              ),
              const SizedBox(height: 20),

              // Image preview
              if (_imageUrlController.text.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Image Preview:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Builder(builder: (context) {
                        String input = _imageUrlController.text.trim();
                        if (input.isEmpty) return const SizedBox.shrink();
                        if (!input.startsWith('http') && !input.startsWith('assets/')) {
                          input = 'assets/cards/$input';
                        }
                        if (input.startsWith('http')) {
                          return Image.network(
                            input,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          color: Colors.grey, size: 48),
                                      SizedBox(height: 8),
                                      Text('Failed to load image'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          return Image.asset(
                            input,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          color: Colors.grey, size: 48),
                                      SizedBox(height: 8),
                                      Text('Failed to load image'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      }),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveCard,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(isEditing ? 'Update Card' : 'Add Card'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
