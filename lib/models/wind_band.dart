import 'package:flutter/material.dart';

class WindBand {
  final double min;
  final double max;
  final String label;
  final Color color;

  const WindBand({
    required this.min,
    required this.max,
    required this.label,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
    'label': label,
    'color': color.value,
  };

  factory WindBand.fromJson(Map<String, dynamic> json) => WindBand(
    min: (json['min'] as num).toDouble(),
    max: (json['max'] as num).toDouble(),
    label: json['label'] as String,
    color: Color(json['color'] as int),
  );

  WindBand copyWith({
    double? min,
    double? max,
    String? label,
    Color? color,
  }) {
    return WindBand(
      min: min ?? this.min,
      max: max ?? this.max,
      label: label ?? this.label,
      color: color ?? this.color,
    );
  }
}
