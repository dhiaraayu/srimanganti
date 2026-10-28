import 'package:flutter/material.dart';
import 'dart:math';

class ETicketScreen extends StatefulWidget {
  final String title;
  final String date;
  final String time;
  final String kodeBooking;
  final int ticketCount;
  final String imageAsset;

  const ETicketScreen({
    Key? key,
    required this.title,
    required this.date,
    required this.time,
    required this.kodeBooking,
    required this.ticketCount,
    required this.imageAsset,
  }) : super(key: key);

  @override
  State<ETicketScreen> createState() => _ETicketScreenState();
}

class _ETicketScreenState extends State<ETicketScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // BIKIN KODE TIKET JADI LEBIH PENDEK
  String _getKodeTiket(int index) {
    String kodePendek = widget.kodeBooking;
    if (kodePendek.length > 6) {
      kodePendek = kodePendek.substring(kodePendek.length - 6);
    }
    final total = widget.ticketCount;
    final pad = total.toString().length;
    return 'TIKET-$kodePendek-${(index + 1).toString().padLeft(pad, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalTiket = widget.ticketCount;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87), 
          onPressed: () => Navigator.pop(context)
        ),
        title: const Text(
          'E - Ticket', 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 20)
        ),
      ),
      body: Column(
        children: [
          if (totalTiket > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Tiket ${_currentPage + 1} dari $totalTiket',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A3C34)),
              ),
            ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalTiket,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: _buildTicketCard(_getKodeTiket(index)),
                  ),
                );
              },
            ),
          ),
          if (totalTiket > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalTiket, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF153D1F) : const Color(0xFFE6D5B8), 
                      borderRadius: BorderRadius.circular(4)
                    ),
                  );
                }),
              ),
            ),
          if (totalTiket > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.swipe, size: 16, color: Colors.grey), 
                  SizedBox(width: 6), 
                  Text('Geser untuk melihat tiket lainnya', style: TextStyle(fontSize: 11, color: Colors.grey))
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(String ticketNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                child: Image.asset(
                  widget.imageAsset, 
                  height: 345, 
                  width: double.infinity, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 345, 
                    color: Colors.grey[300], 
                    child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey))
                  ),
                ),
              ),
              Container(
                width: double.infinity, 
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                decoration: const BoxDecoration(
                  color: Color(0xFF153D1F), 
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))
                ),
                child: Column(
                  children: [
                    
                    // ==========================================
                    // BAGIAN TANGGAL & WAKTU YANG UDAH DIBENERIN
                    // ==========================================
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          // Tanggal dikasih Expanded biar dia nyesuaiin sisa ruang
                          Expanded(
                            child: _buildInfo(label: 'Tanggal', value: widget.date),
                          ),
                          const SizedBox(width: 8), // Jarak aman
                          // Waktu rata kanan
                          _buildInfo(label: 'Waktu', value: widget.time),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // NOMOR TIKET
                    Text(
                      ticketNumber, 
                      textAlign: TextAlign.center, 
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 2.0
                      )
                    ),
                    
                    const SizedBox(height: 12),
                    // Barcode
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: SizedBox(
                        height: 60, 
                        width: double.infinity, 
                        child: CustomPaint(painter: _ManualBarcodePainter(ticketNumber))
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tunjukkan barcode ini ke petugas di pintu masuk', 
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontStyle: FontStyle.italic)
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Lubang tiket kiri & kanan
          Positioned(top: 345 - 15, left: -15, child: _buildTicketHole()),
          Positioned(top: 345 - 15, right: -15, child: _buildTicketHole()),
          // Garis putus-putus
          Positioned(
            top: 345, left: 20, right: 20,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: List.generate(
                    (constraints.maxWidth / 10).floor(),
                    (index) => Container(
                      width: 6, height: 1, margin: const EdgeInsets.only(right: 4), color: Colors.white.withOpacity(0.3)
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET INI JUGA GUE BENERIN BIAR TEKSNYA BISA NYUSUT OTOMATIS
  Widget _buildInfo({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ', 
          style: const TextStyle(color: Color(0xFFD4B57E), fontSize: 11, fontWeight: FontWeight.w600)
        ),
        const SizedBox(height: 2),
        // FittedBox bikin teks "Sabtu, 31 Okt 2026" otomatis ngecil kalau sempit
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value, 
            maxLines: 1,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
          ),
        ),
      ],
    );
  }

  Widget _buildTicketHole() {
    return Container(
      width: 30, 
      height: 30, 
      decoration: const BoxDecoration(
        color: Color(0xFFFDF8F0), 
        shape: BoxShape.circle
      )
    );
  }
}

class _ManualBarcodePainter extends CustomPainter {
  final String data;
  _ManualBarcodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final random = Random(data.hashCode);
    double currentX = 0;
    while (currentX < size.width) {
      double lineWidth = random.nextDouble() * 3 + 1;
      double gap = random.nextDouble() * 2 + 1;
      canvas.drawRect(Rect.fromLTWH(currentX, 0, lineWidth, size.height), paint);
      currentX += lineWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}