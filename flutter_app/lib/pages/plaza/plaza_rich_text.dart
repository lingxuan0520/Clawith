import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

/// Renders plaza post/comment text with bold (**text**), inline code (`code`),
/// clickable URLs, and highlighted #hashtags — matching the React renderContent logic.
class PlazaRichText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const PlazaRichText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final baseStyle = (style ?? const TextStyle(fontSize: 13, height: 1.65))
        .copyWith(color: style?.color ?? AppColors.textPrimary);
    final spans = _buildSpans(text, baseStyle);
    return RichText(text: TextSpan(children: spans, style: baseStyle));
  }

  List<InlineSpan> _buildSpans(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    for (int li = 0; li < lines.length; li++) {
      spans.addAll(_parseLine(lines[li], base));
      if (li < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }

  List<InlineSpan> _parseLine(String line, TextStyle base) {
    final spans = <InlineSpan>[];
    // Split on **bold**, `code`, URLs, and #hashtags
    final pattern = RegExp(
        r'\*\*[^*]+\*\*|`[^`]+`|https?://[^\s<>"()，。！？、；：]+|#[\w\u4e00-\u9fff]+');
    int last = 0;
    for (final match in pattern.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(text: line.substring(last, match.start)));
      }
      final part = match.group(0)!;
      if (part.startsWith('**') && part.endsWith('**')) {
        spans.add(TextSpan(
          text: part.substring(2, part.length - 2),
          style: base.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (part.startsWith('`') && part.endsWith('`')) {
        spans.add(TextSpan(
          text: part.substring(1, part.length - 1),
          style: base.copyWith(
            fontFamily: 'monospace',
            fontSize: (base.fontSize ?? 13) - 1,
            backgroundColor: AppColors.bgTertiary,
          ),
        ));
      } else if (part.startsWith('#')) {
        spans.add(TextSpan(
          text: part,
          style: base.copyWith(color: AppColors.accentPrimary, fontWeight: FontWeight.w500),
        ));
      } else {
        // URL
        final display = part.length > 60 ? '${part.substring(0, 57)}...' : part;
        spans.add(TextSpan(
          text: display,
          style: base.copyWith(color: AppColors.accentPrimary),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.tryParse(part);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ));
      }
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last)));
    }
    return spans;
  }
}
