import 'package:flutter_test/flutter_test.dart';

import 'package:class_activity_p2/models/card.dart';

/// Mirror of _filterCards logic from CardsScreen — tests the pure filtering
/// and sorting logic without needing a widget or database.
List<PlayingCard> filterCards(
  List<PlayingCard> cards, {
  String query = '',
  String? filterBySuit,
  bool showOnlyFavorites = false,
  String sortBy = 'name',
}) {
  final filtered = cards.where((card) {
    final matchesSearch =
        query.isEmpty || card.cardName.toLowerCase().contains(query.toLowerCase());
    final matchesSuit = filterBySuit == null || card.suit == filterBySuit;
    final matchesFavorite = !showOnlyFavorites || card.isFavorite;
    return matchesSearch && matchesSuit && matchesFavorite;
  }).toList();

  if (sortBy == 'suit') {
    filtered.sort((a, b) => a.suit.compareTo(b.suit));
  } else {
    filtered.sort((a, b) => a.cardName.compareTo(b.cardName));
  }
  return filtered;
}

PlayingCard makeCard({
  int? id,
  String cardName = 'Ace',
  String suit = 'Hearts',
  int folderId = 1,
  bool isFavorite = false,
  String? notes,
}) {
  return PlayingCard(
    id: id,
    cardName: cardName,
    suit: suit,
    folderId: folderId,
    isFavorite: isFavorite,
    notes: notes,
  );
}

