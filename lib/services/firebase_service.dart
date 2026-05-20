// services/firebase_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_log.dart';
import '../models/user_model.dart';
import '../models/recipe_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- AUTHENTICATION ---

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _db.collection('users').doc(result.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return result;
    } catch (e) {
      debugPrint('Sign Up Error: $e');
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
      debugPrint('Sign In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> emailExists(String email) async {
    final snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      rethrow;
    }
  }

  // --- USER DATA (GOAL) ---

  Future<void> saveUserGoal(UserModel userModel) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set(
      userModel.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<UserModel?> fetchUserGoal() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // --- RECIPES ---

  Future<void> addRecipe(RecipeModel recipe) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .add(recipe.toMap());
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .doc(recipe.id)
        .update(recipe.toMap());
  }

  Stream<List<RecipeModel>> getRecipesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RecipeModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  Stream<List<RecipeModel>> getDeletedRecipesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RecipeModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  Future<void> softDeleteRecipe(String recipeId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .doc(recipeId)
        .update({'isDeleted': true});
  }

  Future<void> restoreRecipe(String recipeId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .doc(recipeId)
        .update({'isDeleted': false});
  }

  Future<void> hardDeleteRecipe(String recipeId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .doc(recipeId)
        .delete();
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
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            final dynamic rawTimestamp = data['timestamp'];
            final DateTime timestamp = rawTimestamp != null 
                ? (rawTimestamp as Timestamp).toDate() 
                : DateTime.now();

            final List measuresData = data['availableMeasures'] ?? [];
            final List<Map<String, dynamic>> availableMeasures = measuresData
                .where((m) => m != null)
                .map((m) {
                  final map = Map<String, dynamic>.from(m);
                  final weight = map['weight'];
                  map['weight'] = (weight is num) ? weight.toDouble() : 100.0;
                  map['label'] = map['label']?.toString() ?? 'serving';
                  return map;
                })
                .toList();

            if (availableMeasures.isEmpty) {
              availableMeasures.add({'label': 'serving', 'weight': 100.0});
            }

            int selectedMeasureIndex = data['selectedMeasureIndex'] ?? 0;
            if (selectedMeasureIndex < 0 || selectedMeasureIndex >= availableMeasures.length) {
              selectedMeasureIndex = 0;
            }

            return FoodLog(
              id: doc.id,
              name: data['name'] ?? 'Unknown',
              calories: data['calories'] ?? 0,
              protein: (data['protein'] ?? 0.0).toDouble(),
              carbs: (data['carbs'] ?? 0.0).toDouble(),
              fats: (data['fats'] ?? 0.0).toDouble(),
              servingSize: data['servingSize'] ?? 'Unknown',
              timestamp: timestamp,
              isDeleted: data['isDeleted'] ?? false,
              quantity: (data['quantity'] ?? 1.0).toDouble(),
              availableMeasures: availableMeasures,
              selectedMeasureIndex: selectedMeasureIndex,
              baseCalories: data['baseCalories'] ?? 0,
              baseProtein: (data['baseProtein'] ?? 0.0).toDouble(),
              baseCarbs: (data['baseCarbs'] ?? 0.0).toDouble(),
              baseFats: (data['baseFats'] ?? 0.0).toDouble(),
              fromRecipe: data['fromRecipe'] ?? false,
            );
          })
          .where((log) => !log.isDeleted)
          .toList();
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
      'isDeleted': log.isDeleted,
      'quantity': log.quantity,
      'availableMeasures': log.availableMeasures,
      'selectedMeasureIndex': log.selectedMeasureIndex,
      'baseCalories': log.baseCalories,
      'baseProtein': log.baseProtein,
      'baseCarbs': log.baseCarbs,
      'baseFats': log.baseFats,
      'fromRecipe': log.fromRecipe,
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
      'isDeleted': log.isDeleted,
    });
  }

  Stream<List<FoodLog>> getDeletedFoodLogsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('food_logs')
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final List measuresData = data['availableMeasures'] ?? [];
        final List<Map<String, dynamic>> availableMeasures = measuresData
            .where((m) => m != null)
            .map((m) {
              final map = Map<String, dynamic>.from(m);
              final weight = map['weight'];
              map['weight'] = (weight is num) ? weight.toDouble() : 100.0;
              map['label'] = map['label']?.toString() ?? 'serving';
              return map;
            })
            .toList();

        if (availableMeasures.isEmpty) {
          availableMeasures.add({'label': 'serving', 'weight': 100.0});
        }

        final dynamic rawTimestamp = data['timestamp'];
        final DateTime timestamp = rawTimestamp != null 
            ? (rawTimestamp as Timestamp).toDate() 
            : DateTime.now();

        int selectedMeasureIndex = data['selectedMeasureIndex'] ?? 0;
        if (selectedMeasureIndex < 0 || selectedMeasureIndex >= availableMeasures.length) {
          selectedMeasureIndex = 0;
        }

        return FoodLog(
          id: doc.id,
          name: data['name'] ?? 'Unknown',
          calories: data['calories'] ?? 0,
          protein: (data['protein'] ?? 0.0).toDouble(),
          carbs: (data['carbs'] ?? 0.0).toDouble(),
          fats: (data['fats'] ?? 0.0).toDouble(),
          servingSize: data['servingSize'] ?? 'Unknown',
          timestamp: timestamp,
          isDeleted: data['isDeleted'] ?? false,
          quantity: (data['quantity'] ?? 1.0).toDouble(),
            availableMeasures: availableMeasures,
            selectedMeasureIndex: selectedMeasureIndex,
          baseCalories: data['baseCalories'] ?? 0,
          baseProtein: (data['baseProtein'] ?? 0.0).toDouble(),
          baseCarbs: (data['baseCarbs'] ?? 0.0).toDouble(),
          baseFats: (data['baseFats'] ?? 0.0).toDouble(),
          fromRecipe: data['fromRecipe'] ?? false,
        );
      }).toList();
    });
  }

  Future<void> restoreFoodLog(String logId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('food_logs')
        .doc(logId)
        .update({'isDeleted': false});
  }

  Future<void> softDeleteFoodLog(String logId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('food_logs')
        .doc(logId)
        .update({'isDeleted': true});
  }

  Future<void> hardDeleteFoodLog(String logId) async {
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
