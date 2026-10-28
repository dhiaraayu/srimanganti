import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_screen.dart';
import 'main_navigation_screen.dart';
import '../services/db_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final Color _bgColor = const Color(0xFF1E3B38); 
  final Color _goldColor = const Color(0xFFE6D5B8); 

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _mulaiTransisi();
  }

  Future<void> _mulaiTransisi() async {
    // 1. Tahan Splash Screen selama 2.5 detik
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // 2. Cek Sesi di belakang layar (Splash screen TETAP TAMPIL)
    try {
      final email = await DBHelper().getSesi();
      final prefs = await SharedPreferences.getInstance();
      bool isBioEnabled = prefs.getBool('biometric_enabled') ?? false;

      if (!mounted) return;

      // 3. Siapkan halaman tujuan
      Widget nextPage;
      if (email != null && email.isNotEmpty) {
        nextPage = isBioEnabled 
            ? const AuthScreen(paksaBiometrik: true) 
            : const MainNavigationScreen();
      } else {
        nextPage = const AuthScreen();
      }

      // 4. Pindah halaman pakai FadeTransition (Biar mulus tanpa kedip)
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation, // Halaman baru muncul sambil memudar
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800), // Durasi pudar
        ),
      );

    } catch (e) {
      debugPrint("Error cek sesi: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Image.asset(
                  'assets/logo.png',
                  width: 120, 
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _goldColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          'LOGO',
                          style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 30), 
                
                // TEKS
                const Text(
                  'SRIMANGANTI',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: Colors.white,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'KERATON NGAYOGYAKARTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: _goldColor.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 40), 

                // LOADING 3 TITIK
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 6),
                    _buildDot(1),
                    const SizedBox(width: 6),
                    _buildDot(2),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Animasi 3 Titik
  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.2, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 150)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -4 * value), 
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _goldColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}