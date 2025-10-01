class Note {
  final String id;
  final String titre;
  final String? text;
  final String userId;
  final String entrepriseId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.titre,
    this.text,
    required this.userId,
    required this.entrepriseId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      titre: map['titre'],
      text: map['text'],
      userId: map['user_id'],
      entrepriseId: map['entreprise_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'text': text,
      'user_id': userId,
      'entreprise_id': entrepriseId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Note copyWith({
    String? id,
    String? titre,
    String? text,
    String? userId,
    String? entrepriseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      text: text ?? this.text,
      userId: userId ?? this.userId,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, titre: $titre, text: $text, userId: $userId, entrepriseId: $entrepriseId)';
  }
}