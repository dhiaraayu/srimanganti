import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'hash_helper.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isEmailRegistered(String email) async {
    try {
      String cleanEmail = email.trim().toLowerCase();
      final response = await _client.from('users').select('email').eq('email', cleanEmail).maybeSingle();
      return response != null;
    } catch (e) {
      throw Exception('Gagal memeriksa email: $e');
    }
  }

  Future<void> createUser({
    required String email, required String nama, required String noWa, required String kewarganegaraan, required String password,
  }) async {
    try {
      String hashedPassword = HashHelper.hashPassword(password);
      await _client.from('users').insert({
        'email': email.trim().toLowerCase(), 'nama_lengkap': nama, 'no_whatsapp': noWa, 'kewarganegaraan': kewarganegaraan, 'password': hashedPassword,
      });
    } catch (e) {
      throw Exception('Gagal menyimpan user: $e');
    }
  }

  Future<bool> cekLoginOnline(String email, String password) async {
    try {
      String cleanEmail = email.trim().toLowerCase();
      String hashedPassword = HashHelper.hashPassword(password.trim());
      final response = await _client.from('users').select().eq('email', cleanEmail).maybeSingle();
      if (response == null) return false;
      String dbPassword = response['password']?.toString() ?? '';
      return dbPassword == hashedPassword;
    } catch (e) {
      throw Exception('Gagal cek login online: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    try {
      final response = await _client.from('users').select().eq('email', email).maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Gagal mengambil profil: $e');
    }
  }

  Future<void> updateProfile({required String email, required String nama, required String noWa}) async {
    try {
      await _client.from('users').update({'nama_lengkap': nama, 'no_whatsapp': noWa}).eq('email', email);
    } catch (e) {
      throw Exception('Gagal update profil online: $e');
    }
  }

  Future<void> updatePassword({required String email, required String newPassword}) async {
    try {
      String hashedPassword = HashHelper.hashPassword(newPassword);
      await _client.from('users').update({'password': hashedPassword}).eq('email', email);
    } catch (e) {
      throw Exception('Gagal update password online: $e');
    }
  }

  Future<String?> uploadFotoProfil(String email, String filePath) async {
    try {
      final file = File(filePath);
      final fileName = '${email.replaceAll('@', '_')}.jpg';
      await _client.storage.from('avatars').upload(fileName, file, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
      return _client.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getFotoProfilUrl(String email) async {
    try {
      final fileName = '${email.replaceAll('@', '_')}.jpg';
      final files = await _client.storage.from('avatars').list();
      if (files.any((file) => file.name == fileName)) {
        return _client.storage.from('avatars').getPublicUrl(fileName);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPagelaran() async {
    try {
      final response = await _client.from('pagelaran').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal memuat pagelaran: $e');
    }
  }

  // BALIKIN JADI 1 BARIS DATA PER TRANSAKSI
  Future<void> createTiket({
    required String userEmail,
    required String judulPagelaran,
    required String kodeBooking,
    required int jumlahTiket,
    required int totalHarga,
    required String tanggalKunjungan,
    required String imageAsset,
  }) async {
    try {
      String kodeDanGambar = "$kodeBooking|${imageAsset.split('/').last}";

      await _client.from('tiket').insert({
        'user_email': userEmail,
        'judul_pagelaran': judulPagelaran,
        'kode_booking': kodeDanGambar,
        'jumlah_tiket': jumlahTiket, 
        'total_harga': totalHarga,
        'status': 'Aktif',
        'tanggal_kunjungan': tanggalKunjungan,
      });
    } catch (e) {
      throw Exception('Gagal menyimpan tiket: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistoryTiket(String email) async {
    try {
      final response = await _client.from('tiket').select().eq('user_email', email).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal memuat riwayat tiket: $e');
    }
  }

  Future<void> updateStatusTiket(String idTiket, String statusBaru) async {
    try {
      await _client.from('tiket').update({'status': statusBaru}).eq('id', idTiket);
    } catch (e) {
      throw Exception('Gagal update status tiket: $e');
    }
  }

  Future<void> createUlasan({required String userEmail, required String judulPagelaran, required int rating, required String teksUlasan, required List<String> tags}) async {
    try {
      await _client.from('ulasan').insert({
        'user_email': userEmail, 'judul_pagelaran': judulPagelaran, 'rating': rating, 'teks_ulasan': teksUlasan, 'tags': tags.join(', '),
      });
    } catch (e) {
      throw Exception('Gagal menyimpan ulasan: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUlasan(String judulPagelaran) async {
    try {
      final response = await _client.from('ulasan').select().eq('judul_pagelaran', judulPagelaran).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Gagal memuat ulasan: $e');
    }
  }

  Future<String> generateRingkasanAI(String judulPagelaran) async {
    try {
      final ulasanData = await getUlasan(judulPagelaran);
      if (ulasanData.isEmpty) return "Belum ada ulasan untuk pagelaran ini.";
      String semuaUlasan = ulasanData.map((u) => "- ${u['teks_ulasan']}").join("\n");
      final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: 'ISI SENDIRI');
      final prompt = 'Berikan ringkasan singkat (maksimal 3 kalimat) dalam bahasa Indonesia yang ramah dan menarik dari ulasan penonton pagelaran "$judulPagelaran" berikut ini:\n\n$semuaUlasan';
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "Gagal membuat ringkasan.";
    } catch (e) {
      return "Terjadi kesalahan saat menghubungi AI: $e";
    }
  }
}