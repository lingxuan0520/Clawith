import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
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
    return MarkdownBody(
      data: data,
      selectable: selectable,
      shrinkWrap: shrinkWrap,
      styleSheet: _buildStyleSheet(context),
      onTapLink: (text, href, title) => _launchUrl(href),
      builders: {
        'code': _CodeBlockBuilder(),
      },
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      p: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6),
      h1: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      h2: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      h3: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      code: TextStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        backgroundColor: AppColors.bgTertiary,
        color: AppColors.textPrimary,
      ),
      codeblockDecoration: const BoxDecoration(),
      codeblockPadding: EdgeInsets.zero,
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.accentPrimary, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12),
      a: const TextStyle(color: AppColors.accentPrimary, decoration: TextDecoration.underline),
      listBullet: TextStyle(color: AppColors.textSecondary),
      tableHead: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      tableBody: TextStyle(color: AppColors.textSecondary),
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

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    // Only handle fenced code blocks (multi-line), not inline code
    if (element.tag != 'code') return null;
    final parent = element.attributes['class'];
    // Inline code has no language class and is within a <p> tag
    // Check if this looks like a code block (has language or contains newlines)
    final text = element.textContent;
    final isBlock = parent != null || text.contains('\n');
    if (!isBlock) return null;

    final language = parent?.replaceFirst('language-', '') ?? '';

    return _CodeBlockWidget(code: text, language: language);
  }
}

class _CodeBlockWidget extends StatefulWidget {
  final String code;
  final String language;
  const _CodeBlockWidget({required this.code, required this.language});

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language label and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                if (widget.language.isNotEmpty)
                  Text(
                    widget.language,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      fontFamily: 'monospace',
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: _copy,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied ? Icons.check : Icons.copy,
                        size: 14,
                        color: _copied ? Colors.green : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? l.markdownCopied : l.markdownCopy,
                        style: TextStyle(
                          fontSize: 12,
                          color: _copied ? Colors.green : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Code content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              widget.code,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
