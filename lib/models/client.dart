// lib/models/client.dart

class Client {
  int? id;
  String firstName;
  String lastName;
  String cin;

  Client({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.cin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'cin': cin,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      cin: map['cin'],
    );
  }
}
