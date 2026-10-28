import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

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

  static const String _groqApiKey = 'ISI_API_DI_SINI';

  final List<Map<String, String>> _chatHistory = [
    {
      'role': 'system',
      'content':
          'Kamu adalah "Srimanganti AI", teman ngobrol Gen Z yang chill, asik, dan ga kaku dari aplikasi Keraton Yogyakarta. '
          'ATURAN KETAT: '
          '1. WAJIB pakai bahasa Indonesia santai. Panggil "aku" dan "kamu". '
          '2. JANGAN kaku. Boleh sesekali pakai kata "gas", "nih", "banget", "sih", atau emoji dikit. '
          '3. WAJIB BACA DATA: Kamu akan selalu diberikan data jadwal dari database beserta informasi hari ini. Jika user tanya jadwal/harga, HARUS jawab sesuai data yang dikasih. '
          '4. Jam semua pementasan adalah 09.00 - 11.00 WIB. '
          '5. Kalau user nanya di luar topik, balikin ke topik tiket/pentas dengan santai.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'isUser': false,
      'text': 'Sugeng rawuh! 👋 Aku Srimanganti AI. Mau tanya **jadwal pentas**, **harga tiket**, atau info seru soal Keraton? Gas aja tanya apa aja ya!',
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
      String konteksDatabase = "=== DATA JADWAL KERATON ===\n";
      try {
        final pagelaran = await SupabaseService().getPagelaran();
        if (pagelaran.isEmpty) {
          konteksDatabase += "Data kosong.\n";
        } else {
          for (var p in pagelaran) {
            konteksDatabase +=
                "- ${p['judul']} | Hari: ${p['hari']} | 09.00-11.00 WIB | WNI: Rp ${p['harga_wni']} | WNA: Rp ${p['harga_wna']}\n";
          }
        }
      } catch (e) {
        konteksDatabase += "Gagal load database.\n";
      }

      final now = DateTime.now();
      // Daftar nama hari dalam bahasa Indonesia (1 = Senin, 7 = Minggu)
      const listHari = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      final hariIni = listHari[now.weekday - 1];
      final tanggalIni = "${now.day}-${now.month}-${now.year}";

      final promptLengkap =
          """
INFORMASI HARI INI: Hari $hariIni, tanggal $tanggalIni.

DATA JADWAL KERATON DARI DATABASE:
$konteksDatabase

PERTANYAAN USER: "$text"

ATURAN JAWAB:
1. Jawab dengan gaya Gen Z yang asik.
2. Jika user tanya jadwal "hari ini", COCOKKAN dengan INFORMASI HARI INI di atas, lalu cari jadwal yang harinya sama di DATA JADWAL KERATON.
3. Jika user tanya jadwal/harga, cari di data. Jangan ngarang!
""";

      // Masukkan pesan user ke history
      _chatHistory.add({'role': 'user', 'content': promptLengkap});

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'openai/gpt-oss-120b',
          'messages': _chatHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = data['choices'][0]['message']['content'];

        // Masukkan balasan bot ke history biar nyambung
        _chatHistory.add({'role': 'assistant', 'content': botReply});

        if (!mounted) return;
        setState(() {
          _messages.add({'isUser': false, 'text': botReply});
          _isLoading = false;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print("================ ERROR GROQ ================");
      print(e.toString());
      print("============================================");

      if (!mounted) return;
      setState(() {
        _messages.add({'isUser': false, 'text': '❌ **Error Sistem:**\n\n$e'});
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C34),
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFE6D5B8),
              radius: 18,
              child: Icon(Icons.smart_toy, size: 22, color: Color(0xFF1A3C34)),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Srimanganti AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'Online nih 👋',
                      style: TextStyle(fontSize: 11, color: Colors.greenAccent),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/bg_chat.png', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }

                      final msg = _messages[index];
                      final isUser = msg['isUser'] as bool;

                      return _buildChatBubble(msg['text'], isUser);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      top: BorderSide(color: Color(0xFFEADFCB)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F5F0),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFEADFCB)),
                          ),
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _kirimPesan(),
                            decoration: const InputDecoration(
                              hintText: 'Ketik pesan...',
                              hintStyle: TextStyle(
                                color: Color(0xFF9AA6A2),
                                fontSize: 14,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: _isLoading
                            ? const Color(0xFF9AA6A2)
                            : const Color(0xFF1A3C34),
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
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
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFFE6D5B8),
              radius: 16,
              child: Icon(Icons.smart_toy, size: 18, color: Color(0xFF1A3C34)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1A3C34) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFEADFCB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    height: 1.5,
                    fontSize: 14,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUser
                        ? const Color(0xFFE6D5B8)
                        : const Color(0xFF1A3C34),
                  ),
                  listBullet: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Color(0xFF1A3C34),
              radius: 16,
              child: Text(
                'U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE6D5B8),
            radius: 16,
            child: Icon(Icons.smart_toy, size: 18, color: Color(0xFF1A3C34)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.zero,
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: const Color(0xFFEADFCB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFF9AA6A2),
              const Color(0xFF1A3C34),
              value,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
