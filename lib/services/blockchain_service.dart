import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Block {
  final int index;
  final String timestamp;
  final String data;
  final String previousHash;
  final String hash;

  Block({
    required this.index,
    required this.timestamp,
    required this.data,
    required this.previousHash,
    required this.hash,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'timestamp': timestamp,
        'data': data,
        'previousHash': previousHash,
        'hash': hash,
      };

  factory Block.fromJson(Map<String, dynamic> json) => Block(
        index: json['index'],
        timestamp: json['timestamp'],
        data: json['data'],
        previousHash: json['previousHash'],
        hash: json['hash'],
      );
}

class BlockchainService {
  static const String _prefKey = 'blockchain_ledger';

  // Fungsi untuk menghitung hash SHA-256 dari sebuah string
  static String _calculateHash(int index, String timestamp, String data, String previousHash) {
    final content = '$index$timestamp$data$previousHash';
    return sha256.convert(utf8.encode(content)).toString();
  }

  // 1. Ambil semua blok dari penyimpanan lokal
  static Future<List<Block>> getChain() async {
    final prefs = await SharedPreferences.getInstance();
    final String? chainJson = prefs.getString(_prefKey);
    
    if (chainJson == null) {
      // Jika belum ada, buat Genesis Block (Blok Pertama)
      final genesisBlock = Block(
        index: 0,
        timestamp: DateTime.now().toIso8601String(),
        data: 'Genesis Block - Srimanganti Ledger',
        previousHash: '0',
        hash: _calculateHash(0, DateTime.now().toIso8601String(), 'Genesis Block - Srimanganti Ledger', '0'),
      );
      return [genesisBlock];
    }

    final List<dynamic> decoded = jsonDecode(chainJson);
    return decoded.map((e) => Block.fromJson(e)).toList();
  }

  // 2. Tambah Blok Baru (Pencatatan Transaksi Tiket)
  static Future<void> addBlock(String dataTiket) async {
    final prefs = await SharedPreferences.getInstance();
    final currentChain = await getChain();

    final lastBlock = currentChain.last;
    final newIndex = lastBlock.index + 1;
    final timestamp = DateTime.now().toIso8601String();
    
    // Hitung hash baru berdasarkan hash blok sebelumnya
    final newHash = _calculateHash(newIndex, timestamp, dataTiket, lastBlock.hash);

    final newBlock = Block(
      index: newIndex,
      timestamp: timestamp,
      data: dataTiket,
      previousHash: lastBlock.hash,
      hash: newHash,
    );

    currentChain.add(newBlock);

    // Simpan kembali ke SharedPreferences
    final String encoded = jsonEncode(currentChain.map((e) => e.toJson()).toList());
    await prefs.setString(_prefKey, encoded);
  }
}