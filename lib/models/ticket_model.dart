import 'package:flutter/material.dart';

class TicketModel {
  final String id;
  final String location;
  final String status;
  final bool isCompleted;
  final String title;
  final String subtitle;
  final String detail;
  final String bookingCode;
  final String imageAsset;
  final Color iconBgColor;
  final String description;
  final int ticketCount; // <-- TAMBAHAN

  TicketModel({
    required this.id,
    required this.location,
    required this.status,
    required this.isCompleted,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.bookingCode,
    required this.imageAsset,
    required this.iconBgColor,
    required this.description,
    this.ticketCount = 1, // <-- default 1
  });
}