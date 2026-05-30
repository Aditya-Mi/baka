import 'package:flutter/material.dart';

/// 8 muted warm tones that complement the app's cream/terracotta palette.
/// Each color is stored as a hex string in the DB.
class TagPalette {
  static const colors = <TagColor>[
    TagColor('terracotta', Color(0xFFC4622D)),
    TagColor('sage',       Color(0xFF8A9E7E)),
    TagColor('dusty_rose', Color(0xFFC08080)),
    TagColor('amber',      Color(0xFFB8860B)),
    TagColor('slate',      Color(0xFF6B7FA3)),
    TagColor('bark',       Color(0xFF8B6914)),
    TagColor('plum',       Color(0xFF9B6B8A)),
    TagColor('moss',       Color(0xFF5F7A5F)),
  ];

  /// Assigns a color deterministically based on tag name.
  static Color forName(String name) {
    final index = name.codeUnits.fold(0, (sum, c) => sum + c) % colors.length;
    return colors[index].color;
  }

  static Color fromHex(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', 'FF'), radix: 16);
    return value != null ? Color(value) : colors[0].color;
  }

  static String toHex(Color color) =>
      '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}

class TagColor {
  final String name;
  final Color color;
  const TagColor(this.name, this.color);
}

class Tag {
  final String name;
  final Color color;

  const Tag({required this.name, required this.color});

  /// Chip background — very subtle tint (12% opacity).
  Color get chipBg => color.withValues(alpha: 0.12);

  /// Chip border — slightly more visible (30% opacity).
  Color get chipBorder => color.withValues(alpha: 0.30);

  factory Tag.fromMap(Map<String, dynamic> map) => Tag(
        name:  map['name'] as String,
        color: TagPalette.fromHex(map['color'] as String),
      );

  Map<String, dynamic> toMap() => {
        'name':  name,
        'color': TagPalette.toHex(color),
      };

  Tag copyWith({Color? color}) => Tag(
        name:  name,
        color: color ?? this.color,
      );
}
