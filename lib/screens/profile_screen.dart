import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../services/db_helper.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import 'about_developer_screen.dart'; // <-- IMPORT HALAMAN BARU

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isBlurred = false;
  String activeModal = '';

  String namaLengkap = 'Memuat...';
  String emailUser = 'Memuat...';
  String waUser = 'Memuat...';
  String? fotoProfilUrl;

  bool _isBiometricEnabled = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController waController = TextEditingController();
  final TextEditingController oldPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  int _pentasDitonton = 0;
  int _tiketSiapDigunakan = 0;
  int _levelGames = 1;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await DBHelper().getSesi();
    if (email != null) {
      final prefs = await SharedPreferences.getInstance();
      bool isBioEnabled = prefs.getBool('biometric_enabled') ?? false;

      try {
        final supabaseUser = await SupabaseService().getUserProfile(email);

        if (supabaseUser != null) {
          setState(() {
            namaLengkap = supabaseUser['nama_lengkap'] ?? 'User';
            emailUser = supabaseUser['email'] ?? email;
            waUser = supabaseUser['no_whatsapp'] ?? '-';
            _isBiometricEnabled = isBioEnabled;

            nameController.text = namaLengkap;
            emailController.text = emailUser;
            waController.text = waUser;
          });

          final db = await DBHelper().database;
          await db.update(
            'users',
            {'nama_lengkap': namaLengkap, 'no_whatsapp': waUser},
            where: 'email = ?',
            whereArgs: [email],
          );
        } else {
          _loadFromLocal(email, isBioEnabled);
        }
      } catch (e) {
        _loadFromLocal(email, isBioEnabled);
      }

      final url = await SupabaseService().getFotoProfilUrl(email);
      if (mounted) {
        setState(() {
          fotoProfilUrl = url;
        });
      }
    }
    _loadStatistik();
  }

  Future<void> _loadFromLocal(String email, bool isBioEnabled) async {
    final user = await DBHelper().getUserByEmail(email);
    if (user != null && mounted) {
      setState(() {
        namaLengkap = user['nama_lengkap'] ?? 'User';
        emailUser = user['email'] ?? '-';
        waUser = user['no_whatsapp'] ?? '-';
        _isBiometricEnabled = isBioEnabled;

        nameController.text = namaLengkap;
        emailController.text = emailUser;
        waController.text = waUser;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() {
      _isBiometricEnabled = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Fitur Biometrik diaktifkan!' : 'Fitur Biometrik dimatikan.',
        ),
        backgroundColor: value ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _loadStatistik() async {
    final prefs = await SharedPreferences.getInstance();
    int level = prefs.getInt('level_games') ?? 1;

    int tiketAktif = 0;
    int tiketSelesai = 0;

    try {
      final email = await DBHelper().getSesi();
      if (email != null && email.isNotEmpty) {
        final data = await SupabaseService().getHistoryTiket(email);
        for (var item in data) {
          if (item['status'] == 'Aktif') {
            tiketAktif++;
          } else if (item['status'] == 'Selesai') {
            tiketSelesai++;
          }
        }
      }
    } catch (e) {
      print("Gagal load statistik: $e");
    }

    if (!mounted) return;
    setState(() {
      _levelGames = level;
      _tiketSiapDigunakan = tiketAktif;
      _pentasDitonton = tiketSelesai;
    });
  }

  Future<void> _gantiFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      if (image != null) {
        setState(() => isBlurred = true);

        final email = await DBHelper().getSesi();
        if (email == null) return;

        final newUrl = await SupabaseService().uploadFotoProfil(
          email,
          image.path,
        );

        if (newUrl != null) {
          setState(() {
            fotoProfilUrl = newUrl;
            isBlurred = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diubah!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => isBlurred = false);
          throw Exception("Gagal upload");
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isBlurred = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _simpanIdentitas() async {
    setState(() => isBlurred = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final db = await DBHelper().database;
      await db.update(
        'users',
        {'nama_lengkap': nameController.text, 'no_whatsapp': waController.text},
        where: 'email = ?',
        whereArgs: [emailUser],
      );

      await SupabaseService().updateProfile(
        email: emailUser,
        nama: nameController.text,
        noWa: waController.text,
      );

      setState(() {
        namaLengkap = nameController.text;
        waUser = waController.text;
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data diri berhasil diperbarui di Lokal & Online!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _simpanPassword() async {
    setState(() => isBlurred = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final db = await DBHelper().database;
      final result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [emailUser, oldPassController.text],
      );

      if (result.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi lama salah!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await db.update(
        'users',
        {'password': newPassController.text},
        where: 'email = ?',
        whereArgs: [emailUser],
      );

      await SupabaseService().updatePassword(
        email: emailUser,
        newPassword: newPassController.text,
      );

      oldPassController.clear();
      newPassController.clear();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diubah!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
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
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              'Profil Saya',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadUserData,
                    color: const Color(0xFF0B3D2E),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                      children: [
                        // KARTU PROFIL
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF0EAD6)),
                          ),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  ClipOval(
                                    child: fotoProfilUrl != null
                                        ? Image.network(
                                            fotoProfilUrl!,
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(
                                                  Icons.person,
                                                  size: 90,
                                                ),
                                          )
                                        : Image.asset(
                                            'assets/profil.jpg',
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(
                                                  Icons.person,
                                                  size: 90,
                                                ),
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _gantiFoto,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A3C34),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                namaLengkap,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0B3D2E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6D5B8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  emailUser,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF153D1F),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStat(
                                    '$_pentasDitonton',
                                    'Pentas\nDitonton',
                                  ),
                                  _buildStat(
                                    '$_tiketSiapDigunakan',
                                    'Tiket\nSiap digunakan',
                                  ),
                                  _buildStat(
                                    '$_levelGames',
                                    'Level\nGames',
                                    color: const Color(0xFFD35400),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'PENGATURAN AKUN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E9D2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE6D5B8)),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF0B3D2E),
                                ),
                                title: const Text(
                                  'Ubah Data Identitas Diri',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Nama Pribadi, Alamat, Email',
                                  style: TextStyle(fontSize: 11),
                                ),
                                onTap: () => setState(() {
                                  isBlurred = true;
                                  activeModal = 'identity';
                                }),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.fingerprint,
                                  color: Color(0xFF0B3D2E),
                                ),
                                title: const Text(
                                  'Verifikasi Biometrik',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Aktifkan/Matikan login sidik jari',
                                  style: TextStyle(fontSize: 11),
                                ),
                                trailing: Switch(
                                  value: _isBiometricEnabled,
                                  onChanged: _toggleBiometric,
                                  activeColor: const Color(0xFF0B3D2E),
                                ),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.lock,
                                  color: Color(0xFF0B3D2E),
                                ),
                                title: const Text(
                                  'Kata Sandi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () => setState(() {
                                  isBlurred = true;
                                  activeModal = 'password';
                                }),
                              ),
                              const Divider(height: 1),
                              // MENU BARU: TENTANG DEVELOPER
                              ListTile(
                                leading: const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF0B3D2E),
                                ),
                                title: const Text(
                                  'Tentang Developer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Informasi tim & refleksi proyek',
                                  style: TextStyle(fontSize: 11),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AboutDeveloperScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              // TOMBOL RESET DATA LOKAL
                              ListTile(
                                leading: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  'Reset Data Lokal (Cache)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Hapus data lama di HP, ambil ulang dari Supabase',
                                  style: TextStyle(fontSize: 11),
                                ),
                                onTap: () async {
                                  await DBHelper().hapusSesi();
                                  final db = await DBHelper().database;
                                  await db.delete('users');

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cache lokal berhasil dihapus. Silakan login ulang.',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AuthScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {
                            isBlurred = true;
                            activeModal = 'logout';
                          }),
                          icon: const Icon(Icons.logout),
                          label: const Text('Keluar Akun (Logout)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFADBD8),
                            foregroundColor: const Color(0xFFC0392B),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'Srimanganti Mobile v. 1.0\n© 2026 Hak Cipta Dilindungi',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isBlurred)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6EE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _buildModalContent(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(
    String number,
    String label, {
    Color color = const Color(0xFF0B3D2E),
  }) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isObscure = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: isObscure,
            readOnly: readOnly,
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? Colors.grey[200] : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE6D5B8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE6D5B8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0B3D2E)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalContent() {
    if (activeModal == 'identity') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Ubah Data Identitas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField('Nama Panggilan', nameController),
          _buildTextField('Alamat Email', emailController, readOnly: true),
          _buildTextField('Nomor WhatsApp', waController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => isBlurred = false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _simpanIdentitas,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3D2E),
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (activeModal == 'password') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Ubah Kata Sandi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Kata Sandi Lama',
            oldPassController,
            isObscure: true,
          ),
          _buildTextField(
            'Kata Sandi Baru',
            newPassController,
            isObscure: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => isBlurred = false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _simpanPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3D2E),
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Keluar Akun?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi Srimanganti?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => isBlurred = false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ya, Keluar'),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }
}