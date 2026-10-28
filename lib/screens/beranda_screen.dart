import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'minigame_screen.dart';
import 'detail_tiket.dart';
import '../services/db_helper.dart';
import '../services/supabase_service.dart';

import 'package:url_launcher/url_launcher.dart';

/* ---------------- RESPONSIVE HELPER ---------------- */
enum _ScreenSize { compact, medium, expanded }

class _Layout {
  final double width;
  const _Layout(this.width);

  _ScreenSize get size {
    if (width < 600) return _ScreenSize.compact;
    if (width < 1024) return _ScreenSize.medium;
    return _ScreenSize.expanded;
  }

  bool get isCompact => size == _ScreenSize.compact;
  bool get isExpanded => size == _ScreenSize.expanded;

  double get contentMaxWidth => switch (size) {
    _ScreenSize.compact => double.infinity,
    _ScreenSize.medium => 720,
    _ScreenSize.expanded => 1040,
  };

  double get contentWidth => width < contentMaxWidth ? width : contentMaxWidth;
  double get gutter => isCompact ? 16 : 24;

  double get carouselFraction => switch (size) {
    _ScreenSize.compact => 0.76,
    _ScreenSize.medium => 0.5,
    _ScreenSize.expanded => 0.34,
  };

  double get mapHeight => switch (size) {
    _ScreenSize.compact => 220,
    _ScreenSize.medium => 260,
    _ScreenSize.expanded => 300,
  };
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String namaUser = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _loadNamaUser();
  }

  Future<void> _loadNamaUser() async {
    final email = await DBHelper().getSesi();
    if (email != null && email.isNotEmpty) {
      try {
        final onlineUser = await SupabaseService().getUserProfile(email);

        if (onlineUser != null && onlineUser['nama_lengkap'] != null) {
          String fullName = onlineUser['nama_lengkap'].toString();

          if (mounted) {
            setState(() {
              namaUser = fullName.split(' ').first;
            });
          }

          final db = await DBHelper().database;
          await db.update(
            'users',
            {'nama_lengkap': onlineUser['nama_lengkap']},
            where: 'email = ?',
            whereArgs: [email],
          );
          return;
        }
      } catch (e) {
        debugPrint("Gagal ambil nama dari Supabase: $e");
      }

      final localUser = await DBHelper().getUserByEmail(email);
      if (localUser != null && mounted) {
        String fullName = localUser['nama_lengkap'].toString();
        setState(() {
          namaUser = fullName.split(' ').first;
        });
      }
    } else {
      if (mounted) setState(() => namaUser = 'Tamu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF8F0),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = _Layout(constraints.maxWidth);

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF1A3C34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            width: 50,
                            height: 50,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'KERATON NGAYOGYAKARTA',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFFE6D5B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    height: 1.2,
                                  ),
                                ),
                                Text(
                                  'Beranda',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'serif',
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: layout.contentMaxWidth,
                        ),
                        child: layout.isExpanded
                            ? _buildExpanded(layout)
                            : _buildStacked(layout),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStacked(_Layout layout) {
    final g = layout.gutter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(g, 14, g, 0),
          child: const _WorldClockStrip(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(g, 14, g, 0),
          child: _HelloCard(nama: namaUser),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: g),
          child: const _SectionHead(),
        ),
        _ShowCarousel(viewportFraction: layout.carouselFraction),
        Padding(
          padding: EdgeInsets.fromLTRB(g, 22, g, 0),
          child: const _MiniGamesCard(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(g, 18, g, 0),
          child: _PlaceCard(mapHeight: layout.mapHeight),
        ),
      ],
    );
  }

  Widget _buildExpanded(_Layout layout) {
    final g = layout.gutter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(g, 14, g, 0),
          child: const _WorldClockStrip(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(g, 14, g, 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _HelloCard(nama: namaUser)),
                const SizedBox(width: 16),
                const Expanded(child: _MiniGamesCard()),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: g),
          child: const _SectionHead(),
        ),
        _ShowCarousel(viewportFraction: layout.carouselFraction),
        Padding(
          padding: EdgeInsets.fromLTRB(g, 18, g, 0),
          child: _PlaceCard(mapHeight: layout.mapHeight),
        ),
      ],
    );
  }
}

/* ---------------- KARTU MINI GAMES ---------------- */
class _MiniGamesCard extends StatelessWidget {
  const _MiniGamesCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MinigameScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E5631), Color(0xFF0B3D2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.gamepad, color: Color(0xFFE6D5B8), size: 16),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'MINI GAMES BUDAYA',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFE6D5B8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Memory Card',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Asah daya ingatmu lewat kecocokan gambar wayang, batik, dan gamelan.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE6D5B8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Mainkan',
                    style: TextStyle(
                      color: Color(0xFF0B3D2E),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF0B3D2E),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- JAM REAL-TIME ---------------- */
