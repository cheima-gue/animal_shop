class Produit {
  final int? id;
  final String nom;
  final double prix;
  final String? image;

  Produit({this.id, required this.nom, required this.prix, this.image});

  // Convertir un objet Produit en Map pour la BD
  Map<String, dynamic> toMap() {
    return {'id': id, 'nom': nom, 'prix': prix, 'image': image};
  }

  // Convertir une Map en objet Produit
  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'],
      nom: map['nom'],
      prix: map['prix'],
      image: map['image'],
    );
  }
}