void main() {
  // ── PlayingCard model ────────────────────────────────────────────────────

  group('PlayingCard model', () {
    test('creates with correct default values', () {
      final card = makeCard(id: 1, cardName: 'Ace', suit: 'Hearts');
      expect(card.cardName, 'Ace');
      expect(card.suit, 'Hearts');
      expect(card.isFavorite, false);
      expect(card.notes, isNull);
    });

    test('toMap serializes isFavorite as 1 when true', () {
      final card = makeCard(isFavorite: true);
      expect(card.toMap()['is_favorite'], 1);
    });

    test('toMap serializes isFavorite as 0 when false', () {
      final card = makeCard(isFavorite: false);
      expect(card.toMap()['is_favorite'], 0);
    });

    test('fromMap deserializes isFavorite = 1 as true', () {
      final card = PlayingCard.fromMap({
        'id': 1,
        'card_name': 'King',
        'suit': 'Spades',
        'image_url': null,
        'folder_id': 1,
        'is_favorite': 1,
        'notes': null,
      });
      expect(card.isFavorite, true);
    });

    test('fromMap deserializes isFavorite = 0 as false', () {
      final card = PlayingCard.fromMap({
        'id': 2,
        'card_name': 'Queen',
        'suit': 'Clubs',
        'image_url': null,
        'folder_id': 1,
        'is_favorite': 0,
        'notes': null,
      });
      expect(card.isFavorite, false);
    });

    test('fromMap defaults isFavorite to false when null', () {
      final card = PlayingCard.fromMap({
        'id': 3,
        'card_name': 'Jack',
        'suit': 'Diamonds',
        'image_url': null,
        'folder_id': 1,
        'is_favorite': null,
        'notes': null,
      });
      expect(card.isFavorite, false);
    });

    test('copyWith preserves unchanged fields', () {
      final card = makeCard(id: 1, cardName: 'Ace', suit: 'Hearts', isFavorite: false);
      final toggled = card.copyWith(isFavorite: true);
      expect(toggled.isFavorite, true);
      expect(toggled.id, card.id);
      expect(toggled.cardName, card.cardName);
      expect(toggled.suit, card.suit);
    });

    test('copyWith with no args returns equivalent card', () {
      final card = makeCard(id: 1, cardName: 'Ten', suit: 'Clubs', isFavorite: true);
      final copy = card.copyWith();
      expect(copy.cardName, card.cardName);
      expect(copy.suit, card.suit);
      expect(copy.isFavorite, card.isFavorite);
    });
  });

  // ── Favorites filter ─────────────────────────────────────────────────────

  group('Favorites filter - All Suits tab', () {
    // Cards spanning all four suits
    final allCards = [
      makeCard(id: 1, cardName: 'Ace',   suit: 'Hearts',   isFavorite: true),
      makeCard(id: 2, cardName: 'King',  suit: 'Spades',   isFavorite: true),
      makeCard(id: 3, cardName: 'Queen', suit: 'Clubs',    isFavorite: false),
      makeCard(id: 4, cardName: 'Jack',  suit: 'Diamonds', isFavorite: true),
      makeCard(id: 5, cardName: 'Ten',   suit: 'Hearts',   isFavorite: false),
    ];

    test('All Suits + Favorites returns every favorited card across all suits', () {
      final result = filterCards(allCards, showOnlyFavorites: true);
      expect(result.length, 3);
      expect(result.every((c) => c.isFavorite), true);
    });

    test('All Suits + Favorites includes cards from different suits', () {
      final result = filterCards(allCards, showOnlyFavorites: true);
      final suits = result.map((c) => c.suit).toSet();
      expect(suits, containsAll(['Hearts', 'Spades', 'Diamonds']));
    });

    test('All Suits without Favorites returns all cards', () {
      final result = filterCards(allCards);
      expect(result.length, 5);
    });

    test('Favorites filter off does not exclude non-favorites', () {
      final result = filterCards(allCards, filterBySuit: 'Hearts');
      // Hearts has Ace (fav) and Ten (not fav) — both should appear
      expect(result.length, 2);
    });

    test('no favorited cards returns empty list', () {
      final noFavs = [
        makeCard(id: 1, cardName: 'Two', suit: 'Hearts',   isFavorite: false),
        makeCard(id: 2, cardName: 'Three', suit: 'Spades', isFavorite: false),
      ];
      final result = filterCards(noFavs, showOnlyFavorites: true);
      expect(result, isEmpty);
    });

    test('all cards favorited returns all cards when filter on', () {
      final allFavs = [
        makeCard(id: 1, cardName: 'Ace',  suit: 'Hearts',   isFavorite: true),
        makeCard(id: 2, cardName: 'King', suit: 'Spades',   isFavorite: true),
        makeCard(id: 3, cardName: 'Jack', suit: 'Diamonds', isFavorite: true),
      ];
      final result = filterCards(allFavs, showOnlyFavorites: true);
      expect(result.length, 3);
    });
  });

  // ── Suit filter ──────────────────────────────────────────────────────────

  group('Suit filter', () {
    final allCards = [
      makeCard(id: 1, cardName: 'Ace',   suit: 'Hearts',   isFavorite: true),
      makeCard(id: 2, cardName: 'King',  suit: 'Spades',   isFavorite: true),
      makeCard(id: 3, cardName: 'Queen', suit: 'Clubs',    isFavorite: false),
      makeCard(id: 4, cardName: 'Jack',  suit: 'Diamonds', isFavorite: true),
    ];

    test('filter by Hearts returns only Hearts cards', () {
      final result = filterCards(allCards, filterBySuit: 'Hearts');
      expect(result.every((c) => c.suit == 'Hearts'), true);
    });

    test('filter by Spades + Favorites returns only favorited Spades', () {
      final result = filterCards(allCards, filterBySuit: 'Spades', showOnlyFavorites: true);
      expect(result.length, 1);
      expect(result.first.suit, 'Spades');
      expect(result.first.isFavorite, true);
    });

    test('filter by Clubs + Favorites returns empty (Queen is not favorited)', () {
      final result = filterCards(allCards, filterBySuit: 'Clubs', showOnlyFavorites: true);
      expect(result, isEmpty);
    });

    test('null filterBySuit (All Suits) does not exclude any suit', () {
      final result = filterCards(allCards, filterBySuit: null);
      final suits = result.map((c) => c.suit).toSet();
      expect(suits, containsAll(['Hearts', 'Spades', 'Clubs', 'Diamonds']));
    });
  });

  // ── Search filter ────────────────────────────────────────────────────────

  group('Search filter', () {
    final allCards = [
      makeCard(id: 1, cardName: 'Ace'),
      makeCard(id: 2, cardName: 'King'),
      makeCard(id: 3, cardName: 'Queen'),
      makeCard(id: 4, cardName: 'Jack'),
    ];

    test('empty query returns all cards', () {
      expect(filterCards(allCards).length, 4);
    });

    test('partial lowercase match returns correct cards', () {
      final result = filterCards(allCards, query: 'ki');
      expect(result.length, 1);
      expect(result.first.cardName, 'King');
    });

    test('search is case-insensitive', () {
      final result = filterCards(allCards, query: 'QUEEN');
      expect(result.length, 1);
      expect(result.first.cardName, 'Queen');
    });

    test('query with no match returns empty list', () {
      final result = filterCards(allCards, query: 'xyz');
      expect(result, isEmpty);
    });

    test('search combines with favorites filter', () {
      final cards = [
        makeCard(id: 1, cardName: 'Ace',  isFavorite: true),
        makeCard(id: 2, cardName: 'Ace2', isFavorite: false),
      ];
      final result = filterCards(cards, query: 'ace', showOnlyFavorites: true);
      expect(result.length, 1);
      expect(result.first.isFavorite, true);
    });
  });

  // ── Sorting ──────────────────────────────────────────────────────────────

  group('Sorting', () {
    final unsorted = [
      makeCard(id: 1, cardName: 'King',  suit: 'Spades'),
      makeCard(id: 2, cardName: 'Ace',   suit: 'Hearts'),
      makeCard(id: 3, cardName: 'Queen', suit: 'Clubs'),
    ];

    test('sort by name returns alphabetical order', () {
      final result = filterCards(unsorted, sortBy: 'name');
      expect(result.map((c) => c.cardName).toList(), ['Ace', 'King', 'Queen']);
    });

    test('sort by suit returns alphabetical suit order', () {
      final result = filterCards(unsorted, sortBy: 'suit');
      expect(result.map((c) => c.suit).toList(), ['Clubs', 'Hearts', 'Spades']);
    });
  });

  // ── Regression: _loadCards must re-apply filters ─────────────────────────

  group('Regression - favorites preserved after reload', () {
    // Before the fix, _loadCards set _filteredCards = cards directly,
    // discarding the active _showOnlyFavorites / _filterBySuit state.
    // This group documents that the filtering logic itself is correct,
    // so calling _filterCards() after reload produces the right result.

    test('re-applying filters after reload keeps only favorites (All Suits)', () {
      final freshFromDb = [
        makeCard(id: 1, cardName: 'Ace',  suit: 'Hearts',   isFavorite: true),
        makeCard(id: 2, cardName: 'King', suit: 'Spades',   isFavorite: false),
        makeCard(id: 3, cardName: 'Jack', suit: 'Diamonds', isFavorite: true),
      ];
      // Simulates: after reload, _filterCards() runs with showOnlyFavorites=true, filterBySuit=null
      final result = filterCards(freshFromDb, showOnlyFavorites: true);
      expect(result.length, 2, reason: 'Should show 2 favorites, not all 3 cards');
      expect(result.every((c) => c.isFavorite), true);
    });

    test('re-applying filters after reload respects suit + favorites', () {
      final freshFromDb = [
        makeCard(id: 1, cardName: 'Ace',  suit: 'Hearts',   isFavorite: true),
        makeCard(id: 2, cardName: 'King', suit: 'Hearts',   isFavorite: false),
        makeCard(id: 3, cardName: 'Jack', suit: 'Diamonds', isFavorite: true),
      ];
      // Simulates: filterBySuit='Hearts', showOnlyFavorites=true
      final result = filterCards(freshFromDb, filterBySuit: 'Hearts', showOnlyFavorites: true);
      expect(result.length, 1);
      expect(result.first.cardName, 'Ace');
    });

    test('toggling a favorite off is reflected correctly after re-applying filter', () {
      // Simulates the card that was just un-favorited being returned from DB
      final afterToggle = [
        makeCard(id: 1, cardName: 'Ace',  isFavorite: false), // was true, now false
        makeCard(id: 2, cardName: 'King', isFavorite: true),
      ];
      final result = filterCards(afterToggle, showOnlyFavorites: true);
      expect(result.length, 1);
      expect(result.first.cardName, 'King');
    });

    test('toggling a favorite on is reflected correctly after re-applying filter', () {
      final afterToggle = [
        makeCard(id: 1, cardName: 'Ace',  isFavorite: true),  // was false, now true
        makeCard(id: 2, cardName: 'King', isFavorite: true),
      ];
      final result = filterCards(afterToggle, showOnlyFavorites: true);
      expect(result.length, 2);
    });
  });

  // ── Regression: suit filter + desynchronized favorites = 0 results ────────

  group('Regression - Hearts suit filter shows 0 when favorites filter is stuck', () {
    // Scenario that caused the "houses of heart, no cards appeared" bug:
    //
    // 1. User is in Hearts folder, Favorites ON (showing 2 favorited Hearts cards)
    // 2. User unfavorites both cards
    // 3. OLD BUG: _loadCards set _filteredCards = all 13 cards directly,
    //    but _showOnlyFavorites stayed true (desynchronized)
    // 4. User clicks the "Hearts" suit filter chip (thinking display was stuck)
    // 5. _filterCards runs with showOnlyFavorites=true + filterBySuit='Hearts'
    //    → 0 results, even though 13 Hearts cards exist
    //
    // Fix: _loadCards now calls _filterCards(), keeping display in sync.

    test('Hearts suit + Favorites ON with no favorites = 0 results (explains the bug)', () {
      final heartsCards = [
        makeCard(id: 1,  cardName: 'Ace',   suit: 'Hearts', isFavorite: false),
        makeCard(id: 2,  cardName: 'King',  suit: 'Hearts', isFavorite: false),
        makeCard(id: 3,  cardName: 'Queen', suit: 'Hearts', isFavorite: false),
        makeCard(id: 4,  cardName: 'Jack',  suit: 'Hearts', isFavorite: false),
      ];
      // With both filters active and no favorites: 0 results
      final result = filterCards(heartsCards, filterBySuit: 'Hearts', showOnlyFavorites: true);
      expect(result, isEmpty,
          reason: 'No favorited Hearts cards → 0 results when both filters active');
    });

    test('Hearts suit + Favorites OFF shows all Hearts cards (correct recovery)', () {
      final heartsCards = [
        makeCard(id: 1, cardName: 'Ace',  suit: 'Hearts', isFavorite: false),
        makeCard(id: 2, cardName: 'King', suit: 'Hearts', isFavorite: false),
      ];
      // Turning off favorites filter while keeping Hearts suit filter shows all Hearts
      final result = filterCards(heartsCards, filterBySuit: 'Hearts', showOnlyFavorites: false);
      expect(result.length, 2,
          reason: 'Favorites OFF: all Hearts cards should be visible');
    });

    test('after reload, display correctly shows 0 when last favorite is removed', () {
      // The fix ensures the user SEES 0 immediately (not a stale all-cards view)
      // so they know the favorites filter is the cause, not a display bug.
      final afterLastUnfavorite = [
        makeCard(id: 1, cardName: 'Ace',  suit: 'Hearts', isFavorite: false), // was true
        makeCard(id: 2, cardName: 'King', suit: 'Hearts', isFavorite: false),
      ];
      final result = filterCards(afterLastUnfavorite,
          filterBySuit: 'Hearts', showOnlyFavorites: true);
      expect(result, isEmpty,
          reason: 'After reload with fix applied, filter state is consistent: '
              '0 favorites → correctly shows 0 instead of all cards');
    });
  });
}
