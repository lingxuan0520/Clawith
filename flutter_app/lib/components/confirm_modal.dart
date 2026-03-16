import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Shows a confirmation dialog. Returns true if confirmed, false/null otherwise.
Future<bool?> showConfirmModal(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Color? confirmColor,
  bool isDangerous = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: message != null
          ? Text(message, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel, style: TextStyle(color: AppColors.textTertiary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDangerous
                ? AppColors.error
                : (confirmColor ?? AppColors.accentPrimary),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
