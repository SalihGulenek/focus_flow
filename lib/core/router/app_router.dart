import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../views/screens/splash/splash_screen.dart';
import '../../views/screens/auth/login_screen.dart';
import '../../views/screens/auth/register_screen.dart';
import '../../views/screens/dashboard/dashboard_screen.dart';
import '../../views/screens/task/task_detail_screen.dart';
import '../../views/screens/task/add_task_screen.dart';
import '../../views/screens/focus/focus_timer_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/tasks/:id',
        name: 'taskDetail',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: '/add-task',
        name: 'addTask',
        builder: (context, state) {
          final parentId = state.uri.queryParameters['parentId'];
          return AddTaskScreen(parentId: parentId);
        },
      ),
      GoRoute(
        path: '/focus',
        name: 'focus',
        builder: (context, state) {
          final taskId = state.uri.queryParameters['taskId'];
          final taskTitle = state.uri.queryParameters['taskTitle'];
          return FocusTimerScreen(
            taskId: taskId,
            taskTitle: taskTitle,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.path}'),
      ),
    ),
  );
}
