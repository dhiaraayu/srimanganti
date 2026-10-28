import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tiket_srimanganti/screens/e_ticket_screen.dart';

const String kJudul = 'judul_pagelaran';
const String kTanggal = 'tanggal_kunjungan';
const String kJumlah = 'jumlah_tiket';
const String kKode = 'kode_booking'; 
const String kStatus = 'status';

const Set<String> kStatusMati = {'dibatalkan', 'selesai'};
const Color _hijau = Color(0xFF0B3D2E);
const Color _krem = Color(0xFFFDF8F0);

class ShakeDetector {
  ShakeDetector({required this.onShake, this.thresholdG = 2.7, this.cooldown = const Duration(seconds: 2)});

  final VoidCallback onShake;
  final double thresholdG; 
  final Duration cooldown;

  StreamSubscription<AccelerometerEvent>? _sub;
  int _spikes = 0;
  DateTime? _windowStart;
  DateTime? _lastShake;

  void start() {
    _sub ??= accelerometerEventStream().listen((e) {
      final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.80665;
      if (g < thresholdG) return;
      final now = DateTime.now();
      if (_windowStart == null || now.difference(_windowStart!) > const Duration(milliseconds: 700)) { _windowStart = now; _spikes = 0; }
      _spikes++;
      if (_spikes >= 2 && (_lastShake == null || now.difference(_lastShake!) > cooldown)) { _lastShake = now; _spikes = 0; onShake(); }
    });
  }
  void dispose() { _sub?.cancel(); _sub = null; }
}

class ShakeTicketHandler {
  ShakeTicketHandler({required this.getContext, required this.loadTiket}) {
    _detector = ShakeDetector(onShake: _handleShake);
  }

  final BuildContext Function() getContext;
  final Future<List<Map<String, dynamic>>> Function() loadTiket;
  late final ShakeDetector _detector;
  bool _busy = false;

  void start() => _detector.start();
  void dispose() => _detector.dispose();

  Future<void> _handleShake() async {
    if (_busy) return;
    _busy = true;
    try {
      HapticFeedback.mediumImpact();
      final semua = await loadTiket();
      final tiket = _filterAkanDatang(semua);
      final ctx = getContext();
      if (!ctx.mounted) return;

      if (tiket.isEmpty) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Belum ada tiket yang akan datang.')));
        return;
      }

      if (tiket.length == 1) {
        await Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => _buatETicket(tiket.first)));
        return;
      }

      await showModalBottomSheet<void>(
        context: ctx, isScrollControlled: true, backgroundColor: _krem,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _PilihTiketSheet(tiket: tiket),
      );
    } catch (e) {
      final ctx = getContext();
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Gagal memuat tiket. Coba lagi.')));
    } finally {
      _busy = false;
    }
  }
}

DateTime? _tgl(Map<String, dynamic> t) {
  final v = t[kTanggal];
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

DateTime _hanyaTanggal(DateTime d) => DateTime(d.year, d.month, d.day);

List<Map<String, dynamic>> _filterAkanDatang(List<Map<String, dynamic>> semua) {
  final hariIni = _hanyaTanggal(DateTime.now());
  final hasil = semua.where((t) {
    final d = _tgl(t);
    if (d == null) return false;
    final status = (t[kStatus] ?? 'Aktif').toString().trim().toLowerCase();
    if (kStatusMati.contains(status)) return false;
    return !_hanyaTanggal(d).isBefore(hariIni);
  }).toList();
  hasil.sort((a, b) => _tgl(a)!.compareTo(_tgl(b)!));
  return hasil;
}

Widget _buatETicket(Map<String, dynamic> t) {
  final judul = t[kJudul]?.toString() ?? 'Pagelaran Keraton';
  String tanggal = '-';
  final d = _tgl(t);
  if (d != null) {
    tanggal = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(d);
  } else if (t[kTanggal] != null) {
    tanggal = t[kTanggal].toString();
  }

  final rawKode = t[kKode]?.toString() ?? '-';
  final kode = rawKode.contains('|') ? rawKode.split('|')[0] : rawKode;

  final jumlahRaw = t[kJumlah];
  final jumlahTiket = (jumlahRaw is int) ? jumlahRaw : int.tryParse('${jumlahRaw ?? 1}') ?? 1;

  String gambarPath = 'assets/uyon_uyon_selasa.webp';
  if (judul.contains('Wayang Golek')) gambarPath = 'assets/wayang_golek_rabu.webp';
  else if (judul.contains('Wayang Kulit')) gambarPath = 'assets/wayang_kulit_kamis.webp';
  else if (judul.contains('Macapat')) gambarPath = 'assets/macapat_jumat.webp';
  else if (judul.contains('Fragmen')) gambarPath = 'assets/fragmen_wayang_wong_sabtu.webp';
  else if (judul.contains('Gladhen')) gambarPath = 'assets/gladhen_beksan_minggu.webp';

  return ETicketScreen(
    title: judul,
    date: tanggal,
    time: '09:00 - 11:00',
    kodeBooking: kode, // <-- Kirim kode booking
    ticketCount: jumlahTiket, // <-- Kirim jumlah tiket
    imageAsset: gambarPath,
  );
}

class _PilihTiketSheet extends StatelessWidget {
  const _PilihTiketSheet({required this.tiket});
  final List<Map<String, dynamic>> tiket;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, dd MMM yyyy', 'id_ID');
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 4), child: Align(alignment: Alignment.centerLeft, child: Text('Pilih tiket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true, padding: const EdgeInsets.all(16), itemCount: tiket.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = tiket[i];
                  final d = _tgl(t)!;
                  final jumlahRaw = t[kJumlah];
                  final jumlahTiket = (jumlahRaw is int) ? jumlahRaw : int.tryParse('${jumlahRaw ?? 1}') ?? 1;

                  return Material(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () { final nav = Navigator.of(context); nav.pop(); nav.push(MaterialPageRoute(builder: (_) => _buatETicket(t))); },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.confirmation_number_rounded, color: _hijau),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${t[kJudul] ?? 'Tiket'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('${fmt.format(d)} • $jumlahTiket tiket', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}