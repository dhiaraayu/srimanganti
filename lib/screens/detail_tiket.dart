import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiket_srimanganti/screens/checkout_screen.dart';

import '../services/supabase_service.dart';
import '../services/currency_service.dart';

enum _Currency { idr, usd, eur, jpy }
enum _Category { wni, wna }

const Map<_Currency, String> _currencyLabel = {
  _Currency.idr: 'IDR (Rp)',
  _Currency.usd: 'USD (\$)',
  _Currency.eur: 'EUR (€)',
  _Currency.jpy: 'JPY (¥)',
};

const Map<_Category, int> _basePriceIdr = {
  _Category.wni: 15000,
  _Category.wna: 25000,
};

String _formatPrice(int idr, _Currency c, Map<String, double> idrRates) {
  if (c == _Currency.idr) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(idr);
  }
  String code = c.name.toUpperCase();
  double rate = idrRates[code] ?? 1.0;
  if (rate == 0) rate = 1.0;
  double finalAmount = idr * rate;

  switch (c) {
    case _Currency.usd:
      return NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2).format(finalAmount);
    case _Currency.eur:
      return NumberFormat.currency(locale: 'en_US', symbol: '€', decimalDigits: 2).format(finalAmount);
    case _Currency.jpy:
      return NumberFormat.currency(locale: 'en_US', symbol: '¥', decimalDigits: 0).format(finalAmount);
    default:
      return '';
  }
}

const _kGreen = Color(0xFF1A3C34);
const _kGold = Color(0xFFB8862B);
const _kGoldSoft = Color(0xFFF6D58E);
const _kBg = Color(0xFFFDF8F0);
const _kBorder = Color(0xFFEADFCB);
const _kMuted = Color(0xFF6B7A75);

class ShowDetailScreen extends StatefulWidget {
  final String title;
  final String day;
  final String image;
  final String description;

  const ShowDetailScreen({
    super.key,
    required this.title,
    required this.day,
    required this.image,
    required this.description,
  });

  @override
  State<ShowDetailScreen> createState() => _ShowDetailScreenState();
}

class _ShowDetailScreenState extends State<ShowDetailScreen> {
  _Currency _currency = _Currency.idr;
  _Category _category = _Category.wni;
  List<Map<String, dynamic>> _ulasanList = [];
  bool _isLoadingUlasan = true;
  String? _teksRingkasanAI;
  bool _isLoadingAI = false;

  Map<String, double> _idrRates = {};
  bool _isLoadingRates = true;

  @override
  void initState() {
    super.initState();
    _loadUlasan();
    _loadRates();
  }

  Future<void> _loadRates() async {
    final rates = await CurrencyService.getRates();
    if (mounted) {
      setState(() {
        _idrRates = rates;
        _isLoadingRates = false;
      });
    }
  }

