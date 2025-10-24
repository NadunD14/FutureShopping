import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'core/services/firebase_data_seeder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseDataSeeder.seedTwoShopsData();
  // Keep a minimal app running so `flutter run lib/test_seeder.dart` can exit gracefully on hot restart/quit
  runApp(const _SeederApp());
}

class _SeederApp extends StatelessWidget {
  const _SeederApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Seeding completed. You can close this app.'),
        ),
      ),
    );
  }
}
