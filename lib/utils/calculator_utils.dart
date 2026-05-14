class CalculatorUtils {
  /// Calculates Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  static double calculateBMR({
    required String gender,
    required double weight,
    required double height,
    required int age,
  }) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  /// Calculates Total Daily Energy Expenditure (TDEE) based on activity level
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    double multiplier;
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'lightly active':
        multiplier = 1.375;
        break;
      case 'moderately active':
        multiplier = 1.55;
        break;
      case 'very active':
        multiplier = 1.725;
        break;
      case 'extra active':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.2;
    }
    return bmr * multiplier;
  }

  /// Calculates Daily Calorie Goal based on user goal (cut, maintain, bulk)
  static int calculateDailyGoal({
    required double tdee,
    required String goalType,
  }) {
    switch (goalType.toLowerCase()) {
      case 'cut':
        return (tdee - 500).round();
      case 'bulk':
        return (tdee + 500).round();
      case 'maintain':
      default:
        return tdee.round();
    }
  }
}
