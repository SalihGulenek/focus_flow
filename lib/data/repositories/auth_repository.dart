import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiService _apiService;
  final DatabaseService _databaseService;

  AuthRepository(this._apiService, this._databaseService);

  Future<UserModel> login(String email, String password) async {
    final response = await _apiService.login(email, password);
    final data = response.data;

    // Save tokens
    await _apiService.saveTokens(
      data['access_token'],
      data['refresh_token'],
    );

    // Parse and cache user
    final user = UserModel.fromJson(data['user']);
    await _cacheUser(user);

    return user;
  }

  Future<UserModel> register(String email, String password, String fullName) async {
    final response = await _apiService.register(email, password, fullName);
    final data = response.data;

    // Save tokens
    await _apiService.saveTokens(
      data['access_token'],
      data['refresh_token'],
    );

    // Parse and cache user
    final user = UserModel.fromJson(data['user']);
    await _cacheUser(user);

    return user;
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {
      // Ignore network errors during logout
    }
    await _apiService.clearTokens();
    await _databaseService.delete('users');
  }

  Future<UserModel?> getCurrentUser() async {
    // First try to get from local database
    final localUsers = await _databaseService.query('users', limit: 1);
    if (localUsers.isNotEmpty) {
      return UserModel.fromDb(localUsers.first);
    }

    // Try to fetch from API
    try {
      final response = await _apiService.getMe();
      final user = UserModel.fromJson(response.data);
      await _cacheUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _apiService.getAccessToken();
    return token != null;
  }

  Future<UserModel> updateProfile({String? fullName, String? avatarUrl}) async {
    // This would call an API endpoint for profile update
    // For now, just update local cache
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final updatedUser = currentUser.copyWith(
      fullName: fullName ?? currentUser.fullName,
      avatarUrl: avatarUrl ?? currentUser.avatarUrl,
      updatedAt: DateTime.now(),
    );

    await _cacheUser(updatedUser);
    return updatedUser;
  }

  Future<void> _cacheUser(UserModel user) async {
    // Clear existing users and save new one
    await _databaseService.delete('users');
    await _databaseService.insert('users', user.toDb());
  }
}
