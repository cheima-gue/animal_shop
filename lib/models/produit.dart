class Produit {
  int? id; // Nullable for new products before ID is assigned
  String nom;
  double prix;
  String? image; // Path to the image file
  int?
      subCategoryId; // Foreign key to SubCategory. Nullable for initial states if needed.

  Produit(
      {this.id,
      required this.nom,
      required this.prix,
      this.image,
      this.subCategoryId});

  // Convert a Produit object into a Map. The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
      'image': image,
      'subCategoryId': subCategoryId,
    };
  }

  // Convert a Map into a Produit object.
  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'],
      nom: map['nom'],
      prix: map['prix'],
      image: map['image'],
      subCategoryId: map['subCategoryId'],
    );
  }

  // Override equality and hashCode for proper comparison in lists (e.g., in dropdowns)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Produit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
