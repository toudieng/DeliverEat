import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    ApiClient.instance.onSessionExpired = _forceLogout;
  }

  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  bool isBusy = false;
  String? errorMessage;

  Future<void> bootstrap() async {
    final hasSession = await SecureStorageService.instance.hasSession;
    if (!hasSession) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = await _authService.me();
      status = AuthStatus.authenticated;
    } catch (_) {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    return _runAuthAction(() async {
      final result = await _authService.login(email: email, password: password);
      user = result.user;
      status = AuthStatus.authenticated;
    });
  }

  Future<bool> register({required String name, required String email, required String password}) async {
    return _runAuthAction(() async {
      final result = await _authService.register(name: name, email: email, password: password);
      user = result.user;
      status = AuthStatus.authenticated;
    });
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isBusy = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.friendlyMessage;
      isBusy = false;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = "Une erreur inattendue est survenue.";
      isBusy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final updated = await _authService.updateProfile(name: name, phone: phone);
    user = updated;
    notifyListeners();
  }

  void setUser(AppUser updated) {
    user = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Best-effort server-side invalidation; local session is cleared regardless.
    }
    _forceLogout();
  }

  void _forceLogout() {
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
