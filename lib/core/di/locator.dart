import 'package:get_it/get_it.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/focus_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../viewmodels/focus_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  // Services
  locator.registerLazySingleton<DatabaseService>(() => DatabaseService());
  locator.registerLazySingleton<ApiService>(() => ApiService());

  // Initialize database
  await locator<DatabaseService>().init();

  // Repositories
  locator.registerLazySingleton<AuthRepository>(() => AuthRepository(locator<ApiService>(), locator<DatabaseService>()));
  locator.registerLazySingleton<TaskRepository>(() => TaskRepository(locator<ApiService>(), locator<DatabaseService>()));
  locator.registerLazySingleton<FocusRepository>(() => FocusRepository(locator<ApiService>(), locator<DatabaseService>()));

  // ViewModels
  locator.registerLazySingleton<AuthViewModel>(() => AuthViewModel(locator<AuthRepository>()));
  locator.registerLazySingleton<TaskViewModel>(() => TaskViewModel(locator<TaskRepository>()));
  locator.registerLazySingleton<FocusViewModel>(() => FocusViewModel(locator<FocusRepository>()));
  locator.registerLazySingleton<DashboardViewModel>(() => DashboardViewModel(locator<TaskRepository>(), locator<FocusRepository>()));
}
