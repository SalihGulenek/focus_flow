import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(_AuthInterceptor(_dio, _storage));
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  // Auth
  Future<Response> login(String email, String password) async {
    return await _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(String email, String password, String fullName) async {
    return await _dio.post(ApiConstants.register, data: {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
  }

  Future<Response> refreshToken(String refreshToken) async {
    return await _dio.post(ApiConstants.refreshToken, data: {
      'refresh_token': refreshToken,
    });
  }

  Future<Response> logout() async {
    return await _dio.post(ApiConstants.logout);
  }

  Future<Response> getMe() async {
    return await _dio.get(ApiConstants.me);
  }

  // Tasks
  Future<Response> getTasks({
    int page = 1,
    int limit = 20,
    String? status,
    int? priority,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;

    return await _dio.get(ApiConstants.tasks, queryParameters: queryParams);
  }

  Future<Response> getTask(String id) async {
    return await _dio.get(ApiConstants.taskDetail(id));
  }

  Future<Response> createTask(Map<String, dynamic> data) async {
    return await _dio.post(ApiConstants.tasks, data: data);
  }

  Future<Response> updateTask(String id, Map<String, dynamic> data) async {
    return await _dio.put(ApiConstants.taskDetail(id), data: data);
  }

  Future<Response> deleteTask(String id) async {
    return await _dio.delete(ApiConstants.taskDetail(id));
  }

  Future<Response> completeTask(String id) async {
    return await _dio.post(ApiConstants.taskComplete(id));
  }

  Future<Response> activateTask(String id) async {
    return await _dio.post(ApiConstants.taskActivate(id));
  }

  // Subtasks
  Future<Response> getSubtasks(String taskId) async {
    return await _dio.get(ApiConstants.taskSubtasks(taskId));
  }

  Future<Response> createSubtask(String taskId, Map<String, dynamic> data) async {
    return await _dio.post(ApiConstants.taskSubtasks(taskId), data: data);
  }

  // Dependencies
  Future<Response> getDependencies(String taskId) async {
    return await _dio.get(ApiConstants.taskDependencies(taskId));
  }

  Future<Response> addDependency(String taskId, String blockerTaskId) async {
    return await _dio.post(ApiConstants.taskDependencies(taskId), data: {
      'blocker_task_id': blockerTaskId,
    });
  }

  Future<Response> removeDependency(String taskId, String blockerTaskId) async {
    return await _dio.delete('${ApiConstants.taskDependencies(taskId)}/$blockerTaskId');
  }

  Future<Response> getTaskFlow(String taskId) async {
    return await _dio.get(ApiConstants.taskFlow(taskId));
  }

  // Focus Sessions
  Future<Response> getFocusSessions({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    return await _dio.get(ApiConstants.focusSessions, queryParameters: queryParams);
  }

  Future<Response> createFocusSession(String? taskId, int duration) async {
    return await _dio.post(ApiConstants.focusSessions, data: {
      if (taskId != null) 'task_id': taskId,
      'duration': duration,
    });
  }

  Future<Response> completeFocusSession(String id) async {
    return await _dio.post(ApiConstants.sessionComplete(id));
  }

  Future<Response> pauseFocusSession(String id) async {
    return await _dio.post(ApiConstants.sessionPause(id));
  }

  Future<Response> resumeFocusSession(String id) async {
    return await _dio.post(ApiConstants.sessionResume(id));
  }

  Future<Response> getFocusStats() async {
    return await _dio.get(ApiConstants.focusStats);
  }

  // Dashboard
  Future<Response> getDashboard() async {
    return await _dio.get(ApiConstants.dashboard);
  }

  Future<Response> getDashboardStats() async {
    return await _dio.get(ApiConstants.dashboardStats);
  }

  // Tags
  Future<Response> getTags() async {
    return await _dio.get(ApiConstants.tags);
  }

  Future<Response> createTag(String name, String? color) async {
    return await _dio.post(ApiConstants.tags, data: {
      'name': name,
      if (color != null) 'color': color,
    });
  }

  // Token management
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  _AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await _storage.read(key: 'refresh_token');
        if (refreshToken != null) {
          final response = await _dio.post(
            ApiConstants.refreshToken,
            data: {'refresh_token': refreshToken},
          );

          final newToken = response.data['access_token'];
          await _storage.write(key: 'access_token', value: newToken);

          // Retry original request
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(opts);
          handler.resolve(retryResponse);
          return;
        }
      } catch (e) {
        // Clear tokens on refresh failure
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
      }
    }
    handler.next(err);
  }
}
