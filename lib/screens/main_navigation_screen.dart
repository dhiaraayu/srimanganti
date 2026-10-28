import 'package:flutter/material.dart';

import '../services/db_helper.dart';
import '../services/supabase_service.dart';
import 'beranda_screen.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'shake_ticket.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({Key? key, this.initialIndex = 0})
    : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late final ShakeTicketHandler _shake;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Goyang HP -> tampilkan e-ticket
    _shake = ShakeTicketHandler(
      getContext: () => context,
      loadTiket: _loadTiket,
    )..start();
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// Ambil semua tiket milik user yang sedang login
  /// (pakai fungsi yang sama dengan HistoryScreen).
  Future<List<Map<String, dynamic>>> _loadTiket() async {
    final email = await DBHelper().getSesi();
    if (email == null || email.isEmpty) return [];
    return SupabaseService().getHistoryTiket(email);
  }

  // LIST HALAMAN
  final List<Widget> _pages = [
    const HomeScreen(),
    const HistoryScreen(),
    const ChatScreen(), // <-- Index 2
    const ProfileScreen(), // <-- Index 3
  ];

  @override
  Widget build(BuildContext context) {
    // true jika keyboard sedang muncul
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Navbar tinggi 70 + margin bawah 20 = 90.
            // Khusus halaman chat, sisakan ruang itu saat navbar tampil
            // supaya kolom ketik tidak tertutup.
            Padding(
              padding: EdgeInsets.only(
                bottom: (_currentIndex == 2 && !isKeyboardOpen) ? 90 : 0,
              ),
              child: _pages[_currentIndex],
            ),

            // Navbar disembunyikan saat keyboard muncul
            if (!isKeyboardOpen)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B3D2E).withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            index: 0,
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            label: 'Beranda',
                          ),
                          _buildNavItem(
                            index: 1,
                            icon: Icons.confirmation_number_outlined,
                            activeIcon: Icons.confirmation_number_rounded,
                            label: 'Tiket',
                          ),
                          _buildNavItem(
                            index: 2,
                            icon: Icons.smart_toy_outlined,
                            activeIcon: Icons.smart_toy_rounded,
                            label: 'AI',
                          ),
                          _buildNavItem(
                            index: 3,
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            label: 'Profil',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0B3D2E) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : const Color(0xFF9AA6A2),
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
