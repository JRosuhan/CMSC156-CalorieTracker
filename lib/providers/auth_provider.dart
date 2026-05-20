import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../services/chatbot_api_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final authStateProvider = StreamProvider((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

final userProvider = NotifierProvider<UserNotifier, UserModel?>(() {
  return UserNotifier();
});

class UserNotifier extends Notifier<UserModel?> {
  late final FirebaseService _service;

  @override
  UserModel? build() {
    _service = ref.watch(firebaseServiceProvider);
    _init();
    return null;
  }

  Future<void> _init() async {
    final user = await _service.fetchUserGoal();
    state = user;
  }

  Future<void> login(String email, String password) async {
    await _service.signIn(email, password);
    final user = await _service.fetchUserGoal();
    state = user ?? UserModel(email: email, dailyCalorieGoal: 2000);
  }

  Future<void> signUp(String email, String password) async {
    await _service.signUp(email, password);
    state = UserModel(email: email, dailyCalorieGoal: 2000);
  }

  Future<void> logout() async {
    await _service.signOut();
    ChatbotApiService().clearHistory();
    state = null;
  }

  Future<void> setGoal(UserModel user) async {
    await _service.saveUserGoal(user);
    state = user;
  }
}
