import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';

/// Markdown renderer widget matching the React frontend's markdown display.
class MarkdownRenderer extends StatelessWidget {
  final String data;
  final bool selectable;
  final bool shrinkWrap;

  const MarkdownRenderer({
    super.key,
    required this.data,
    this.selectable = true,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (selectable) {
      return MarkdownBody(
        data: data,
        selectable: true,
        shrinkWrap: shrinkWrap,
        styleSheet: _buildStyleSheet(context),
        onTapLink: (text, href, title) => _launchUrl(href),
      );
    }

    return MarkdownBody(
      data: data,
      shrinkWrap: shrinkWrap,
      styleSheet: _buildStyleSheet(context),
      onTapLink: (text, href, title) => _launchUrl(href),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      p: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6),
      h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      code: TextStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        backgroundColor: AppColors.bgTertiary,
        color: AppColors.textPrimary,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.accentPrimary, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12),
      a: const TextStyle(color: AppColors.accentPrimary, decoration: TextDecoration.underline),
      listBullet: const TextStyle(color: AppColors.textSecondary),
      tableHead: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      tableBody: const TextStyle(color: AppColors.textSecondary),
      tableBorder: TableBorder.all(color: AppColors.borderSubtle, width: 0.5),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
    );
  }

  void _launchUrl(String? href) {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
