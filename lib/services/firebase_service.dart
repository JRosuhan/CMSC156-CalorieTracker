// services/firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_log.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- AUTHENTICATION ---

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign Up Error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- USER DATA (GOAL) ---

  Future<void> saveUserGoal(int goal) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'dailyCalorieGoal': goal,
      'email': user.email,
    }, SetOptions(merge: true));
  }

  Future<int?> fetchUserGoal() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return doc.data()?['dailyCalorieGoal'] as int?;
    }
    return null;
  }

  // --- FOOD LOGS ---

  Stream<List<FoodLog>> getFoodLogsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('food_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final List measuresData = data['availableMeasures'] ?? [];
        
        return FoodLog(
          id: doc.id,
          name: data['name'] ?? 'Unknown',
          calories: data['calories'] ?? 0,
          protein: (data['protein'] ?? 0.0).toDouble(),
          carbs: (data['carbs'] ?? 0.0).toDouble(),
          fats: (data['fats'] ?? 0.0).toDouble(),
          servingSize: data['servingSize'] ?? 'Unknown',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          quantity: (data['quantity'] ?? 1.0).toDouble(),
          availableMeasures: measuresData.map((m) => Map<String, dynamic>.from(m)).toList(),
          selectedMeasureIndex: data['selectedMeasureIndex'] ?? 0,
          baseCalories: data['baseCalories'] ?? 0,
          baseProtein: (data['baseProtein'] ?? 0.0).toDouble(),
          baseCarbs: (data['baseCarbs'] ?? 0.0).toDouble(),
          baseFats: (data['baseFats'] ?? 0.0).toDouble(),
        );
      }).toList();
    });
  }

  Future<void> addFoodLog(FoodLog log) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('food_logs')
        .doc(log.id)
        .set({
      'name': log.name,
      'calories': log.calories,
      'protein': log.protein,
      'carbs': log.carbs,
      'fats': log.fats,
      'servingSize': log.servingSize,
      'timestamp': Timestamp.fromDate(log.timestamp),
      'quantity': log.quantity,
      'availableMeasures': log.availableMeasures,
      'selectedMeasureIndex': log.selectedMeasureIndex,
      'baseCalories': log.baseCalories,
      'baseProtein': log.baseProtein,
      'baseCarbs': log.baseCarbs,
      'baseFats': log.baseFats,
    });
  }

  Future<void> updateFoodLog(FoodLog log) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('food_logs')
        .doc(log.id)
        .update({
      'calories': log.calories,
      'protein': log.protein,
      'carbs': log.carbs,
      'fats': log.fats,
      'servingSize': log.servingSize,
      'quantity': log.quantity,
      'selectedMeasureIndex': log.selectedMeasureIndex,
    });
  }

  Future<void> deleteFoodLog(String logId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('food_logs')
        .doc(logId)
        .delete();
  }
}
