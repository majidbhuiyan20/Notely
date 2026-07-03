import 'package:flutter/material.dart';
import 'package:notely/features/category/view/category_details_screen.dart';
import 'package:notely/features/category/view/category_screen.dart';
import 'package:notely/features/task/view/create_task_screen.dart';
import 'package:notely/features/task/view/edit_task_screen.dart';
import 'package:notely/features/task/view/task_screen.dart';
import '../../features/main/view/main_screen.dart';
import '../../features/onboarding/view/onboarding_screen.dart';
import '../../features/splash/view/splash_screen.dart';
import '../constants/app_strings.dart';

class Routes {
  static const String splashRoute = "/";
  static const String onboardingRoute = "/onboarding";
  static const String mainRoute = "/main";
  static const String loginRoute = "/loginScreen";
  static const String categoryRoute = "/category";
  static const String categoryDetailsRoute = "/categoryDetails";
  static const String taskRoute = "/task";
  static const String editTaskRoute = "/editTask";
  static const String createTaskRoute = "/createTask";
}

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case Routes.mainRoute:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case Routes.categoryRoute:
        return MaterialPageRoute(builder: (_) => const CategoryScreen());
      case Routes.categoryDetailsRoute:
        final categoryName = routeSettings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CategoryDetailsScreen(categoryName: categoryName),
        );
      case Routes.taskRoute:
        final noteId = routeSettings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => TaskScreen(noteId: noteId),
        );
      case Routes.editTaskRoute:
        final noteId = routeSettings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => EditTaskScreen(noteId: noteId),
        );
      case Routes.createTaskRoute:
        final initialCategory = routeSettings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) =>
              CreateTaskScreen(initialCategory: initialCategory),
        );
      default:
        return unDefineRoute();
    }
  }

  static Route<dynamic> unDefineRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.noRoute),
        ),
        body: const Center(
          child: Text(AppStrings.noRoute),
        ),
      ),
    );
  }
}
