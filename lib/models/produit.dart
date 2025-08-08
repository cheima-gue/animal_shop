// lib/models/produit.dart

class Produit {
  int? id;
  String nom;
  double prix;
  String? image;
  String codeBarre;
  int subCategoryId;
  int quantite; // <-- AJOUTEZ CETTE LIGNE

  Produit({
    this.id,
    required this.nom,
    required this.prix,
    this.image,
    required this.codeBarre,
    required this.subCategoryId,
    this.quantite = 0, // Initialisation de la quantité à 0 par défaut
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
      id: map['id'],
      nom: map['nom'],
      prix: map['prix'],
      image: map['image'],
      codeBarre: map['codeBarre'],
      subCategoryId: map['subCategoryId'],
      quantite: map.containsKey('quantite')
          ? map['quantite']
          : 0, // Gérer la quantité lors de la lecture de la base de données
    );
  }

  // Ajout de la méthode pour créer une copie
  Produit copyWith({
    int? id,
    String? nom,
    double? prix,
    String? image,
    String? codeBarre,
    int? subCategoryId,
    int? quantite,
  }) {
    return Produit(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      image: image ?? this.image,
      codeBarre: codeBarre ?? this.codeBarre,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      quantite: quantite ?? this.quantite,
    );
  }
}
