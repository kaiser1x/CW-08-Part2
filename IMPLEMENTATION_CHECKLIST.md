## Card Organizer App - Implementation Checklist

### ✅ **Database Layer** (database_helper.dart)
- [x] Foreign key constraint between Cards.folder_id → Folders.id
- [x] ON DELETE CASCADE to ensure orphaned cards cannot exist
- [x] Enable foreign keys via PRAGMA foreign_keys = ON
- [x] Prepopulate 4 suit folders (Hearts, Diamonds, Clubs, Spades)
- [x] Prepopulate 52 cards (13 per suit) in batch transactions
- [x] Batch insertion for performance optimization
- [x] Transaction-based prepopulation for atomicity
- [x] Helper method: prepopulateCardsForFolder() for future folders

### ✅ **Repository Layer** (Separation of Concerns)
#### FolderRepository
- [x] insertFolder() - Create new folders with auto-prepopulation
- [x] getAllFolders() - Read all folders
- [x] getFolderById() - Read single folder
- [x] updateFolder() - Update folder
- [x] deleteFolder() - Delete with cascade
- [x] getFolderCount() - Count total folders

#### CardRepository  
- [x] insertCard() - Create new cards
- [x] getAllCards() - Read all cards
- [x] getCardsByFolderId() - Read cards filtered by folder
- [x] getCardById() - Read single card
- [x] updateCard() - Update card details
- [x] deleteCard() - Delete card
- [x] getCardCountByFolder() - Card count per folder
- [x] moveCardToFolder() - Move card between folders

### ✅ **Model Layer** (Type Safety)
#### Folder Model
- [x] Proper generic types: Map<String, Object?>
- [x] Type-safe fromMap() with cast operations
- [x] toMap() for database serialization
- [x] copyWith() for immutable updates
- [x] toString() for debugging

#### PlayingCard Model
- [x] Proper generic types: Map<String, Object?>
- [x] Type-safe fromMap() with cast operations
- [x] toMap() for database serialization
- [x] copyWith() for immutable updates
- [x] toString() for debugging

### ✅ **UI Layer - FolderScreen**
- [x] Display 2-4 suit folders in a grid (2 columns)
- [x] Show suit icon/emoji for each folder
- [x] Show folder name
- [x] Show card count (fetched from DB)
- [x] Show suit color (red for Hearts/Diamonds, black for Clubs/Spades)
- [x] Delete folder button with confirmation dialog
- [x] Cascade delete explanation in confirmation
- [x] Tap folder to navigate to CardsScreen
- [x] Refresh folder list on return from CardsScreen
- [x] Loading and empty states

### ✅ **UI Layer - CardsScreen**
- [x] Display all 13 cards for a folder in a grid
- [x] Show card image (or placeholder if missing URL)
- [x] Show card name
- [x] Show card suit
- [x] Edit button → navigate to AddEditCardScreen
- [x] Delete button with confirmation
- [x] Add new card FAB → navigate to AddEditCardScreen
- [x] Refresh card list after add/edit/delete
- [x] Handle online image loading with error fallback
- [x] Loading and empty states

### ✅ **UI Layer - AddEditCardScreen**
- [x] Form to create or edit cards
- [x] Display selected folder info
- [x] Card name input field
- [x] Suit selection dropdown (4 options)
- [x] Image URL input field (optional)
- [x] URL validation (http/https required)
- [x] Image preview (loaded from URL)
- [x] Save button for insert/update
- [x] Cancel button to return
- [x] Populate fields when editing existing card
- [x] Success/error messages
- [x] Loading state during save

### ✅ **UI Layer - Main**
- [x] Initialize FolderScreen as home
- [x] Theme configured with Material 3
- [x] App title set to 'Card Organizer'

### ✅ **Data Integrity Features**
- [x] Foreign key enforcement prevents orphaned cards
- [x] Cascade delete removes cards when folder deleted
- [x] Batch operations reduce individual DB writes
- [x] Transaction atomicity ensures consistency
- [x] Type safety prevents runtime errors

### ✅ **User Experience Features**
- [x] Confirmation dialogs for destructive actions
- [x] Clear warning messages about cascade deletion
- [x] Loading indicators during async operations
- [x] Empty state messages
- [x] Success/error notifications via SnackBar
- [x] Grid-based layout for easy browsing
- [x] Card images display with fallback
- [x] Suit info (icon + name + count)

---

## Testing Checklist (To Verify End-to-End)

1. **Initialization**
   - [ ] App launches and displays 4 suit folders
   - [ ] Each folder shows correct count (13 cards)
   - [ ] Folders show correct suit icons and colors

2. **Read Operations**
   - [ ] Tap a folder → displays 13 cards
   - [ ] Each card shows image or placeholder
   - [ ] Card names are correct for each suit

3. **Create Operations**
   - [ ] Tap FAB in CardsScreen → form opens
   - [ ] Fill form and save → card appears in list
   - [ ] Cards are persisted in database

4. **Update Operations**
   - [ ] Tap edit button on a card → form opens with data
   - [ ] Change card name/URL and save → card updates
   - [ ] Changes reflected immediately in list

5. **Delete Operations**
   - [ ] Tap delete on a card → confirmation dialog
   - [ ] Confirm → card removed from list
   - [ ] Delete folder → confirmation shows cascade warning
   - [ ] Confirm → all 13 cards deleted with folder

6. **Foreign Key Enforcement**
   - [ ] No orphaned cards exist (verify schema)
   - [ ] Deleting folder cascades to cards
   - [ ] Moving cards between folders works

7. **Navigation**
   - [ ] FolderScreen → CardsScreen (tap folder)
   - [ ] CardsScreen → AddEditCardScreen (tap FAB or edit)
   - [ ] Return from screens refreshes parent data
