import 'package:cloud_firestore/cloud_firestore.dart';

class DogModel {
  final String dogId;
  final String ownerId;          // user uid
  final String name;
  final String? breed;
  final int? age;                // in years
  final double? weight;          // in kg
  final String? gender;          // male / female
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  DogModel({
    required this.dogId,
    required this.ownerId,
    required this.name,
    this.breed,
    this.age,
    this.weight,
    this.gender,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ----------------------------------------------------
  // MAP → FIRESTORE
  // ----------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'dogId': dogId,
      'ownerId': ownerId,
      'name': name,
      'breed': breed,
      'age': age,
      'weight': weight,
      'gender': gender,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ----------------------------------------------------
  // FIRESTORE → MODEL
  // ----------------------------------------------------
  factory DogModel.fromMap(Map<String, dynamic> map) {
    return DogModel(
      dogId: map['dogId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      breed: map['breed'],
      age: map['age'],
      weight: (map['weight'] != null)
          ? map['weight'].toDouble()
          : null,
      gender: map['gender'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  // ----------------------------------------------------
  // COPYWITH (for updating dog fields)
  // ----------------------------------------------------
  DogModel copyWith({
    String? dogId,
    String? ownerId,
    String? name,
    String? breed,
    int? age,
    double? weight,
    String? gender,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DogModel(
      dogId: dogId ?? this.dogId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
