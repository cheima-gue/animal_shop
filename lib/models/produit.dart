class Produit {
  int? id;
  String nom;
  double prix;
  String? image;
  String codeBarre; // Rendu obligatoire
  int subCategoryId;

  Produit({
    this.id,
    required this.nom,
    required this.prix,
    this.image,
    required this.codeBarre,
    required this.subCategoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
      'image': image,
      'codeBarre': codeBarre,
      'subCategoryId': subCategoryId,
    };
  }

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      prix: map['prix'] as double,
      image: map['image'] as String?,
      codeBarre: map['codeBarre'] as String,
      subCategoryId: map['subCategoryId'] as int,
    );
  }
}
