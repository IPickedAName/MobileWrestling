import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class AuthViewModel {
  final AuthService _authService = AuthService();

  Future<User?> login(String email, String password) async {
    return await _authService.signIn(email: email, password: password);
  }

  Future<User?> register(String email, String password) async {
    return await _authService.register(email: email, password: password);
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}