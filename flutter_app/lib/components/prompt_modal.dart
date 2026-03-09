import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Shows a dialog with a text input field. Returns the entered text or null.
Future<String?> showPromptModal(
  BuildContext context, {
  required String title,
  String? message,
  String? initialValue,
  String hintText = '',
  String confirmLabel = 'OK',
  String cancelLabel = 'Cancel',
  int maxLines = 1,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[
            Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: controller,
            maxLines: maxLines,
            autofocus: true,
            decoration: InputDecoration(hintText: hintText),
            onSubmitted: maxLines == 1 ? (_) => Navigator.of(context).pop(controller.text) : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(cancelLabel, style: const TextStyle(color: AppColors.textTertiary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
