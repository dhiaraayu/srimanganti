import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class MinigameScreen extends StatefulWidget {
  const MinigameScreen({Key? key}) : super(key: key);

  @override
  State<MinigameScreen> createState() => _MinigameScreenState();
}

class _MinigameScreenState extends State<MinigameScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> levels = [
    {'level': 1, 'cards': 6, 'time': 30},
    {'level': 2, 'cards': 12, 'time': 45},
    {'level': 3, 'cards': 16, 'time': 60},
  ];

  final List<String> allImages = [
    'assets/wayang1.jpg', 'assets/wayang2.jpg', 'assets/wayang3.jpg',
    'assets/gamelan1.jpg', 'assets/gamelan2.jpg', 'assets/gamelan3.jpg',
    'assets/batik1.jpg', 'assets/batik2.jpg', 'assets/batik3.jpg',
  ];

  int currentLevelIndex = 0;
  List<String> currentCards = [];
  List<bool> cardFlipped = [];
  List<bool> cardMatched = [];
  int? firstCardIndex;
  int matchedPairs = 0;
  int timeLeft = 0;
  Timer? timer;
  bool isGameOver = false;
  bool isLevelComplete = false;
  bool lockBoard = false;
  
  bool isCountdown = true;
  int countdownValue = 3;
  Timer? countdownTimer;

  late AnimationController _shuffleController;
  late Animation<double> _shuffleScale;

  @override
  void initState() {
    super.initState();
    
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _shuffleScale = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _shuffleController, curve: Curves.easeInOut),
    );

    startCountdown(0);
  }

  void startCountdown(int levelIndex) {
    setState(() {
      currentLevelIndex = levelIndex;
      isCountdown = true;
      countdownValue = 3;
      isGameOver = false;
      isLevelComplete = false;
      firstCardIndex = null;
      matchedPairs = 0;
      lockBoard = false;
      cardFlipped = [];
      cardMatched = [];
      currentCards = [];
      timer?.cancel();
    });

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdownValue > 1) {
        setState(() => countdownValue--);
      } else {
        t.cancel();
        setState(() {
          countdownValue = 0; 
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() => isCountdown = false);
          startLevel(levelIndex);
        });
      }
    });
  }

  Future<void> startLevel(int levelIndex) async {
    int numCards = levels[levelIndex]['cards'];
    timeLeft = levels[levelIndex]['time'];

    int pairs = numCards ~/ 2;
    List<String> selectedImages = allImages.take(pairs).toList();
    List<String> tempCards = [...selectedImages, ...selectedImages];
    tempCards.shuffle(Random());

    // 1. TAMPILKAN GAMBAR DEPAN
    setState(() {
      currentLevelIndex = levelIndex;
      firstCardIndex = null;
      matchedPairs = 0;
      isGameOver = false;
      isLevelComplete = false;
      lockBoard = true;
      
      currentCards = tempCards;
      cardFlipped = List.generate(numCards, (index) => true); // Kebuka semua
      cardMatched = List.generate(numCards, (index) => false);
    });

    // Tahan 1.2 detik
    await Future.delayed(const Duration(milliseconds: 1200));

    // 2. ANIMASI SHUFFLE
    await _shuffleController.forward(); // Ngecil
    
    setState(() {
      cardFlipped = List.generate(numCards, (index) => false); // Tutup semua (jadi logo)
      currentCards.shuffle(Random()); // Acak posisi
    });

    await _shuffleController.reverse(); // Membesar

    // 3. MULAI GAME
    setState(() {
      lockBoard = false;
    });

    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        t.cancel();
        setState(() => isGameOver = true);
      }
    });
  }

  void onCardTap(int index) {
    if (lockBoard || cardFlipped[index] || cardMatched[index] || isCountdown) return;

    setState(() {
      cardFlipped[index] = true;
    });

    if (firstCardIndex == null) {
      firstCardIndex = index;
    } else {
      lockBoard = true;
      
      if (currentCards[firstCardIndex!] == currentCards[index]) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            cardMatched[firstCardIndex!] = true;
            cardMatched[index] = true;
            firstCardIndex = null;
            matchedPairs++;
            lockBoard = false;
          });
          checkWinCondition();
        });
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() {
            cardFlipped[firstCardIndex!] = false;
            cardFlipped[index] = false;
            firstCardIndex = null;
            lockBoard = false;
          });
        });
      }
    }
  }

  void checkWinCondition() async {
    int totalPairs = levels[currentLevelIndex]['cards'] ~/ 2;
    if (matchedPairs == totalPairs) {
      timer?.cancel();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('level_games', currentLevelIndex + 1);

      if (currentLevelIndex < levels.length - 1) {
        setState(() => isLevelComplete = true);
      } else {
        setState(() => isGameOver = true);
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    countdownTimer?.cancel();
    _shuffleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int numCards = currentCards.isNotEmpty ? currentCards.length : levels[currentLevelIndex]['cards'];
    int crossAxisCount = currentLevelIndex == 2 ? 4 : 3;

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Positioned.fill(
            child: Image.asset(
              'assets/bg_minigame.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF0B3D2E));
              },
            ),
          ),
          Container(color: Colors.black.withOpacity(0.15)),

          // KONTEN UTAMA
          SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3D2E)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Minigame',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Serif',
                          shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // INFO BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🏅 LEVEL ${currentLevelIndex + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                        ),
                        Text(
                          '⏱️ ${timeLeft}s',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC0392B)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // AREA KARTU (TENGAH)
                Expanded(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -10),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: AnimatedBuilder(
                          animation: _shuffleController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _shuffleScale.value,
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: numCards,
                                itemBuilder: (context, index) {
                                  if (currentCards.isEmpty) return const SizedBox();
                                  bool isFlipped = cardFlipped[index] || cardMatched[index];
                                  return _buildAnimatedCard(index, isFlipped);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // TOMBOL NEXT LEVEL
                SizedBox(
                  height: 90, 
                  child: isLevelComplete 
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => startCountdown(currentLevelIndex + 1),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B3D2E), 
                                foregroundColor: Colors.white, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                              ),
                              child: const Text('Lanjut ke Level Berikutnya →', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        )
                      : const SizedBox(), 
                ),
              ],
            ),
          ),

          // OVERLAY COUNTDOWN
          if (isCountdown)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Text(
                    countdownValue > 0 ? '$countdownValue' : 'GO!',
                    style: const TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                      fontFamily: 'Serif',
                      shadows: [Shadow(color: Colors.black54, blurRadius: 20)],
                    ),
                  ),
                ),
              ),
            ),

          // OVERLAY MENANG
          if (isGameOver)
            Container(
              color: const Color(0xFF0B3D2E),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 100)),
                    const SizedBox(height: 20),
                    Text(
                      matchedPairs == levels[currentLevelIndex]['cards'] ~/ 2 ? 'Luar Biasa!' : 'Waktu Habis!',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), fontFamily: 'Serif'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      matchedPairs == levels[currentLevelIndex]['cards'] ~/ 2
                          ? 'Kamu telah menyelesaikan seluruh tantangan Memory Card Budaya Srimanganti. Kamu adalah Penjaga Budaya Sejati!'
                          : 'Kamu gagal di level ini. Ayo coba lagi!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (matchedPairs == levels[currentLevelIndex]['cards'] ~/ 2) {
                            startCountdown(0);
                          } else {
                            startCountdown(currentLevelIndex);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: const Color(0xFF0B3D2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                        child: Text(matchedPairs == levels[currentLevelIndex]['cards'] ~/ 2 ? 'Main Lagi' : 'Ulangi Level Ini', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                        child: const Text('Kembali ke Beranda'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(int index, bool isFlipped) {
    return GestureDetector(
      onTap: () => onCardTap(index),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: isFlipped ? 0.0 : 1.0, end: isFlipped ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final isFront = value > 0.5; 
          final rotationAngle = value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) 
            ..rotateY(rotationAngle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: isFront ? Colors.white : const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFront 
                      ? (cardMatched[index] ? Colors.green : const Color(0xFFE6D5B8))
                      : const Color(0xFFD4AF37), 
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: isFront 
                    // DEPAN: KAYAK AWAL (BoxFit.contain & padding)
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          currentCards[index], 
                          fit: BoxFit.contain, // <-- KEMBALI KE CONTAIN
                        ),
                      )
                    // BELAKANG: FULLIN (BoxFit.cover)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi), 
                        child: Image.asset(
                          'assets/logo.png', 
                          fit: BoxFit.cover, // <-- BELAKANG DI-FULL-IN
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.lock_outline, color: Color(0xFFD4AF37), size: 30);
                          },
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}