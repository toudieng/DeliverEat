import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';

class AuthResult {
  final AppUser user;
  final String accessToken;
  final String refreshToken;

  const AuthResult({required this.user, required this.accessToken, required this.refreshToken});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}

class AuthService {
  final ApiClient _client = ApiClient.instance;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final result = AuthResult.fromJson(response.data as Map<String, dynamic>);
    await SecureStorageService.instance.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    return result;
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final response = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final result = AuthResult.fromJson(response.data as Map<String, dynamic>);
    await SecureStorageService.instance.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    return result;
  }

  Future<void> logout() async {
    final refreshToken = await SecureStorageService.instance.refreshToken;
    try {
      if (refreshToken != null) {
        await _client.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } finally {
      await SecureStorageService.instance.clear();
    }
  }

  Future<AppUser> me() async {
    final response = await _client.get('/auth/me');
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile({String? name, String? phone}) async {
    final response = await _client.patch('/auth/me', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    });
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }
}
