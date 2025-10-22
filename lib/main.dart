import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import features
import 'features/home/screens/home_screen.dart';
import 'features/product/screens/product_detail_screen.dart';
import 'features/comparison/screens/comparison_screen.dart';
import 'features/shopping_list/screens/shopping_list_screen.dart';

// Import core
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with proper options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Note: Data seeding is now done separately.
  // Use FirebaseDataSeeder.seedSampleData() if needed for initial setup.

  runApp(
    // Wrap the entire app with ProviderScope for Riverpod
    const ProviderScope(child: SmartShoppingApp()),
  );
}

class SmartShoppingApp extends StatelessWidget {
  const SmartShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Shopping',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Primary color scheme
        primarySwatch: MaterialColor(0xFF2196F3, const <int, Color>{
          50: Color(0xFFE3F2FD),
          100: Color(0xFFBBDEFB),
          200: Color(0xFF90CAF9),
          300: Color(0xFF64B5F6),
          400: Color(0xFF42A5F5),
          500: AppConstants.primaryColor,
          600: Color(0xFF1E88E5),
          700: Color(0xFF1976D2),
          800: Color(0xFF1565C0),
          900: Color(0xFF0D47A1),
        }),

        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textOnPrimaryColor,
          elevation: AppConstants.elevationM,
          titleTextStyle: AppConstants.titleLarge,
        ),

        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: AppConstants.textOnPrimaryColor,
            textStyle: AppConstants.buttonTextMedium,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingL,
              vertical: AppConstants.paddingM,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            ),
          ),
        ),

        // Card theme
        cardTheme: CardThemeData(
          color: AppConstants.surfaceColor,
          elevation: AppConstants.elevationS,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppConstants.borderRadiusM),
            ),
          ),
        ),

        // Input decoration theme
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppConstants.borderRadiusM),
            ),
          ),
          contentPadding: EdgeInsets.all(AppConstants.paddingM),
        ),

        // Text theme
        textTheme: const TextTheme(
          headlineLarge: AppConstants.headlineLarge,
          headlineMedium: AppConstants.headlineMedium,
          headlineSmall: AppConstants.headlineSmall,
          titleLarge: AppConstants.titleLarge,
          titleMedium: AppConstants.titleMedium,
          titleSmall: AppConstants.titleSmall,
          bodyLarge: AppConstants.bodyLarge,
          bodyMedium: AppConstants.bodyMedium,
          bodySmall: AppConstants.bodySmall,
        ),

        // Color scheme
        colorScheme: const ColorScheme.light(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
          surface: AppConstants.backgroundColor,
          error: AppConstants.errorColor,
          onPrimary: AppConstants.textOnPrimaryColor,
          onSecondary: AppConstants.textOnPrimaryColor,
          onSurface: AppConstants.textPrimaryColor,
          onError: AppConstants.textOnPrimaryColor,
        ),

        // Use Material 3 design
        useMaterial3: true,
      ),

      // Initial route
      initialRoute: '/',

      // Route definitions
      routes: {
        '/': (context) => const HomeScreen(),
        '/product': (context) => const ProductDetailScreen(),
        '/comparison': (context) => const ComparisonScreen(),
        '/shopping-list': (context) => const ShoppingListScreen(),
      },

      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('Page not found', style: AppConstants.titleLarge),
            ),
          ),
        );
      },
    );
  }
}

/// Extension to add navigation helpers to BuildContext
extension NavigationExtension on BuildContext {
  /// Navigate to product detail screen with product ID
  void navigateToProduct(String productId) {
    Navigator.pushNamed(this, '/product', arguments: productId);
  }

  /// Navigate to comparison screen with product IDs
  void navigateToComparison(List<String> productIds) {
    Navigator.pushNamed(this, '/comparison', arguments: productIds);
  }

  /// Navigate to shopping list screen
  void navigateToShoppingList() {
    Navigator.pushNamed(this, '/shopping-list');
  }

  /// Go back to previous screen
  void goBack() {
    Navigator.pop(this);
  }
}
