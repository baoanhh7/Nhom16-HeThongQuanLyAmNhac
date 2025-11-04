import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_music_app/music/handle/audio_handler.dart';
import 'package:flutter_music_app/screens/auth/emailverification_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'constants/app_colors.dart';
import 'screens/auth/start_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.request();
  if (status.isGranted) {
    debugPrint("Notification permission granted");
  } else {
    debugPrint("Notification permission denied");
  }
}

late final AudioHandler globalAudioHandler;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  globalAudioHandler = await AudioService.init(
    builder: () => MyAudioHandler(), // ✅ BẮT BUỘC
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.app.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_notification',
    ),
  );

  // await requestNotificationPermission();

  // Khóa xoay màn hình
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.background,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.primaryDark,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.textSecondary,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ),
      navigatorObservers: [routeObserver],
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return PageTransition(
              type: PageTransitionType.rightToLeft,
              child: const LoginScreen(),
            );
          case '/register':
            return PageTransition(
              type: PageTransitionType.rightToLeft,
              child: const RegisterScreen(),
            );
          case '/home':
            return PageTransition(
              type: PageTransitionType.fade,
              child: const HomeScreen(),
            );
          default:
            return PageTransition(
              type: PageTransitionType.fade,
              child: const StartScreen(),
            );
        }
      },
      home: const SplashScreen(),
    );
  }
}
