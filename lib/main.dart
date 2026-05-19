import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // try {
  //   await Firebase.initializeApp().timeout(
  //     const Duration(seconds: 5),
  //     onTimeout: () => throw Exception('Firebase initialization timed out'),
  //   );
  // } catch (e) {
  //   debugPrint('Firebase failed: $e');
  //   runApp(ErrorApp(message: e.toString()));
  // }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// class ErrorApp extends StatelessWidget {
//   final String message;
//
//   const ErrorApp({
//     required this.message
//   })
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: Center(
//           child: Text(message)
//         )
//       )
//     )
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF1A36FF);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontFamily: 'SpaceGrotesk'),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontFamily: 'SpaceGrotesk'),
      displaySmall: baseTextTheme.displaySmall?.copyWith(fontFamily: 'SpaceGrotesk'),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontFamily: 'SpaceGrotesk'),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontFamily: 'SpaceGrotesk'),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontFamily: 'SpaceGrotesk'),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: 'SpaceGrotesk'),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontFamily: 'SpaceGrotesk'),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontFamily: 'SpaceGrotesk'),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontFamily: 'SpaceMono'),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontFamily: 'SpaceMono'),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontFamily: 'SpaceMono'),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontFamily: 'SpaceMono'),
      labelMedium: baseTextTheme.labelMedium?.copyWith(fontFamily: 'SpaceMono'),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontFamily: 'SpaceMono'),
    );

    return MaterialApp(
      title: 'Tycha Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        fontFamily: 'SpaceMono',
        textTheme: textTheme,
        primaryTextTheme: textTheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: AppBarTheme(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E6F3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E6F3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFEFF2FF),
          selectedColor: const Color(0xFF1A36FF),
          secondarySelectedColor: const Color(0xFF1A36FF),
          labelStyle: const TextStyle(color: Color(0xFF1A36FF)),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const Wrapper(),
    );
  }
}
