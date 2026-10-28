import 'package:flutter/material.dart';
import 'package:tiket_srimanganti/screens/e_ticket_screen.dart';
import 'package:intl/intl.dart';

import 'dart:async';

import '../models/ticket_model.dart';
import 'review_screen.dart';
import '../services/db_helper.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedFilter = 'Semua';
  String searchQuery = '';
  bool isSearchActive = false;
  final TextEditingController searchController = TextEditingController();

  List<TicketModel> allTickets = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTiketDariDatabase();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTiketDariDatabase() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final email = await DBHelper().getSesi();
      if (email != null && email.isNotEmpty) {
        final data = await SupabaseService()
            .getHistoryTiket(email)
            .timeout(const Duration(seconds: 10));

        final parsed = data.map((item) {
          String tglFormatted = '-';
          if (item['tanggal_kunjungan'] != null) {
            try {
              DateTime parsedDate = DateTime.parse(
                item['tanggal_kunjungan'].toString(),
              );
              tglFormatted = DateFormat(
                'EEEE, dd MMM yyyy',
                'id_ID',
              ).format(parsedDate);
            } catch (e) {
              tglFormatted = item['tanggal_kunjungan'].toString();
            }
          }

          String tiketId = item['id']?.toString() ?? '';
          String rawKode = item['kode_booking']?.toString() ?? '-';
          String kodeBookingAsli = rawKode.contains('|')
              ? rawKode.split('|')[0]
              : rawKode;
          String statusRaw = (item['status']?.toString() ?? 'Aktif').trim();
          bool isSelesai = statusRaw.toLowerCase() == 'selesai';
          String deskripsi =
              item['deskripsi']?.toString() ??
              'Saksikan keindahan seni ${item['judul_pagelaran'] ?? 'budaya'} klasik gaya Yogyakarta.';

          // Ambil jumlah tiket dari database
          final jumlahRaw = item['jumlah_tiket'];
          final jumlahTiket = (jumlahRaw is int)
              ? jumlahRaw
              : int.tryParse('${jumlahRaw ?? 1}') ?? 1;

          return TicketModel(
            id: tiketId,
            location: 'Bangsal Srimanganti',
            status: statusRaw,
            isCompleted: isSelesai,
            title: item['judul_pagelaran']?.toString() ?? 'Pagelaran Keraton',
            subtitle: 'Kunjungan: $tglFormatted',
            detail: '$jumlahTiket tiket',
            bookingCode: kodeBookingAsli,
            imageAsset: '',
            iconBgColor: const Color(0xFF0B3D2E),
            description: deskripsi,
            ticketCount: jumlahTiket, // <-- Masukin jumlah tiket ke model
          );
        }).toList();

        if (!mounted) return;
        setState(() {
          allTickets = parsed;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage = "Sesi login tidak ditemukan.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Gagal memuat data: $e";
      });
    }
  }

  Future<void> _batalkanTiket(TicketModel ticket) async {
    if (ticket.id.isEmpty || ticket.id == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiket ini tidak punya ID valid.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Batalkan Tiket?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Apakah Anda yakin ingin membatalkan tiket ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  await SupabaseService()
                      .updateStatusTiket(ticket.id, 'Dibatalkan')
                      .timeout(const Duration(seconds: 5));
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadTiketDariDatabase();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tiket berhasil dibatalkan.'),
                      backgroundColor: Color(0xFF0B3D2E),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadTiketDariDatabase();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal membatalkan: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );
  }

  void _bukaPengingat(TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool cek1H = false, cek2J = false, cek10D = false;
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Atur Pengingat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: const Text('1 Hari Sebelum'),
                    value: cek1H,
                    onChanged: (val) =>
                        setStateSheet(() => cek1H = val ?? false),
                    activeColor: const Color(0xFF0B3D2E),
                  ),
                  CheckboxListTile(
                    title: const Text('2 Jam Sebelum'),
                    value: cek2J,
                    onChanged: (val) =>
                        setStateSheet(() => cek2J = val ?? false),
                    activeColor: const Color(0xFF0B3D2E),
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Tes Notifikasi (10 Detik)',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: cek10D,
                    onChanged: (val) =>
                        setStateSheet(() => cek10D = val ?? false),
                    activeColor: const Color(0xFFD4AF37),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        int baseId = ticket.id.hashCode.abs();
                        if (cek1H)
                          await NotificationService.scheduleNotificationInDays(
                            id: baseId + 1,
                            title: 'SRIMANGANTI',
                            body: 'Pementasan ${ticket.title} besok!',
                            days: 1,
                          );
                        if (cek2J)
                          await NotificationService.scheduleNotificationInHours(
                            id: baseId + 2,
                            title: 'SRIMANGANTI',
                            body: 'Pementasan ${ticket.title} 2 jam lagi!',
                            hours: 2,
                          );
                        if (cek10D)
                          await NotificationService.scheduleNotificationInSeconds(
                            id: baseId + 3,
                            title: 'SRIMANGANTI',
                            body: 'Tes Notifikasi 10 detik!',
                            seconds: 10,
                          );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pengingat disimpan!'),
                            backgroundColor: Color(0xFF0B3D2E),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3D2E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan & Aktifkan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<TicketModel> get filteredTickets {
    return allTickets.where((ticket) {
      final statusLower = ticket.status.toLowerCase().trim();
      bool matchStatus = true;
      if (selectedFilter == 'Akan Datang')
        matchStatus = !ticket.isCompleted && statusLower != 'dibatalkan';
      else if (selectedFilter == 'Selesai')
        matchStatus = ticket.isCompleted;
      else if (selectedFilter == 'Dibatalkan')
        matchStatus = statusLower == 'dibatalkan';
      final matchSearch = ticket.title.toLowerCase().contains(
        searchQuery.toLowerCase().trim(),
      );
      return matchStatus && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tiket Saya',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B3D2E),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          isSearchActive = !isSearchActive;
                          if (!isSearchActive) {
                            searchQuery = '';
                            searchController.clear();
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isSearchActive) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Cari nama pentas...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua'),
                        _buildFilterChip(
                          'Akan Datang',
                          badgeCount: allTickets
                              .where(
                                (t) =>
                                    !t.isCompleted &&
                                    t.status.toLowerCase() != 'dibatalkan',
                              )
                              .length
                              .toString(),
                        ),
                        _buildFilterChip('Selesai'),
                        _buildFilterChip('Dibatalkan'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTiketDariDatabase,
                color: const Color(0xFF0B3D2E),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0B3D2E),
                        ),
                      )
                    : errorMessage != null
                    ? ListView(
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      )
                    : filteredTickets.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Text(
                              'Belum ada tiket.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          24.0,
                          0,
                          24.0,
                          120.0,
                        ),
                        itemCount: filteredTickets.length,
                        itemBuilder: (context, index) =>
                            _buildTicketCard(filteredTickets[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {String? badgeCount}) {
    bool isActive = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0B3D2E) : const Color(0xFFE6D5B8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF666666),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            if (badgeCount != null && badgeCount != '0') ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : const Color(0xFF0B3D2E),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount,
                  style: TextStyle(
                    color: isActive ? const Color(0xFF0B3D2E) : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    bool isCancelled = ticket.status.toLowerCase() == 'dibatalkan';
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isCancelled ? const Color(0xFFF5F5F5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.location,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? const Color(0xFFFADBD8)
                          : ticket.isCompleted
                          ? const Color(0xFFEBEBEB)
                          : const Color(0xFFE3F0E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCancelled
                            ? const Color(0xFFC0392B)
                            : ticket.isCompleted
                            ? Colors.black54
                            : const Color(0xFF1E5631),
                      ),
                    ),
                  ),
                  if (!isCancelled && !ticket.isCompleted) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _bukaPengingat(ticket),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: isCancelled ? Colors.grey : ticket.iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.theater_comedy,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCancelled
                            ? Colors.grey
                            : const Color(0xFF0B3D2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.detail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF0F0F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KODE BOOKING',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      ticket.bookingCode,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B3D2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isCancelled) ...[
                if (!ticket.isCompleted)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => _batalkanTiket(ticket),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC0392B),
                          side: const BorderSide(color: Color(0xFFC0392B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Batalkan',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          String gambarPath = 'assets/uyon_uyon_selasa.webp';
                          if (ticket.title.contains('Wayang Golek'))
                            gambarPath = 'assets/wayang_golek_rabu.webp';
                          else if (ticket.title.contains('Wayang Kulit'))
                            gambarPath = 'assets/wayang_kulit_kamis.webp';
                          else if (ticket.title.contains('Macapat'))
                            gambarPath = 'assets/macapat_jumat.webp';
                          else if (ticket.title.contains('Fragmen'))
                            gambarPath =
                                'assets/fragmen_wayang_wong_sabtu.webp';
                          else if (ticket.title.contains('Gladhen'))
                            gambarPath = 'assets/gladhen_beksan_minggu.webp';

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ETicketScreen(
                                title: ticket.title,
                                date: ticket.subtitle.replaceAll(
                                  'Kunjungan: ',
                                  '',
                                ),
                                time: '09:00 - 11:00',
                                kodeBooking: ticket.bookingCode, // <-- Kirim kode booking induk
                                ticketCount: ticket
                                    .ticketCount, // <-- Kirim jumlah tiketnya
                                imageAsset: gambarPath,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Lihat E-Tiket',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReviewScreen(ticketTitle: ticket.title),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0B3D2E),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Beri Ulasan',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
              ] else ...[
                const Text(
                  'Tiket telah dibatalkan',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
