class Folder {
  final int? id;
  final String folderName;
  final String timestamp;

  Folder({
    this.id,
    required this.folderName,
    required this.timestamp,
  });

  // Convert Folder object to Map for database operations
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'folder_name': folderName,
      'timestamp': timestamp,
    };
  }

  // Create Folder object from Map (database query result)
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int?,
      folderName: map['folder_name'] as String,
      timestamp: map['timestamp'] as String,
    );
  }

  // Create a copy with modified fields
  Folder copyWith({
    int? id,
    String? folderName,
    String? timestamp,
  }) {
    return Folder(
      id: id ?? this.id,
      folderName: folderName ?? this.folderName,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'Folder{id: $id, folderName: $folderName, timestamp: $timestamp}';
  }
}