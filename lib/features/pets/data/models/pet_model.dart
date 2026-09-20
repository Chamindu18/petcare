import '../../domain/entities/pet.dart';

class PetModel extends Pet {
  const PetModel({
    required super.petId,
    required super.ownerId,
    required super.name,
    required super.species,
    required super.breed,
    required super.dob,
    required super.gender,
    required super.weight,
    required super.imageUrl,
    required super.notes,
    required super.status,
  });

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      petId: map['petId'] as String,
      ownerId: map['ownerId'] as String,
      name: map['name'] as String,
      species: map['species'] as String,
      breed: map['breed'] as String,
      dob: DateTime.parse(map['dob'] as String),
      gender: map['gender'] as String,
      weight: (map['weight'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      notes: map['notes'] as String,
      status: map['status'] as String,
    );
  }

  factory PetModel.fromEntity(Pet pet) {
    return PetModel(
      petId: pet.petId,
      ownerId: pet.ownerId,
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      dob: pet.dob,
      gender: pet.gender,
      weight: pet.weight,
      imageUrl: pet.imageUrl,
      notes: pet.notes,
      status: pet.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'ownerId': ownerId,
      'name': name,
      'species': species,
      'breed': breed,
      'dob': dob.toIso8601String(),
      'gender': gender,
      'weight': weight,
      'imageUrl': imageUrl,
      'notes': notes,
      'status': status,
    };
  }
}
