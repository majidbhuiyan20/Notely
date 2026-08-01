import 'package:flutter/material.dart';
import 'package:notely/features/analytics/view/analytics_screen.dart';
import 'package:notely/features/authentication/presentation/view/login_screen.dart';
import 'package:notely/features/category/view/category_details_screen.dart';
import 'package:notely/features/category/view/category_screen.dart';
import 'package:notely/features/subscription/presentation/view/google_login_screen.dart';
import 'package:notely/features/subscription/presentation/view/mobile_login_screen.dart';
import 'package:notely/features/subscription/presentation/view/otp_verification_screen.dart';
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

  // Kept for backwards compatibility — features that used to push
  // "/login" should now push "/mobile" (which is the first step in
  // the new mobile-first flow). The route name itself still works
  // because the existing LoginScreen is preserved as the final
  // "Google" sign-in surface.
  static const String loginRoute = "/login";
  static const String mobileLoginRoute = "/mobile";
  static const String otpRoute = "/otp";
  static const String googleLoginRoute = "/google";

  static const String categoryRoute = "/category";
  static const String categoryDetailsRoute = "/categoryDetails";
  static const String taskRoute = "/task";
  static const String editTaskRoute = "/editTask";
  static const String createTaskRoute = "/createTask";
  static const String analyticsRoute = "/analytics";
}

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.mobileLoginRoute:
        return MaterialPageRoute(builder: (_) => const MobileLoginScreen());
      case Routes.otpRoute:
        final mobile = (routeSettings.arguments as String?) ?? '';
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(mobileNumber: mobile),
        );
      case Routes.googleLoginRoute:
        return MaterialPageRoute(builder: (_) => const GoogleLoginScreen());
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
      case Routes.analyticsRoute:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
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
