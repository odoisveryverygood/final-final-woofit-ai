import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dog_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference for dogs
  CollectionReference get _dogsRef => _db.collection('dogs');

  // -------------------------------------------------
  // ADD A DOG
  // -------------------------------------------------
  Future<void> addDog(DogModel dog) async {
    try {
      await _dogsRef.doc(dog.dogId).set(dog.toMap());
    } catch (e) {
      throw "Failed to add dog: $e";
    }
  }

  // -------------------------------------------------
  // UPDATE A DOG
  // -------------------------------------------------
  Future<void> updateDog(DogModel dog) async {
    try {
      await _dogsRef.doc(dog.dogId).update(dog.toMap());
    } catch (e) {
      throw "Failed to update dog: $e";
    }
  }

  // -------------------------------------------------
  // DELETE A DOG
  // -------------------------------------------------
  Future<void> deleteDog(String dogId) async {
    try {
      await _dogsRef.doc(dogId).delete();
    } catch (e) {
      throw "Failed to delete dog: $e";
    }
  }

  // -------------------------------------------------
  // GET ALL DOGS OWNED BY A USER
  // -------------------------------------------------
  Future<List<DogModel>> getDogsForUser(String ownerId) async {
    try {
      final query = await _dogsRef
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: false)
          .get();

      return query.docs
          .map((doc) => DogModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw "Failed to fetch dogs: $e";
    }
  }

  // -------------------------------------------------
  // STREAM DOGS FOR REAL-TIME UPDATES
  // -------------------------------------------------
  Stream<List<DogModel>> streamDogsForUser(String ownerId) {
    return _dogsRef
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DogModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // -------------------------------------------------
  // GET SINGLE DOG BY ID
  // -------------------------------------------------
  Future<DogModel?> getDogById(String dogId) async {
    try {
      final doc = await _dogsRef.doc(dogId).get();

      if (!doc.exists) return null;

      return DogModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw "Failed to get dog: $e";
    }
  }
}
