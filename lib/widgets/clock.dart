import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorldClockStrip extends StatefulWidget {
  const WorldClockStrip({super.key});

  @override
  State<WorldClockStrip> createState() => _WorldClockStripState();
}

class _WorldClockStripState extends State<WorldClockStrip> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  static const _zones = [
    {'label': 'WIB', 'tz': 'WIB', 'home': true},
    {'label': 'WITA', 'tz': 'WITA', 'home': false},
    {'label': 'WIT', 'tz': 'WIT', 'home': false},
    {'label': 'LONDON', 'tz': 'LONDON', 'home': false},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  DateTime _getTimeForZone(String tz) {
    if (tz == 'WIB') return _now.toUtc().add(const Duration(hours: 7));
    if (tz == 'WITA') return _now.toUtc().add(const Duration(hours: 8));
    if (tz == 'WIT') return _now.toUtc().add(const Duration(hours: 9));

    final y = _now.year;
    final start = DateTime.utc(y, 3, 31)
        .subtract(Duration(days: DateTime.utc(y, 3, 31).weekday % 7))
        .add(const Duration(hours: 1));
    final end = DateTime.utc(y, 10, 31)
        .subtract(Duration(days: DateTime.utc(y, 10, 31).weekday % 7))
        .add(const Duration(hours: 1));
    final isBST = _now.toUtc().isAfter(start) && _now.toUtc().isBefore(end);

    return _now.toUtc().add(Duration(hours: isBST ? 1 : 0));
  }

  String _offsetLabel(String tz) {
    if (tz == 'WIB') return 'UTC+7';
    if (tz == 'WITA') return 'UTC+8';
    if (tz == 'WIT') return 'UTC+9';
    final isBST = _getTimeForZone('LONDON').hour != _now.toUtc().hour;
    return isBST ? 'UTC+1' : 'UTC+0';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADFCB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_zones.length, (i) {
          final z = _zones[i];
          final isHome = z['home'] as bool;
          final timeStr = _timeFormat.format(
            _getTimeForZone(z['tz'] as String),
          );

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(left: BorderSide(color: Color(0xFFF0E8D8))),
              ),
              child: Column(
                children: [
                  Text(
                    z['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isHome
                          ? const Color(0xFFB8862B)
                          : const Color(0xFF6B7A75),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isHome
                          ? const Color(0xFF1A3C34)
                          : const Color(0xFF1A3C34),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _offsetLabel(z['tz'] as String),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF9AA6A2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