  Future<void> _loadUlasan() async {
    try {
      final data = await SupabaseService().getUlasan(widget.title);
      if (mounted) {
        setState(() {
          _ulasanList = data;
          _isLoadingUlasan = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUlasan = false);
    }
  }

  Future<void> _muatRingkasanAI() async {
    setState(() => _isLoadingAI = true);
    final hasil = await SupabaseService().generateRingkasanAI(widget.title);
    setState(() {
      _teksRingkasanAI = hasil;
      _isLoadingAI = false;
    });
  }

  String get _categoryName =>
      _category == _Category.wni ? 'WNI Reguler' : 'WNA Foreigner';

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.3,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHero(),
                          const SizedBox(height: 16),
                          _buildDescriptionCard(widget.description),
                          const SizedBox(height: 16),
                          _buildScheduleCard(),
                          const SizedBox(height: 16),
                          _buildTicketCard(),
                          const SizedBox(height: 16),
                          _buildReviewCard(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _kGreen),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Detail Pentas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      height: 220,
      decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.image,
            fit: BoxFit.cover,
            cacheWidth: 1000,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFD9D9D9),
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_outlined, color: Colors.black38),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.2, 1.0],
                colors: [Color(0x330B1F1A), Color(0xE60B1F1A)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGoldSoft.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kGold),
                  ),
                  child: const Text(
                    'Pentas Sakral Keraton',
                    style: TextStyle(color: _kGoldSoft, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, fontFamily: 'serif'),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: _kGoldSoft, size: 14),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Bangsal Srimanganti, Keraton Yogyakarta',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String deskripsi) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentang Pementasan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kGreen),
          ),
          const SizedBox(height: 10),
          Text(
            deskripsi,
            style: const TextStyle(fontSize: 13, height: 1.6, color: _kMuted),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _infoRow({required IconData icon, required Color iconColor, required Color bgColor, required String label, required String value}) {
    return Row(
      children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Color(0xFF9AA6A2))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kGreen)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard() {
    return _card(
      child: Column(
        children: [
          _infoRow(icon: Icons.calendar_month_outlined, iconColor: _kGreen, bgColor: const Color(0xFFE8EFEC), label: 'JADWAL RUTIN', value: 'Setiap ${widget.day}, 09.00 - 11.00 WIB'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF0E8D8))),
          _infoRow(icon: Icons.schedule, iconColor: const Color(0xFFE08A1E), bgColor: const Color(0xFFFFF3E0), label: 'DURASI PEMENTASAN', value: '120 Menit (Tanpa Jeda)'),
        ],
      ),
    );
  }

  Widget _buildTicketCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Kategori & Mata Uang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kGreen)),
          const SizedBox(height: 14),
          _CurrencySelector(selected: _currency, onChanged: (c) => setState(() => _currency = c)),
          const SizedBox(height: 14),

          if (_isLoadingRates)
            const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
          else ...[
            _CategoryTile(
              title: 'WNI (Reguler)',
              price: '${_formatPrice(_basePriceIdr[_Category.wni]!, _currency, _idrRates)} / orang',
              selected: _category == _Category.wni,
              onTap: () => setState(() => _category = _Category.wni),
            ),
            const SizedBox(height: 10),
            _CategoryTile(
              title: 'WNA (Foreigner)',
              price: '${_formatPrice(_basePriceIdr[_Category.wna]!, _currency, _idrRates)} / orang',
              selected: _category == _Category.wna,
              onTap: () => setState(() => _category = _Category.wna),
            ),
          ],

          if (_currency != _Currency.idr && _idrRates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Kurs real-time bersumber dari penyedia kurs publik. Pembayaran tetap dalam Rupiah.',
              style: const TextStyle(fontSize: 11, color: _kMuted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ulasan Penonton', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kGreen)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A3C34).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: _kGreen, size: 16),
                    SizedBox(width: 6),
                    Text('Ringkasan AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kGreen)),
                  ],
                ),
                const SizedBox(height: 8),
                _teksRingkasanAI == null
                    ? SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoadingAI ? null : _muatRingkasanAI,
                          style: OutlinedButton.styleFrom(foregroundColor: _kGreen, side: const BorderSide(color: _kGreen)),
                          child: _isLoadingAI
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Buat Ringkasan dari Ulasan', style: TextStyle(fontSize: 12)),
                        ),
                      )
                    : Text(_teksRingkasanAI!, style: const TextStyle(fontSize: 12, color: _kGreen, height: 1.5, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          if (_isLoadingUlasan)
            const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
          else if (_ulasanList.isEmpty)
            const Text('Belum ada ulasan untuk pentas ini. Jadilah yang pertama!', style: TextStyle(fontSize: 12.5, color: _kMuted, fontStyle: FontStyle.italic))
          else
            ..._ulasanList.map((ulasan) {
              final rating = ulasan['rating'] ?? 0;
              final teks = ulasan['teks_ulasan'] ?? '';
              final email = ulasan['user_email'] ?? 'Pengguna';
              final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';
              final tanggal = ulasan['created_at'] != null
                  ? DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(ulasan['created_at']))
                  : '-';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEF1F4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: const Color(0xFFC9D6E0), child: Text(initial, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(email, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kGreen), overflow: TextOverflow.ellipsis),
                              Text(tanggal, style: const TextStyle(fontSize: 10, color: Color(0xFF9AA6A2))),
                            ],
                          ),
                        ),
                        Row(children: List.generate(5, (index) => Icon(index < rating ? Icons.star : Icons.star_border, color: const Color(0xFFF5A623), size: 14))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('"$teks"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: _kGreen)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('KATEGORI DIPILIH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF9AA6A2))),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(_categoryName, key: ValueKey(_categoryName), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kGreen)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              int hargaTiket = _basePriceIdr[_category]!;
              String namaKategori = _category == _Category.wni ? 'WNI Reguler' : 'WNA Foreigner';
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => CheckoutScreen(
                    title: widget.title, 
                    basePrice: hargaTiket, 
                    categoryName: namaKategori,
                    imageAsset: widget.image,
                    day: widget.day, // <-- TAMBAHAN UNTUK GAMBAR
                  )
                )
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pesan Tiket', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final _Currency selected;
  final ValueChanged<_Currency> onChanged;

  const _CurrencySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const values = _Currency.values;
    final index = values.indexOf(selected);

    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F6), borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segW = constraints.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: segW * index,
                top: 0,
                bottom: 0,
                width: segW,
                child: Container(decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(10))),
              ),
              Row(
                children: values.map((c) {
                  final isSel = c == selected;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(c),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSel ? Colors.white : _kMuted),
                            child: Text(_currencyLabel[c]!),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({required this.title, required this.price, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 250);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _kGreen : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _kGreen : const Color(0xFFE3E8EC)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? Colors.white : _kGreen),
                    child: Text(title),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: TextStyle(fontSize: 12, color: selected ? const Color(0xFFCFE0DA) : _kMuted),
                    child: Text(price),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: duration,
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? _kGoldSoft : const Color(0xFFCBD3D8), width: 2),
              ),
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: duration,
                curve: Curves.easeOutBack,
                child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: _kGoldSoft)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}