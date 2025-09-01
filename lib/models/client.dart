// lib/models/client.dart

class Client {
  int? id;
  String firstName;
  String lastName;
  String tel;
  double loyaltyPoints; // Champ ajouté

  Client({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.tel,
    this.loyaltyPoints = 0.0, // Initialisé à 0 par défaut
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'tel': tel,
      'loyaltyPoints': loyaltyPoints, // Ajouté à la méthode toMap
    };
  }

  static Client fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      tel: map['tel'],
      // Utilisation de '?? 0.0' pour gérer les anciennes bases de données sans cette colonne
      loyaltyPoints: map['loyaltyPoints'] ?? 0.0,
    );
  }

  // Ajout de la méthode copyWith
  Client copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? tel,
    double? loyaltyPoints,
  }) {
    return Client(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      tel: tel ?? this.tel,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    );
  }
}
