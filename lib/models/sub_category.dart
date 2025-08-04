class SubCategory {
  int? id;
  String nom;
  int categoryId;

  SubCategory({this.id, required this.nom, required this.categoryId});

  // Add the copyWith method
  SubCategory copyWith({int? id, String? nom, int? categoryId}) {
    return SubCategory(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'categoryId': categoryId,
    };
  }

  factory SubCategory.fromMap(Map<String, dynamic> map) {
    return SubCategory(
      id: map['id'],
      nom: map['nom'],
      categoryId: map['categoryId'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
