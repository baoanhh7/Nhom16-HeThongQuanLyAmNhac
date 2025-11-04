// // routes/app_routes.dart
// import 'package:flutter/material.dart';
// import '../screens/auth/login_screen.dart';
// import '../screens/auth/register_screen.dart';
// import '../screens/auth/emailverification_screen.dart';
// import '../screens/home_screen.dart';

// class AppRoutes {
//   static const String login = '/login';
//   static const String register = '/register';
//   static const String emailVerification = '/email-verification';
//   static const String home = '/home';

//   static Map<String, WidgetBuilder> get routes {
//     return {
//       login: (context) => const LoginScreen(),
//       register: (context) => const RegisterScreen(),
//       emailVerification: (context) => const EmailVerificationScreen(),
//       home: (context) => const HomeScreen(),
//     };
//   }

//   static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
//     switch (settings.name) {
//       case emailVerification:
//         final args = settings.arguments as Map<String, dynamic>?;
//         if (args == null || 
//             args['userId'] == null || 
//             args['email'] == null || 
//             args['username'] == null) {
//           // Redirect to register if missing required arguments
//           return MaterialPageRoute(builder: (_) => const RegisterScreen());
//         }
//         return MaterialPageRoute(
//           builder: (_) => const EmailVerificationScreen(),
//           settings: settings,
//         );
//       default:
//         return null;
//     }
//   }
// }