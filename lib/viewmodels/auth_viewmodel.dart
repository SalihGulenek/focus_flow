import 'package:mobx/mobx.dart';
import 'dart:developer' as developer;
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';

part 'auth_viewmodel.g.dart';

// Mock mode flag - set to true to skip login
const bool kUseMockData = false;

class AuthViewModel = _AuthViewModelBase with _$AuthViewModel;

abstract class _AuthViewModelBase with Store {
  final AuthRepository _authRepository;

  _AuthViewModelBase(this._authRepository);

  @observable
  UserModel? currentUser;

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  bool isAuthenticated = false;

  @computed
  String get displayName => currentUser?.fullName ?? currentUser?.email ?? 'User';

  @computed
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @action
  Future<void> checkAuthStatus() async {
    isLoading = true;
    error = null;

    // Mock mode - skip authentication
    if (kUseMockData) {
      currentUser = _createMockUser();
      isAuthenticated = true;
      isLoading = false;
      return;
    }

    try {
      isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        currentUser = await _authRepository.getCurrentUser();
      }
    } catch (e) {
      error = e.toString();
      isAuthenticated = false;
    } finally {
      isLoading = false;
    }
  }

  UserModel _createMockUser() {
    return UserModel(
      id: 'mock-user-001',
      email: 'demo@focusflow.app',
      fullName: 'Demo User',
      avatarUrl: null,
      timezone: 'Europe/Istanbul',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @action
  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;

    try {
      currentUser = await _authRepository.login(email, password);
      isAuthenticated = true;
      return true;
    } catch (e) {
      error = _parseError(e);
      isAuthenticated = false;
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> register(String email, String password, String fullName) async {
    isLoading = true;
    error = null;

    try {
      currentUser = await _authRepository.register(email, password, fullName);
      isAuthenticated = true;
      return true;
    } catch (e) {
      error = _parseError(e);
      isAuthenticated = false;
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> logout() async {
    isLoading = true;

    try {
      await _authRepository.logout();
      currentUser = null;
      isAuthenticated = false;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    isLoading = true;
    error = null;

    try {
      currentUser = await _authRepository.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  void clearError() {
    error = null;
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('401')) {
      return 'Invalid email or password';
    }
    if (errorStr.contains('409')) {
      return 'Email already exists';
    }
    if (errorStr.contains('network')) {
      return 'Please check your internet connection';
    }
    return 'An error occurred. Please try again.';
  }
}