class _WorldClockStrip extends StatefulWidget {
  const _WorldClockStrip();

  @override
  State<_WorldClockStrip> createState() => _WorldClockStripState();
}

class _WorldClockStripState extends State<_WorldClockStrip> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  static const _zones = [
    {'label': 'WIB', 'tz': 'WIB', 'home': true},
    {'label': 'WITA', 'tz': 'WITA', 'home': false},
    {'label': 'WIT', 'tz': 'WIT', 'home': false},
    {'label': 'LONDON', 'tz': 'LONDON', 'home': false},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  DateTime _getTimeForZone(String tz) {
    if (tz == 'WIB') return _now.toUtc().add(const Duration(hours: 7));
    if (tz == 'WITA') return _now.toUtc().add(const Duration(hours: 8));
    if (tz == 'WIT') return _now.toUtc().add(const Duration(hours: 9));

    final y = _now.year;
    final start = DateTime.utc(y, 3, 31)
        .subtract(Duration(days: DateTime.utc(y, 3, 31).weekday % 7))
        .add(const Duration(hours: 1));
    final end = DateTime.utc(y, 10, 31)
        .subtract(Duration(days: DateTime.utc(y, 10, 31).weekday % 7))
        .add(const Duration(hours: 1));
    final isBST = _now.toUtc().isAfter(start) && _now.toUtc().isBefore(end);

    return _now.toUtc().add(Duration(hours: isBST ? 1 : 0));
  }

  String _offsetLabel(String tz) {
    if (tz == 'WIB') return 'UTC+7';
    if (tz == 'WITA') return 'UTC+8';
    if (tz == 'WIT') return 'UTC+9';
    final isBST = _getTimeForZone('LONDON').hour != _now.toUtc().hour;
    return isBST ? 'UTC+1' : 'UTC+0';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADFCB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_zones.length, (i) {
          final z = _zones[i];
          final isHome = z['home'] as bool;
          final timeStr = _timeFormat.format(
            _getTimeForZone(z['tz'] as String),
          );

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(left: BorderSide(color: Color(0xFFF0E8D8))),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      z['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isHome
                            ? const Color(0xFFB8862B)
                            : const Color(0xFF6B7A75),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A3C34),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _offsetLabel(z['tz'] as String),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF9AA6A2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/* ---------------- HELLO CARD ---------------- */
class _HelloCard extends StatelessWidget {
  final String nama;
  const _HelloCard({required this.nama});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C5E4F), Color(0xFF1F463C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6D58E).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFFF6D58E)),
                    SizedBox(width: 6),
                    Text(
                      'Keraton Ngayogyakarta',
                      style: TextStyle(
                        color: Color(0xFFF6D58E),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sugeng Rawuh,',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFCFE0DA),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$nama 👋🏻',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Rasakan keagungan seni tradisi di panggung keraton tertua hari ini.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFA9C2BA),
                  height: 1.5,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  right: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF6D58E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- SECTION HEAD ---------------- */
class _SectionHead extends StatelessWidget {
  const _SectionHead();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 22, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JADWAL EKSKLUSIF',
                  style: TextStyle(
                    color: Color(0xFFB8862B),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pilihan Pagelaran',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF1A3C34),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Geser ›',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFB8862B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- CAROUSEL 3D ---------------- */
class _ShowCarousel extends StatelessWidget {
  final double viewportFraction;

  const _ShowCarousel({required this.viewportFraction});

  static const String _dir = 'assets/';

  static const List<Map<String, String>> shows = [
    {
      'title': 'Uyon-Uyon',
      'day': 'Selasa',
      'image': '${_dir}uyon_uyon_selasa.webp',
      'desc': 'Uyon-uyon adalah pertunjukan musik gamelan tradisional Jawa yang biasanya diiringi dengan tembang dan tarian klasik. Dalam pementasan ini, Anda akan disuguhkan harmoni gamelan yang menenangkan, dipadukan dengan gerak gemulai penari Keraton. Suasana tenang dan khidmat akan membawa Anda merasakan kedamaian budaya Jawa yang autentik.',
    },
    {
      'title': 'Wayang Golek',
      'day': 'Rabu',
      'image': '${_dir}wayang_golek_rabu.webp',
      'desc': 'Wayang golek adalah seni pertunjukan boneka kayu khas Sunda yang sangat populer. Namun, dalam versi Keraton Yogyakarta ini, wayang golek disajikan dengan sentuhan gaya Yogyakarta yang khas. Cerita yang diangkat biasanya seputar legenda lokal dan epik Mahabharata, disampaikan dengan iringan gamelan dan sinden yang memukau.',
    },
    {
      'title': 'Wayang Kulit',
      'day': 'Kamis',
      'image': '${_dir}wayang_kulit_kamis.webp',
      'desc': 'Saksikan keindahan seni wayang kulit klasik gaya Yogyakarta yang dibawakan oleh dalang senior dari Keraton. Pementasan ini mengangkat lakon epik Mahabharata dengan iringan gamelan Jawa yang syahdu, sinden, dan tata cahaya yang memukau. Rasakan suasana sakral dan magis di Bangsal Srimanganti yang bersejarah.',
    },
    {
      'title': 'Macapat',
      'day': 'Jumat',
      'image': '${_dir}macapat_jumat.webp',
      'desc': 'Macapat adalah tradisi membaca puisi Jawa klasik (tembang) dengan aturan guru gatra, guru wilangan, dan guru lagu tertentu. Pementasan macapat di Keraton ini menyajikan tembang-tembang sakral yang dibawakan oleh para abdi dalem, menciptakan suasana khusyuk dan sarat akan makna filosofis.',
    },
    {
      'title': 'Fragmen Wayang Wong',
      'day': 'Sabtu',
      'image': '${_dir}fragmen_wayang_wong_sabtu.webp',
      'desc': 'Wayang Wong adalah seni pertunjukan tari drama yang dimainkan oleh manusia, bukan boneka. Fragmen ini menceritakan kisah kepahlawanan Raden Arjuna dalam memperjuangkan kebenaran. Dengan gerakan yang luwes, kostum yang megah, serta iringan gamelan yang dinamis, pertunjukan ini menyajikan pengalaman visual dan musikal yang memikat.',
    },
    {
      'title': 'Gladhen Beksan',
      'day': 'Minggu',
      'image': '${_dir}gladhen_beksan_minggu.webp',
      'desc': 'Gladhen Beksan adalah latihan rutin tari klasik Jawa yang dilakukan di Keraton. Meskipun berupa latihan, pertunjukan ini terbuka untuk umum dan menjadi daya tarik tersendiri bagi wisatawan. Anda dapat melihat langsung proses para penari muda Keraton mengasah kemampuan mereka dalam menarikan tarian sakral.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final height = 250 + (textScale - 1).clamp(0.0, 0.3) * 100;

    final behavior = ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      },
    );

    return ScrollConfiguration(
      behavior: behavior,
      child: CarouselSlider.builder(
        itemCount: shows.length,
        options: CarouselOptions(
          height: height,
          viewportFraction: viewportFraction,
          enlargeCenterPage: true,
          enlargeFactor: 0.15,
          enableInfiniteScroll: true,
          autoPlay: false,
          scrollDirection: Axis.horizontal,
        ),
        itemBuilder: (context, index, realIndex) {
          final show = shows[index];

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3C34),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        show['image']!,
                        fit: BoxFit.cover,
                        cacheWidth: 800,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFD9D9D9),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.45, 1.0],
                            colors: [Colors.transparent, Color(0xCC0B1F1A)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 8,
                        child: Text(
                          show['title']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: 'serif',
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFFF6D58E),
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              show['day']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShowDetailScreen(
                                title: show['title']!,
                                day: show['day']!,
                                image: show['image']!,
                                description: show['desc']!,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF6D58E),
                            foregroundColor: const Color(0xFF1A3C34),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'BELI TIKET',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ---------------- PLACE CARD (PETA INTERAKTIF) ---------------- */
class _PlaceCard extends StatelessWidget {
  final double mapHeight;

  const _PlaceCard({required this.mapHeight});

  // Koordinat perkiraan, cek lagi di Google Maps lalu sesuaikan
  static const LatLng _lokasi = LatLng(-7.8053, 110.3642);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0E6),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: mapHeight,
            width: double.infinity,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: _lokasi,
                initialZoom: 17,
                minZoom: 5,
                maxZoom: 19,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.example.nama_app_lu', // ganti sesuai package name
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _lokasi,
                      width: 150,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A3C34),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.place,
                              color: Color(0xFFF6D58E),
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A3C34),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Bangsal Srimanganti',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChip('➤ 250m dari Alun-Alun Utara'),
                    _buildChip('🕗 Buka Pukul 08.30 WIB'),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kompleks Keraton Yogyakarta, Jl. Rotowijayan, Kadipaten, Keraton, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55132',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3D4B46),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE6E0D3),
                      foregroundColor: const Color(0xFF1A3C34),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final Uri url = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=Bangsal+Srimanganti+Keraton+Yogyakarta',
                      );

                      if (!await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      )) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tidak bisa membuka Google Maps'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      '➤ Buka Petunjuk di Google Maps',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E0D3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3D4B46),
        ),
      ),
    );
  }
}
