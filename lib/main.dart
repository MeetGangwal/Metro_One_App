import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/metro_provider.dart';
import 'core/providers/ticket_provider.dart';
import 'core/providers/crowd_provider.dart';
import 'core/providers/favorites_provider.dart';
import 'core/providers/transit_alarm_provider.dart';
import 'core/providers/admin_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'screens/splash/splash_screen.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase with project-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Running in offline mode');
  }

  final prefs = await SharedPreferences.getInstance();
  
  // Initialize local notifications
  await NotificationService().init();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('mr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MumbaiMetroApp(prefs: prefs),
    ),
  );
}

class MumbaiMetroApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MumbaiMetroApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider(prefs)),
        ChangeNotifierProvider(create: (_) => MetroProvider(prefs)),
        ChangeNotifierProxyProvider<AppAuthProvider, TicketProvider>(
          create: (_) => TicketProvider(prefs),
          update: (_, auth, ticket) {
            final provider = ticket ?? TicketProvider(prefs);
            // Use local uid from prefs if it's more stable during startup
            final effectiveUid = auth.uid;
            if (effectiveUid.isNotEmpty) {
              provider.setUid(effectiveUid);
            } else if (!auth.isLoggedIn) {
              provider.clearData();
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => CrowdProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => TransitAlarmProvider()),
        ChangeNotifierProxyProvider<AppAuthProvider, FavoritesProvider>(
          create: (_) => FavoritesProvider(prefs),
          update: (_, auth, fav) {
            final provider = fav ?? FavoritesProvider(prefs);
            final effectiveUid = auth.uid;
            if (effectiveUid.isNotEmpty) {
              provider.setUid(effectiveUid);
            } else if (!auth.isLoggedIn) {
              provider.clearData();
            }
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, WalletProvider>(
          create: (_) => WalletProvider(),
          update: (_, auth, wallet) {
            final provider = wallet ?? WalletProvider();
            final effectiveUid = auth.uid;
            if (effectiveUid.isNotEmpty) {
              provider.setUid(effectiveUid);
            } else if (!auth.isLoggedIn) {
              provider.clearData();
            }
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Mumbai Metro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const SplashScreen(),
      ),
    );
  }
}
