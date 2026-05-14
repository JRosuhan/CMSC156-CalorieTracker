// models/user_model.dart

class UserModel {
  final String email;
  final int dailyCalorieGoal;
  final int? age;
  final String? gender;
  final double? weight;
  final double? height;
  final String? activityLevel;
  final String? goalType;

  UserModel({
    required this.email,
    required this.dailyCalorieGoal,
    this.age,
    this.gender,
    this.weight,
    this.height,
    this.activityLevel,
    this.goalType,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'dailyCalorieGoal': dailyCalorieGoal,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'activityLevel': activityLevel,
      'goalType': goalType,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] ?? '',
      dailyCalorieGoal: map['dailyCalorieGoal'] ?? 2000,
      age: map['age'],
      gender: map['gender'],
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      activityLevel: map['activityLevel'],
      goalType: map['goalType'],
    );
  }
}
