import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  // Jangan tulis API key langsung di kode.
  // Jalankan dengan:
  //   flutter run --dart-define=GEMINI_API_KEY=AIza...
  // Untuk produksi, lebih aman panggil Gemini lewat Supabase Edge Function.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  late GenerativeModel _model;
  late ChatSession _chat;

  @override
  void initState() {
    super.initState();

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'Kamu adalah asisten virtual cerdas dari aplikasi Srimanganti Keraton Yogyakarta. '
        'Tugasmu adalah membantu pengguna menjawab pertanyaan seputar jadwal pagelaran, harga tiket, lokasi, dan budaya Jawa. '
        'Jawablah dengan sopan, ramah, dan gunakan bahasa yang sedikit elegan seperti abdi dalem Keraton. '
        'Jika pengguna bertanya di luar topik Keraton Yogyakarta atau aplikasi ini, tolak dengan halus.',
      ),
    );

    _chat = _model.startChat();

    _messages.add({
      'isUser': false,
      'text': 'Sugeng rawuh! Saya asisten virtual Srimanganti. Ada yang bisa saya bantu terkait jadwal pentas atau tiket Keraton hari ini?',
    });
  }

  Future<void> _kirimPesan() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _isLoading = true;
      _controller.clear();
    });

    _scrollKeBawah();

    try {
      String konteksDatabase = "";

      try {
        final pagelaran = await SupabaseService().getPagelaran();
        if (pagelaran.isNotEmpty) {
          konteksDatabase += "Daftar Pagelaran Keraton:\n";
          for (var p in pagelaran) {
            konteksDatabase +=
                "- ${p['judul']} (Hari: ${p['hari']}, Harga WNI: ${p['harga_wni']}, Harga WNA: ${p['harga_wna']})\n";
          }
        }

        final ulasan = await SupabaseService().getUlasan('Wayang Kulit');
        if (ulasan.isNotEmpty) {
          konteksDatabase += "\nBeberapa Ulasan Penonton Wayang Kulit:\n";
          for (var u in ulasan.take(3)) {
            konteksDatabase += "- \"${u['teks_ulasan']}\"\n";
          }
        }
      } catch (e) {
        debugPrint("Gagal ambil data database untuk AI: $e");
      }

      final promptLengkap =
          """
Gunakan data berikut untuk menjawab pertanyaan user jika relevan.
JIKA pertanyaan tidak ada di data, jawab berdasarkan pengetahuan umummu tentang Keraton Yogyakarta.

DATA APLIKASI:
$konteksDatabase

PERTANYAAN USER:
$text
""";

      final response = await _chat.sendMessage(Content.text(promptLengkap));

      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'text': response.text ?? 'Maaf, saya tidak mengerti maksud Anda.',
        });
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'text': 'Terjadi kesalahan koneksi: $e',
        });
        _isLoading = false;
      });
    }
    _scrollKeBawah();
  }

  void _scrollKeBawah() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ruang untuk navbar diatur oleh MainNavigationScreen (lewat Padding),
    // jadi ChatScreen tidak perlu tahu soal navbar atau keyboard.
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C34),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFE6D5B8),
              radius: 16,
              child: Icon(Icons.smart_toy, size: 20, color: Color(0xFF1A3C34)),
            ),
            SizedBox(width: 10),
            Text(
              'Srimanganti AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF1A3C34) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isUser
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottomRight: isUser
                              ? Radius.zero
                              : const Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['text'],
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: CircularProgressIndicator(color: Color(0xFF1A3C34)),
              ),

            // INPUT CHAT
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEADFCB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _kirimPesan(),
                      decoration: InputDecoration(
                        hintText: 'Tanya jadwal atau tiket...',
                        filled: true,
                        fillColor: const Color(0xFFF7F5F0),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1A3C34),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isLoading ? null : _kirimPesan,
                    ),
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
