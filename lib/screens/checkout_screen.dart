import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'payment_screen.dart';
import '../services/supabase_service.dart';
import '../services/db_helper.dart';
import '../services/notification_service.dart';
import '../services/polygon_service.dart'; 

class CheckoutScreen extends StatefulWidget {
  final String title;
  final int basePrice;
  final String categoryName;
  final String imageAsset;
  final String day; 

  const CheckoutScreen({
    Key? key,
    required this.title,
    required this.basePrice,
    required this.categoryName,
    required this.imageAsset,
    required this.day,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int selectedDateIndex = -1;
  int ticketCount = 1;
  final int serviceFee = 2000;
  final int maxTickets = 10;

  List<Map<String, dynamic>> availableDates = [];

  @override
  void initState() {
    super.initState();
    _generateRealtimeDates();
  }

  void _generateRealtimeDates() {
    final now = DateTime.now();
    final DateFormat dayFormat = DateFormat('EEEE', 'id_ID');
    final DateFormat dateFormat = DateFormat('dd MMM', 'id_ID');
    
    List<Map<String, dynamic>> tempDates = [];
    
    for (int i = 0; i <= 30; i++) {
      DateTime checkDate = now.add(Duration(days: i));
      String namaHari = dayFormat.format(checkDate);
      
      if (namaHari.toLowerCase() == widget.day.toLowerCase()) {
        bool isTodayAndPassed = false;
        if (i == 0 && now.hour >= 11) {
          isTodayAndPassed = true;
        }

        if (!isTodayAndPassed) {
          tempDates.add({
            'day': namaHari, 
            'date': dateFormat.format(checkDate), 
            'fullDate': DateFormat('yyyy-MM-dd').format(checkDate), 
            'isAvailable': true,
          });
        }
      }
    }

    setState(() {
      availableDates = tempDates;
      if (availableDates.isNotEmpty) {
        selectedDateIndex = 0; 
      }
    });
  }

  int get subtotal => widget.basePrice * ticketCount;
  int get totalBayar => subtotal + serviceFee;

  String _formatRupiah(int amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  // ==========================================
  // PROSES PEMESANAN + BLOCKCHAIN (DENGAN ERROR HANDLING)
  // ==========================================
  void _prosesPemesanan() async {
    if (selectedDateIndex == -1 || availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada jadwal tersedia untuk dipilih!'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final email = await DBHelper().getSesi();
      final kodeBooking = 'KGY-SRM-${DateTime.now().millisecondsSinceEpoch}';
      final tglKunjungan = availableDates[selectedDateIndex]['fullDate'];

      // 1. SIMPAN KE SUPABASE
      await SupabaseService().createTiket(
        userEmail: email ?? 'guest@srimanganti.com',
        judulPagelaran: widget.title,
        kodeBooking: kodeBooking,
        jumlahTiket: ticketCount,
        totalHarga: totalBayar,
        tanggalKunjungan: tglKunjungan,
        imageAsset: widget.imageAsset,
      );

      // 2. SIMPAN KE BLOCKCHAIN
      final polygonService = PolygonService();
      final BigInt hargaPerTiketWei = BigInt.parse('10000000000000000'); 
      final BigInt totalBayarWei = hargaPerTiketWei * BigInt.from(ticketCount);

      // BLOK KHUSUS UNTUK MENANGKAP ERROR BLOCKCHAIN
      try {
        String txHash = await polygonService.beliTiketOnChain(
          totalHargaWei: totalBayarWei,
          jumlahTiket: ticketCount,
        );
        print("✅ Blockchain Success! Hash: $txHash");
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Tutup loading
          // Tampilkan Pop-up Error yang Jelas
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Gagal ke Blockchain', style: TextStyle(color: Colors.red)),
              content: Text(e.toString(), style: const TextStyle(fontSize: 13)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        }
        return; // Hentikan proses, jangan lanjut ke halaman pembayaran
      }

      // 3. NOTIFIKASI
      await NotificationService.scheduleNotificationInSeconds(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Pembayaran Berhasil!',
        body: 'Tiket ${widget.title} kamu sudah aktif & tercatat di Blockchain. Cek di menu Riwayat ya!',
        seconds: 2, 
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      // 4. KE HALAMAN PEMBAYARAN
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(totalAmount: totalBayar),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses tiket: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Konfirmasi Pembayaran', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'serif')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 4, height: 60, decoration: BoxDecoration(color: const Color(0xFFB8862B), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PENTAS SENI KERATON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34), fontFamily: 'serif')),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text('Bangsal Srimanganti, Keraton Yogyakarta', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PILIH TANGGAL KUNJUNGAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34))),
                      Text(DateFormat('MMM yyyy', 'id_ID').format(DateTime.now()), style: const TextStyle(fontSize: 11, color: Color(0xFFB8862B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (availableDates.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Tidak ada jadwal tersedia bulan ini.', style: TextStyle(fontSize: 12, color: Colors.grey))))
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(availableDates.length, (index) {
                          bool isSelected = selectedDateIndex == index;
                          var dateData = availableDates[index];
                          
                          return GestureDetector(
                            onTap: () => setState(() => selectedDateIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1A3C34) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? const Color(0xFF1A3C34) : const Color(0xFFEADFCB)),
                              ),
                              child: Column(
                                children: [
                                  Text(dateData['day']!, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(dateData['date']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF1A3C34))),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Color(0xFF1A3C34)),
                      const SizedBox(width: 6),
                      Text('Jadwal tersedia setiap hari ${widget.day}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('JUMLAH TIKET', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.categoryName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34))),
                          const SizedBox(height: 2),
                          Text('${_formatRupiah(widget.basePrice)} / tiket', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEADFCB)), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: ticketCount > 1 ? () => setState(() => ticketCount--) : null,
                            ),
                            Text('$ticketCount', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: ticketCount < maxTickets ? () => setState(() => ticketCount++) : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Maksimal 10 tiket per transaksi.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('METODE PEMBAYARAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1A3C34), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                          child: const Text('QRIS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34))),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('QRIS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34))),
                              Text('Bank dan e-wallet apa saja', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: Color(0xFF1A3C34), size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RINCIAN PEMBAYARAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34))),
                  const SizedBox(height: 12),
                  _buildRincianRow('Tiket ${widget.categoryName} ($ticketCount x ${_formatRupiah(widget.basePrice)})', _formatRupiah(subtotal)),
                  const SizedBox(height: 8),
                  _buildRincianRow('Biaya layanan', _formatRupiah(serviceFee)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFEADFCB))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34))),
                      Text(_formatRupiah(totalBayar), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('TOTAL BAYAR', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(_formatRupiah(totalBayar), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3C34))),
                ],
              ),
              ElevatedButton(
                onPressed: _prosesPemesanan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C34),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  children: [
                    Text('Konfirmasi & Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF0E8D8))),
      child: child,
    );
  }

  Widget _buildRincianRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A3C34))),
      ],
    );
  }
}