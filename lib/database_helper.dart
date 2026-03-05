import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// A singleton helper that manages the SQLite database used by the
/// card‑organizer application.  All database creation, configuration, and
/// versioning logic lives here so that repository classes can remain thin
/// wrappers around the low‑level API.

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Returns a reference to the open database, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  /// Invoked before the database is opened.  We need to explicitly turn on
  /// foreign‑key support because SQLite disables it by default.  This ensures
  /// the `FOREIGN KEY` constraint declared in the `cards` table is enforced
  /// and cascades applied correctly.
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Cleanly close the database (useful during testing or when the app
  /// shuts down).
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  /// Insert the full set of 13 cards for a single suit into a specific
  /// folder.  This can be used by repository logic when the user creates a
  /// new deck after the initial prepopulation.
  Future<void> prepopulateCardsForFolder(
      {required int folderId, required String suit}) async {
    final db = await database;
    final cards = [
      'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
    ];

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var card in cards) {
        batch.insert('cards', {
          'card_name': card,
          'suit': suit,
          'image_url': 'assets/cards/${suit.toLowerCase()}_$card.png',
          'folder_id': folderId,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future _createDB(Database db, int version) async {
    // Create Folders table
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Create Cards table with foreign key
    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT,
        folder_id INTEGER,
        FOREIGN KEY (folder_id) REFERENCES folders (id)
          ON DELETE CASCADE
      )
    ''');

    // Prepopulate folders
    await _prepopulateFolders(db);
    
    // Prepopulate cards
    await _prepopulateCards(db);
  }

  Future _prepopulateFolders(Database db) async {
    final folders = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];

    // Use a transaction+batch to insert all folders in one go for
    // performance and to ensure atomicity.
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var name in folders) {
        batch.insert('folders', {
          'folder_name': name,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future _prepopulateCards(Database db) async {
    final suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
    final cards = ['Ace', '2', '3', '4', '5', '6', '7',
                   '8', '9', '10', 'Jack', 'Queen', 'King'];

    // insert all card rows in a batch inside one transaction
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (int folderId = 1; folderId <= suits.length; folderId++) {
        final suitName = suits[folderId - 1];
        for (var card in cards) {
          batch.insert('cards', {
            'card_name': card,
            'suit': suitName,
            'image_url':
                'assets/cards/${suitName.toLowerCase()}_$card.png',
            'folder_id': folderId,
          });
        }
      }
      await batch.commit(noResult: true);
    });
  }
}