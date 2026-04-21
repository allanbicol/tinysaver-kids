import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'providers/app_providers.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'services/ad_service.dart';
import 'services/iap_service.dart';
import 'theme/app_theme.dart';
import 'widgets/sparkly_background.dart';

void main() async {
  // Run the entire app inside a zone so both sync Flutter errors and
  // async errors from Futures get routed to Crashlytics.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

    // Crashlytics is unsupported on web; only wire it for native builds.
    if (!kIsWeb) {
      // Send Flutter framework errors (build/layout/paint) to Crashlytics.
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      // Disable during debug builds to avoid noisy reports during dev.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
    }

    // Initialize AdMob (no-op on web). Non-blocking — failures are silent.
    AdService.instance.init();

    // Warm up the in-app purchase plugin so product details are cached
    // before the user opens the paywall. Non-blocking.
    IapService.instance.init();

    runApp(const ProviderScope(child: IponBuddyApp()));
  }, (error, stack) {
    // Catches uncaught async errors outside the Flutter framework.
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}

class IponBuddyApp extends ConsumerWidget {
  const IponBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'TinySaver Kids',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  // Show splash for at least this long on cold start so users actually see it.
  static const _minSplashDuration = Duration(milliseconds: 2200);
  bool _splashElapsed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(_minSplashDuration, () {
      if (mounted) setState(() => _splashElapsed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Still showing splash if either auth hasn't resolved OR min time hasn't elapsed
    if (!_splashElapsed || authState.isLoading) {
      return const _SplashScreen();
    }

    return authState.when(
      data: (user) => user != null ? const MainShell() : const AuthScreen(),
      loading: () => const _SplashScreen(),
      error: (_, __) => const AuthScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SparklyBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo — bouncy entrance
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    height: 160,
                    errorBuilder: (_, __, ___) => const _LogoFallback(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Saving made fun for kids',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                  letterSpacing: 0.2,
                ),
              ),

              const Spacer(flex: 2),

              // Mascots group — slides up with slight delay
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 60.0, end: 0.0),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (_, offsetY, child) => Transform.translate(
                  offset: Offset(0, offsetY),
                  child: Opacity(
                    opacity: (1 - offsetY / 60).clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
                child: Image.asset(
                  'assets/images/splash_mascots.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: AppColors.primaryDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    // Shown when assets/images/logo.png isn't placed yet.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryContainer,
          ),
          child: const Icon(Icons.savings_rounded,
            color: AppColors.primaryDark, size: 54),
        ),
        const SizedBox(height: 16),
        Text('TinySaver Kids',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDark)),
      ],
    );
  }
}
