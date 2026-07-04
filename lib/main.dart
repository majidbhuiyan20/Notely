import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notely/core/route/app_route.dart';
import 'package:notely/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:notely/features/authentication/presentation/providers/auth_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Hand the splash screen a pre-warmed SharedPreferences instance so the
  // first read is synchronous and the user lands on Login or Main without
  // a flash of the "wrong" destination.
  final localDataSource = AuthLocalDataSource();
  runApp(
    ProviderScope(
      overrides: [
        authLocalDataSourceProvider.overrideWithValue(localDataSource),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notely',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      onGenerateRoute: RouteGenerator.getRoute,
      initialRoute: Routes.splashRoute,
    );
  }
}