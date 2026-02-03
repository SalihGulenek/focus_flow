class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'FocusFlow';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String fullName = 'Full Name';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';

  // Dashboard
  static const String goodMorning = 'Good Morning';
  static const String goodAfternoon = 'Good Afternoon';
  static const String goodEvening = 'Good Evening';
  static const String tasksToGo = 'tasks to go';
  static const String allDone = 'All done!';

  // Tasks
  static const String tasks = 'Tasks';
  static const String addTask = 'Add Task';
  static const String editTask = 'Edit Task';
  static const String deleteTask = 'Delete Task';
  static const String taskTitle = 'Task Title';
  static const String taskDescription = 'Description';
  static const String dueDate = 'Due Date';
  static const String priority = 'Priority';
  static const String subtasks = 'Subtasks';
  static const String dependencies = 'Dependencies';
  static const String blocked = 'Blocked';
  static const String completed = 'Completed';

  // Priority Labels
  static const String priorityCritical = 'Critical';
  static const String priorityHigh = 'High';
  static const String priorityMedium = 'Medium';
  static const String priorityLow = 'Low';
  static const String priorityMinimal = 'Minimal';

  // Focus Timer
  static const String focusTimer = 'Focus Timer';
  static const String startFocus = 'Start Focus';
  static const String pause = 'Pause';
  static const String resume = 'Resume';
  static const String stop = 'Stop';
  static const String sessionCompleted = 'Session Completed!';

  // Recurrence
  static const String daily = 'Daily';
  static const String weekly = 'Weekly';
  static const String weekdays = 'Weekdays';
  static const String monthly = 'Monthly';

  // Errors
  static const String networkError = 'Please check your connection';
  static const String unauthorizedError = 'Please login again';
  static const String validationError = 'Please check your input';
  static const String taskBlockedError = 'This task has uncompleted dependencies';
  static const String cycleDetectedError = 'This would create a circular dependency';
  static const String activeSessionError = 'You already have an active focus session';
}
