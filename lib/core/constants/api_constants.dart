class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://focusflow-vc91.onrender.com',
  );

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refreshToken = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';

  // Tasks
  static const String tasks = '/api/tasks';
  static String taskDetail(String id) => '/api/tasks/$id';
  static String taskComplete(String id) => '/api/tasks/$id/complete';
  static String taskActivate(String id) => '/api/tasks/$id/activate';
  static String taskSubtasks(String id) => '/api/tasks/$id/subtasks';
  static String taskDependencies(String id) => '/api/tasks/$id/dependencies';
  static String taskFlow(String id) => '/api/tasks/$id/flow';

  // Focus
  static const String focusSessions = '/api/focus/sessions';
  static String focusSession(String id) => '/api/focus/sessions/$id';
  static String sessionComplete(String id) => '/api/focus/sessions/$id/complete';
  static String sessionPause(String id) => '/api/focus/sessions/$id/pause';
  static String sessionResume(String id) => '/api/focus/sessions/$id/resume';
  static const String focusStats = '/api/focus/stats';

  // Dashboard
  static const String dashboard = '/api/dashboard';
  static const String dashboardStats = '/api/dashboard/stats';
  static const String dashboardToday = '/api/dashboard/today';

  // Tags
  static const String tags = '/api/tags';
}
