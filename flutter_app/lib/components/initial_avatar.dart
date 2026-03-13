import 'package:flutter/material.dart';

/// Colored circle avatar showing the first character of [name].
/// Used as fallback when user has no profile photo (e.g. Apple Sign-In).
class InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;
  final double borderRadius;

  const InitialAvatar({
    super.key,
    required this.name,
    this.size = 32,
    this.fontSize = 14,
    this.borderRadius = 8,
  });

  static const _colors = [
    Color(0xFF6366F1), // indigo
    Color(0xFF8B5CF6), // violet
    Color(0xFFEC4899), // pink
    Color(0xFFF43F5E), // rose
    Color(0xFFF97316), // orange
    Color(0xFFEAB308), // yellow
    Color(0xFF22C55E), // green
    Color(0xFF14B8A6), // teal
    Color(0xFF06B6D4), // cyan
    Color(0xFF3B82F6), // blue
  ];

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colorIndex = name.isEmpty ? 0 : name.codeUnits.fold(0, (sum, c) => sum + c) % _colors.length;
    final bgColor = _colors[colorIndex];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: bgColor,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
