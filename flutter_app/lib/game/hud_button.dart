import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const HudButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
