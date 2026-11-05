import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';

/// A lightweight, robust Markdown widget tailored for AI chat bubbles.
/// - Formats headings, bold, italics, bullets, numbered lists, and inline code.
/// - Avoids oversized headers and excessive paragraph gaps.
/// - Resilient to incomplete tokens during live streaming.
class ChatMarkdownWidget extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final Color? defaultTextColor;
  final bool isUser;

  const ChatMarkdownWidget({
    super.key,
    required this.text,
    this.baseStyle,
    this.defaultTextColor,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final textColor = defaultTextColor ?? (isUser ? Colors.white : AppColors.textPrimary);
    final effectiveBaseStyle = baseStyle ??
        AppTypography.bodyMedium.copyWith(
          color: textColor,
          fontSize: 13.5,
          height: 1.45,
        );

    final lines = text.split('\n');
    final List<Widget> widgets = [];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trimRight();

      if (line.trim().isEmpty) {
        // Small paragraph separation
        if (widgets.isNotEmpty && i + 1 < lines.length && lines[i + 1].trim().isNotEmpty) {
          widgets.add(const SizedBox(height: 6));
        }
        i++;
        continue;
      }

      // 1. Heading check: ### or ## or #
      if (line.startsWith('### ')) {
        widgets.add(_buildHeading(line.substring(4).trim(), 13.5, textColor));
        i++;
        continue;
      } else if (line.startsWith('## ')) {
        widgets.add(_buildHeading(line.substring(3).trim(), 14.0, textColor));
        i++;
        continue;
      } else if (line.startsWith('# ')) {
        widgets.add(_buildHeading(line.substring(2).trim(), 14.5, textColor));
        i++;
        continue;
      }

      // 2. Bullet list check: - or * or •
      final isBullet = line.startsWith('- ') || line.startsWith('* ') || line.startsWith('• ');
      if (isBullet) {
        final content = line.substring(2).trim();
        widgets.add(_buildBulletItem(content, effectiveBaseStyle, textColor));
        i++;
        continue;
      }

      // 3. Numbered list check: e.g. 1. or 2.
      final numberMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
      if (numberMatch != null) {
        final numStr = numberMatch.group(1)!;
        final content = numberMatch.group(2)!.trim();
        widgets.add(_buildNumberedItem(numStr, content, effectiveBaseStyle, textColor));
        i++;
        continue;
      }

      // 4. Regular Paragraph line
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(
            text: TextSpan(
              children: _parseInlineSpans(line, effectiveBaseStyle, textColor),
            ),
          ),
        ),
      );

      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _buildHeading(String headingText, double fontSize, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: fontSize + 1,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isUser ? Colors.white70 : AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              _cleanDanglingMarkdown(headingText),
              style: AppTypography.bodyMedium.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String content, TextStyle baseStyle, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isUser ? Colors.white : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: _parseInlineSpans(content, baseStyle, textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedItem(String numStr, String content, TextStyle baseStyle, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$numStr.',
              style: baseStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: isUser ? Colors.white70 : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: _parseInlineSpans(content, baseStyle, textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parses inline markdown elements (**bold**, *italic*, `code`, and unclosed streaming tokens).
  List<InlineSpan> _parseInlineSpans(String text, TextStyle baseStyle, Color textColor) {
    final List<InlineSpan> spans = [];
    final cleaned = _cleanDanglingMarkdown(text);

    // Pattern matches **bold**, *italic*, and `code`
    final pattern = RegExp(r'(\*\*(.*?)\*\*|\*(.*?)\*|`(.*?)`)');
    int lastIndex = 0;

    for (final match in pattern.allMatches(cleaned)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: cleaned.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final fullMatch = match.group(0)!;
      if (fullMatch.startsWith('**') && fullMatch.endsWith('**')) {
        final inner = match.group(2) ?? '';
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ));
      } else if (fullMatch.startsWith('*') && fullMatch.endsWith('*')) {
        final inner = match.group(3) ?? '';
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (fullMatch.startsWith('`') && fullMatch.endsWith('`')) {
        final inner = match.group(4) ?? '';
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isUser ? Colors.black12 : AppColors.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              inner,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! * 0.9 : 12,
                color: isUser ? Colors.white : AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < cleaned.length) {
      spans.add(TextSpan(
        text: cleaned.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }

  /// Handles streaming partial tokens gracefully.
  /// If the text ends with an unclosed '**' or '*' or '`', strips or closes it for smooth rendering.
  String _cleanDanglingMarkdown(String raw) {
    String s = raw;
    // If odd number of '**', complete it temporarily for parsing
    final boldCount = '**'.allMatches(s).length;
    if (boldCount % 2 != 0) {
      s = '$s**';
    } else {
      // Check single '*'
      final singleStarCount = RegExp(r'(?<!\*)\*(?!\*)').allMatches(s).length;
      if (singleStarCount % 2 != 0) {
        s = '$s*';
      }
    }
    final backtickCount = '`'.allMatches(s).length;
    if (backtickCount % 2 != 0) {
      s = '$s`';
    }
    return s;
  }
}

