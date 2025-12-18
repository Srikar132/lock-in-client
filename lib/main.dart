import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lock_in/core/theme/app_theme.dart';
import 'package:lock_in/presentation/overlays/overlay_app.dart';
import 'package:lock_in/presentation/screens/splash_screen.dart';
import 'package:lock_in/services/native_service.dart';

// Overlay entry point - separate from main app
void overlayMain() {
  runApp(
    const ProviderScope(
      child: OverlayApp(),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp();

  // Enable Firebase offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const ProviderScope(child: LockInApp()));
}

class LockInApp extends ConsumerStatefulWidget {
  const LockInApp({super.key});

  @override
  ConsumerState<LockInApp> createState() => _LockInAppState();
}

class _LockInAppState extends ConsumerState<LockInApp> {
  @override
  void initState() {
    super.initState();

    // Initialize native method handler after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NativeService.initializeMethodHandler(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lock In',
      debugShowCheckedModeBanner: false,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Material(
            child: Container(
              color: Colors.red,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Navigation Error',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorDetails.exception.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const SplashScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text('Restart App'),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return child ?? const SizedBox();
      },
    );
  }
}