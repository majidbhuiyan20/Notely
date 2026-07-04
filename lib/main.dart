import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notely/core/route/app_route.dart';
import 'package:notely/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:notely/features/authentication/presentation/providers/auth_providers.dart';
import 'package:notely/features/sync/presentation/sync_bootstrap.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Enable Firestore's offline cache explicitly. cloud_firestore enables
  // it implicitly on mobile but we set it here so the behaviour is
  // documented in code. Combined with our own outbox, this means an
  // offline write will (a) succeed against the local cache, (b) be
  // marked dirty, and (c) be re-pushed by SyncManager when connectivity
  // returns.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  // Hand the splash screen a pre-warmed SharedPreferences instance so the
  // first read is synchronous and the user lands on Login or Main without
  // a flash of the "wrong" destination.
  final localDataSource = AuthLocalDataSource();
  runApp(
    ProviderScope(
      overrides: [
        authLocalDataSourceProvider.overrideWithValue(localDataSource),
      ],
      child: const SyncBootstrap(child: MyApp()),
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