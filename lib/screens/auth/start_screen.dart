import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
              ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
              const SizedBox(height: 24),
              Text(
                'Music App',
                style: Theme.of(context).textTheme.headlineLarge,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 8),
              Text(
                'Thưởng thức âm nhạc mọi lúc mọi nơi',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 800.ms)
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 16),
                    SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.primaryColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Đăng ký',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 1000.ms)
                        .slideY(begin: 0.3, end: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
