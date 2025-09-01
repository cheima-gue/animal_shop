// lib/models/parametre.dart

class Parametre {
  final int? id;
  final double pointsParDinar;
  final double valeurDinar;
  final double margeBeneficiaire;

  Parametre({
    this.id,
    required this.pointsParDinar,
    required this.valeurDinar,
    required this.margeBeneficiaire,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pointsParDinar': pointsParDinar,
      'valeurDinar': valeurDinar,
      'margeBeneficiaire': margeBeneficiaire,
    };
  }

  factory Parametre.fromMap(Map<String, dynamic> map) {
    return Parametre(
      id: map['id'] as int?,
      pointsParDinar: map['pointsParDinar'] as double,
      valeurDinar: map['valeurDinar'] as double,
      margeBeneficiaire: map['margeBeneficiaire'] as double,
    );
  }

  // Add the copyWith method
  Parametre copyWith({
    int? id,
    double? pointsParDinar,
    double? valeurDinar,
    double? margeBeneficiaire,
  }) {
    return Parametre(
      id: id ?? this.id,
      pointsParDinar: pointsParDinar ?? this.pointsParDinar,
      valeurDinar: valeurDinar ?? this.valeurDinar,
      margeBeneficiaire: margeBeneficiaire ?? this.margeBeneficiaire,
    );
  }
}
