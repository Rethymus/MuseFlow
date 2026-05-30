import 'package:flutter/material.dart';
import '../../models/user_preference.dart';

/// 语言风格指示器
/// 显示用户学习到的语言风格偏好
class LanguageStyleIndicator extends StatelessWidget {
  final LanguageStyle languageStyle;
  final DetailLevel detailLevel;
  final ParagraphStructure paragraphStructure;
  final SentenceComplexity sentenceComplexity;

  const LanguageStyleIndicator({
    Key? key,
    required this.languageStyle,
    required this.detailLevel,
    required this.paragraphStructure,
    required this.sentenceComplexity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIndicator(
          context,
          '语言风格',
          _getLanguageStyleIcon(),
          _getLanguageStyleText(),
          _getLanguageStyleColor(),
        ),
        const SizedBox(height: 12),
        _buildIndicator(
          context,
          '详细程度',
          _getDetailLevelIcon(),
          _getDetailLevelText(),
          _getDetailLevelColor(),
        ),
        const SizedBox(height: 12),
        _buildIndicator(
          context,
          '段落结构',
          _getParagraphStructureIcon(),
          _getParagraphStructureText(),
          _getParagraphStructureColor(),
        ),
        const SizedBox(height: 12),
        _buildIndicator(
          context,
          '句式复杂度',
          _getSentenceComplexityIcon(),
          _getSentenceComplexityText(),
          _getSentenceComplexityColor(),
        ),
      ],
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    String label,
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getLanguageStyleIcon() {
    switch (languageStyle) {
      case LanguageStyle.formal:
        return Icons.business_center;
      case LanguageStyle.casual:
        return Icons.face;
      case LanguageStyle.mixed:
        return Icons.swap_horiz;
      case LanguageStyle.unknown:
        return Icons.help_outline;
    }
  }

  String _getLanguageStyleText() {
    switch (languageStyle) {
      case LanguageStyle.formal:
        return '正式风格';
      case LanguageStyle.casual:
        return '口语化风格';
      case LanguageStyle.mixed:
        return '混合风格';
      case LanguageStyle.unknown:
        return '尚未检测';
    }
  }

  Color _getLanguageStyleColor() {
    switch (languageStyle) {
      case LanguageStyle.formal:
        return Colors.blue;
      case LanguageStyle.casual:
        return Colors.green;
      case LanguageStyle.mixed:
        return Colors.purple;
      case LanguageStyle.unknown:
        return Colors.grey;
    }
  }

  IconData _getDetailLevelIcon() {
    switch (detailLevel) {
      case DetailLevel.concise:
        return Icons.compress;
      case DetailLevel.moderate:
        return Icons.fit_screen;
      case DetailLevel.detailed:
        return Icons.description;
      case DetailLevel.verbose:
        return Icons.menu_book;
      case DetailLevel.unknown:
        return Icons.help_outline;
    }
  }

  String _getDetailLevelText() {
    switch (detailLevel) {
      case DetailLevel.concise:
        return '简洁';
      case DetailLevel.moderate:
        return '适中';
      case DetailLevel.detailed:
        return '详细';
      case DetailLevel.verbose:
        return '极其详细';
      case DetailLevel.unknown:
        return '尚未检测';
    }
  }

  Color _getDetailLevelColor() {
    switch (detailLevel) {
      case DetailLevel.concise:
        return Colors.lightBlue;
      case DetailLevel.moderate:
        return Colors.blue;
      case DetailLevel.detailed:
        return Colors.indigo;
      case DetailLevel.verbose:
        return Colors.deepPurple;
      case DetailLevel.unknown:
        return Colors.grey;
    }
  }

  IconData _getParagraphStructureIcon() {
    switch (paragraphStructure) {
      case ParagraphStructure.shortParagraphs:
        return Icons.short_text;
      case ParagraphStructure.mediumParagraphs:
        return Icons.text_fields;
      case ParagraphStructure.longParagraphs:
        return Icons.notes;
      case ParagraphStructure.mixed:
        return Icons.view_headline;
      case ParagraphStructure.unknown:
        return Icons.help_outline;
    }
  }

  String _getParagraphStructureText() {
    switch (paragraphStructure) {
      case ParagraphStructure.shortParagraphs:
        return '短段落';
      case ParagraphStructure.mediumParagraphs:
        return '中等段落';
      case ParagraphStructure.longParagraphs:
        return '长段落';
      case ParagraphStructure.mixed:
        return '混合段落';
      case ParagraphStructure.unknown:
        return '尚未检测';
    }
  }

  Color _getParagraphStructureColor() {
    switch (paragraphStructure) {
      case ParagraphStructure.shortParagraphs:
        return Colors.teal;
      case ParagraphStructure.mediumParagraphs:
        return Colors.green;
      case ParagraphStructure.longParagraphs:
        return Colors.lightGreen;
      case ParagraphStructure.mixed:
        return Colors.lime;
      case ParagraphStructure.unknown:
        return Colors.grey;
    }
  }

  IconData _getSentenceComplexityIcon() {
    switch (sentenceComplexity) {
      case SentenceComplexity.simple:
        return Icons.looks_one;
      case SentenceComplexity.moderate:
        return Icons.looks_two;
      case SentenceComplexity.complex:
        return Icons.format_quote;
      case SentenceComplexity.varied:
        return Icons.shuffle;
      case SentenceComplexity.unknown:
        return Icons.help_outline;
    }
  }

  String _getSentenceComplexityText() {
    switch (sentenceComplexity) {
      case SentenceComplexity.simple:
        return '简单句式';
      case SentenceComplexity.moderate:
        return '中等复杂度';
      case SentenceComplexity.complex:
        return '复杂句式';
      case SentenceComplexity.varied:
        return '多样化';
      case SentenceComplexity.unknown:
        return '尚未检测';
    }
  }

  Color _getSentenceComplexityColor() {
    switch (sentenceComplexity) {
      case SentenceComplexity.simple:
        return Colors.lightGreen;
      case SentenceComplexity.moderate:
        return Colors.green;
      case SentenceComplexity.complex:
        return Colors.teal;
      case SentenceComplexity.varied:
        return Colors.cyan;
      case SentenceComplexity.unknown:
        return Colors.grey;
    }
  }
}
