import 'package:flutter/material.dart';

class TextUtils {
  /// Truncates a title to a maximum number of words
  /// If the title exceeds maxWords, it adds "..." at the end
  static String truncateTitle(String title, {int maxWords = 4}) {
    if (title.isEmpty) return title;
    
    final words = title.trim().split(' ');
    if (words.length <= maxWords) return title;
    
    return '${words.take(maxWords).join(' ')}...';
  }

  /// Checks if a title is truncated (exceeds maxWords)
  static bool isTitleTruncated(String title, {int maxWords = 4}) {
    if (title.isEmpty) return false;
    
    final words = title.trim().split(' ');
    return words.length > maxWords;
  }

  /// Builds a truncated title widget with tooltip and visual indicators
  static Widget buildTruncatedTitleWidget(
    String title, {
    int maxWords = 4,
    TextStyle? style,
    Color? truncatedColor,
    bool showMoreIcon = true,
  }) {
    final isTruncated = isTitleTruncated(title, maxWords: maxWords);
    final truncatedTitle = truncateTitle(title, maxWords: maxWords);
    
    return Tooltip(
      message: isTruncated ? title : '',
      child: Row(
        children: [
          Expanded(
            child: Text(
              truncatedTitle,
              style: style?.copyWith(
                color: isTruncated ? (truncatedColor ?? Colors.blue) : style?.color,
              ) ?? TextStyle(
                color: isTruncated ? (truncatedColor ?? Colors.blue) : null,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          if (isTruncated && showMoreIcon) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.more_horiz,
              size: 16,
              color: Colors.blue,
            ),
          ],
        ],
      ),
    );
  }
}
