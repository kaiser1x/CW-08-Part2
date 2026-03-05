class PlayingCard {
  final int? id;
  final String cardName;
  final String suit;
  final String? imageUrl;
  final int folderId;
  final bool isFavorite;
  final String? notes;

  PlayingCard({
    this.id,
    required this.cardName,
    required this.suit,
    this.imageUrl,
    required this.folderId,
    this.isFavorite = false,
    this.notes,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'card_name': cardName,
      'suit': suit,
      'image_url': imageUrl,
      'folder_id': folderId,
      'is_favorite': isFavorite ? 1 : 0,
      'notes': notes,
    };
  }

  factory PlayingCard.fromMap(Map<String, dynamic> map) {
    return PlayingCard(
      id: map['id'] as int?,
      cardName: map['card_name'] as String,
      suit: map['suit'] as String,
      imageUrl: map['image_url'] as String?,
      folderId: map['folder_id'] as int,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
    );
  }

  PlayingCard copyWith({
    int? id,
    String? cardName,
    String? suit,
    String? imageUrl,
    int? folderId,
    bool? isFavorite,
    String? notes,
  }) {
    return PlayingCard(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      suit: suit ?? this.suit,
      imageUrl: imageUrl ?? this.imageUrl,
      folderId: folderId ?? this.folderId,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'PlayingCard{id: $id, cardName: $cardName, suit: $suit, folderId: $folderId}';
  }
}