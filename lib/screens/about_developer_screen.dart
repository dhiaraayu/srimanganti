import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AboutDeveloperScreen extends StatefulWidget {
  const AboutDeveloperScreen({Key? key}) : super(key: key);

  @override
  State<AboutDeveloperScreen> createState() => _AboutDeveloperScreenState();
}

class _AboutDeveloperScreenState extends State<AboutDeveloperScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/video_kraton.mp4')
      ..initialize()
          .then((_) {
            if (mounted) setState(() => _isVideoInitialized = true);
          })
          .catchError((error) {
            print("Video belum ditambahkan di folder assets.");
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C34),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tentang Developer',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'serif'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // HEADER
          const Center(
            child: Column(
              children: [
                Icon(Icons.code, size: 60, color: Color(0xFFB8862B)),
                SizedBox(height: 12),
                Text(
                  'TIM PENGEMBANG',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color(0xFF0B3D2E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ANGGOTA KELOMPOK
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E9D2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE6D5B8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.groups, color: Color(0xFF0B3D2E), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'ANGGOTA KELOMPOK',
                      style: TextStyle(
                        color: Color(0xFF0B3D2E),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMemberCard('Alvina Kumala Budiastuti', '124240046'),
                const SizedBox(height: 8),
                _buildMemberCard('Dhiara Ayu Nasta', '124240185'),
                const SizedBox(height: 8),
                _buildMemberCard('Nurisshifa Alfiyana', '124240186'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // KESAN & PESAN
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0B3D2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFFE6D5B8), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'CATATAN REFLEKSI PROYEK AKHIR',
                      style: TextStyle(
                        color: Color(0xFFE6D5B8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kesan & Pesan Kuliah Pemrograman Aplikasi Mobile (PAM)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '"Jujur, ngerjain proyek ini bikin jam tidur kami berkurang dan sering begadang. Banyak revisi dan error yang bikin pusing. Tapi dari proses ini kami jadi tahu hal-hal yang sebelumnya nggak kami ngerti. Kami jadi tau gimana cara bikin aplikasi. Pokoknya, ini pengalaman yang bikin capek tapi kami jadi tau banyak hal baru."',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // DOKUMENTASI VIDEO
          const Text(
            'Dokumentasi Kunjungan',
            style: TextStyle(
              color: Color(0xFF0B3D2E),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _isVideoInitialized
                  ? Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _videoController.value.isPlaying
                                  ? _videoController.pause()
                                  : _videoController.play();
                            });
                          },
                          child: Container(
                            color: Colors.black,
                            child: VideoPlayer(_videoController),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FloatingActionButton.small(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            elevation: 0,
                            onPressed: () {
                              setState(() {
                                _videoController.value.isPlaying
                                    ? _videoController.pause()
                                    : _videoController.play();
                              });
                            },
                            child: Icon(
                              _videoController.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: const Color(0xFF0B3D2E),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text(
                          'Video belum tersedia / Loading...',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMemberCard(String name, String nim) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6D5B8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF0B3D2E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B3D2E),
                  ),
                ),
                Text(
                  nim,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}