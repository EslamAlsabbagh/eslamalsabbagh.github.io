import 'package:flutter/material.dart';

class ShiftTemplateModel {
  final int? id;
  final int managerId;
  final String name;
  final double customStart;
  final double customEnd;
  final int useCount;
  final DateTime? createdAt;

  const ShiftTemplateModel({
    this.id,
    required this.managerId,
    required this.name,
    required this.customStart,
    required this.customEnd,
    this.useCount = 0,
    this.createdAt,
  });

  /// Color derived from start hour: 0–11:59 blue, 12–17:59 teal, 18–23:59 purple
  Color get color {
    if (customStart < 12) return const Color(0xFF1E88E5);
    if (customStart < 18) return const Color(0xFF26A69A);
    return const Color(0xFF7E57C2);
  }

  Color get lightColor {
    if (customStart < 12) return const Color(0xFFE3F2FD);
    if (customStart < 18) return const Color(0xFFE0F2F1);
    return const Color(0xFFEDE7F6);
  }

  /// Human-readable time range, e.g. "08:00 – 16:00"
  String get timeLabel {
    return '${_fmtHour(customStart)} – ${_fmtHour(customEnd)}';
  }

  double get hours => customEnd > customStart
      ? customEnd - customStart
      : (customEnd + 24) - customStart;

  static String _fmtHour(double h) {
    final hh = h.floor() % 24;
    final mm = ((h - h.floor()) * 60).round();
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  factory ShiftTemplateModel.fromJson(Map<String, dynamic> json) {
    return ShiftTemplateModel(
      id: json['id'] as int?,
      managerId: json['manager_id'] as int,
      name: json['name'] as String,
      customStart: (json['custom_start'] as num).toDouble(),
      customEnd: (json['custom_end'] as num).toDouble(),
      useCount: (json['use_count'] as int?) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'manager_id': managerId,
        'name': name,
        'custom_start': customStart,
        'custom_end': customEnd,
        'use_count': useCount,
      };

  ShiftTemplateModel copyWith({
    int? id,
    int? managerId,
    String? name,
    double? customStart,
    double? customEnd,
    int? useCount,
    DateTime? createdAt,
  }) {
    return ShiftTemplateModel(
      id: id ?? this.id,
      managerId: managerId ?? this.managerId,
      name: name ?? this.name,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
