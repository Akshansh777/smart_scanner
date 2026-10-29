import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/database_service.dart';
import 'core/services/database_service.dart' show DatabaseService;
import 'features/home/screens/main_nav_scaffold.dart';

// Keep your existing imports for:
// DatabaseService
// databaseserviceProvider

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize the database
  final dbService = DatabaseService();
  await dbService.init();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
      ],
      child: const SmartScannerApp(),
    ),
  );
}

class SmartScannerApp extends StatelessWidget {
  const SmartScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Document Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        useMaterial3: true,
      ),
      home: const MainNavScaffold(),
    );
  }
}