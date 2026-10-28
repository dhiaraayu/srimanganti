import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/db_helper.dart';

class ReviewScreen extends StatefulWidget {
  final String ticketTitle;
  const ReviewScreen({Key? key, required this.ticketTitle}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int selectedRating = 0;
  final TextEditingController reviewController = TextEditingController();
  final List<String> availableTags = [
    'Pementasan Memukau',
    'Suasana Nyaman',
    'Pelayanan Baik',
    'Akan Datang Lagi',
  ];
  final List<String> selectedTags = [];
  bool _isLoading = false;

  Future<void> _kirimUlasan() async {
    if (selectedRating == 0) return;

    setState(() => _isLoading = true);

    try {
      final email = await DBHelper().getSesi();

      if (email != null) {
        await SupabaseService().createUlasan(
          userEmail: email,
          judulPagelaran: widget.ticketTitle,
          rating: selectedRating,
          teksUlasan: reviewController.text,
          tags: selectedTags,
        );

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Icon(
              Icons.check_circle,
              color: Color(0xFF0B3D2E),
              size: 50,
            ),
            content: const Text(
              'Terima kasih! Ulasan Anda telah tersimpan di database.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Kembali',
                  style: TextStyle(color: Color(0xFF0B3D2E)),
                ),
              ),
            ],
          ),
        );
      } else {
        throw Exception("User tidak ditemukan. Silakan login ulang.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim ulasan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Beri Ulasan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D6E63),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ticketTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B3D2E),
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Keraton Ngayogyakarta',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Bagaimana pengalaman Anda?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B3D2E),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: index < selectedRating
                        ? const Color(0xFFE6A817)
                        : Colors.grey,
                    size: 36,
                  ),
                  onPressed: () => setState(() => selectedRating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tulis Ulasan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B3D2E),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ceritakan keseruan menonton pementasan ini...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE6D5B8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE6D5B8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0B3D2E)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTags.map((tag) {
                bool isSelected = selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () => setState(() {
                    isSelected
                        ? selectedTags.remove(tag)
                        : selectedTags.add(tag);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0B3D2E)
                          : const Color(0xFFE6D5B8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF666666),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (selectedRating > 0 && !_isLoading)
                    ? _kirimUlasan
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3D2E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kirim Ulasan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
