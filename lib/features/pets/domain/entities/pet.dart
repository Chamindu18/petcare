class Pet {
  const Pet({
    required this.petId,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.dob,
    required this.gender,
    required this.weight,
    required this.imageUrl,
    required this.notes,
    required this.status,
  });

  final String petId;
  final String ownerId;
  final String name;
  final String species;
  final String breed;
  final DateTime dob;
  final String gender;
  final double weight;
  final String imageUrl;
  final String notes;
  final String status;

  int get ageInYears {
    final today = DateTime.now();

    var age = today.year - dob.year;

    final birthdayThisYear = DateTime(today.year, dob.month, dob.day);

    if (today.isBefore(birthdayThisYear)) {
      age--;
    }

    return age;
  }
}
