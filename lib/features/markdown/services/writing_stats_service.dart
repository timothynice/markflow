import 'dart:math' as math;

/// Service for calculating writing statistics and text analysis
class WritingStatsService {
  /// Calculate comprehensive text statistics
  static TextStatistics calculateStats(String text) {
    if (text.isEmpty) {
      return TextStatistics.empty();
    }

    // Basic counts
    final characterCount = text.length;
    final characterCountNoSpaces = text.replaceAll(RegExp(r'\s'), '').length;
    final wordCount = _countWords(text);
    final paragraphCount = _countParagraphs(text);
    final sentenceCount = _countSentences(text);

    // Line counts
    final totalLines = text.split('\n').length;
    final nonEmptyLines = text.split('\n').where((line) => line.trim().isNotEmpty).length;

    // Reading time estimation (average 200 words per minute)
    final readingTimeMinutes = (wordCount / 200).ceil();

    // Markdown-specific analysis
    final markdownStats = _analyzeMarkdown(text);

    // Text complexity metrics
    final complexityMetrics = _calculateComplexity(text, wordCount, sentenceCount);

    return TextStatistics(
      wordCount: wordCount,
      characterCount: characterCount,
      characterCountNoSpaces: characterCountNoSpaces,
      paragraphCount: paragraphCount,
      sentenceCount: sentenceCount,
      totalLines: totalLines,
      nonEmptyLines: nonEmptyLines,
      readingTimeMinutes: readingTimeMinutes,
      markdownStats: markdownStats,
      complexityMetrics: complexityMetrics,
    );
  }

  /// Count words in text (handles various edge cases)
  static int _countWords(String text) {
    if (text.isEmpty) return 0;

    // Remove markdown syntax for more accurate word count
    var cleanText = text;

    // Remove code blocks
    cleanText = cleanText.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    cleanText = cleanText.replaceAll(RegExp(r'`[^`]*`'), ' ');

    // Remove links but keep link text
    cleanText = cleanText.replaceAll(RegExp(r'\[([^\]]*)\]\([^)]*\)'), r'$1');

    // Remove other markdown syntax
    cleanText = cleanText.replaceAll(RegExp(r'[*_~`#>\-+=|]'), ' ');

    // Split on whitespace and filter empty strings
    final words = cleanText
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();

    return words.length;
  }

  /// Count paragraphs (separated by blank lines)
  static int _countParagraphs(String text) {
    if (text.isEmpty) return 0;

    final paragraphs = text
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return math.max(1, paragraphs.length);
  }

  /// Count sentences (approximate)
  static int _countSentences(String text) {
    if (text.isEmpty) return 0;

    // Remove code blocks to avoid counting code as sentences
    var cleanText = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    cleanText = cleanText.replaceAll(RegExp(r'`[^`]*`'), ' ');

    // Count sentence-ending punctuation
    final sentenceEnders = RegExp(r'[.!?]+');
    final matches = sentenceEnders.allMatches(cleanText);

    return math.max(1, matches.length);
  }

  /// Analyze markdown-specific elements
  static MarkdownStatistics _analyzeMarkdown(String text) {
    final headingMatches = RegExp(r'^#{1,6}\s+', multiLine: true).allMatches(text);
    final linkMatches = RegExp(r'\[([^\]]*)\]\([^)]*\)').allMatches(text);
    final imageMatches = RegExp(r'!\[([^\]]*)\]\([^)]*\)').allMatches(text);
    final codeBlockMatches = RegExp(r'```[\s\S]*?```').allMatches(text);
    final inlineCodeMatches = RegExp(r'`[^`]*`').allMatches(text);
    final listItemMatches = RegExp(r'^\s*[-*+]\s+', multiLine: true).allMatches(text);
    final numberedListMatches = RegExp(r'^\s*\d+\.\s+', multiLine: true).allMatches(text);
    final boldMatches = RegExp(r'\*\*([^*]+)\*\*').allMatches(text);
    final italicMatches = RegExp(r'\*([^*]+)\*').allMatches(text);

    // Count different heading levels
    final headingLevels = <int, int>{};
    for (final match in headingMatches) {
      final level = match.group(0)!.trim().split('#').length - 1;
      headingLevels[level] = (headingLevels[level] ?? 0) + 1;
    }

    return MarkdownStatistics(
      headingCount: headingMatches.length,
      headingLevels: headingLevels,
      linkCount: linkMatches.length,
      imageCount: imageMatches.length,
      codeBlockCount: codeBlockMatches.length,
      inlineCodeCount: inlineCodeMatches.length,
      listItemCount: listItemMatches.length,
      numberedListItemCount: numberedListMatches.length,
      boldCount: boldMatches.length,
      italicCount: italicMatches.length,
    );
  }

  /// Calculate text complexity metrics
  static ComplexityMetrics _calculateComplexity(String text, int wordCount, int sentenceCount) {
    if (wordCount == 0 || sentenceCount == 0) {
      return ComplexityMetrics.empty();
    }

    final averageWordsPerSentence = wordCount / sentenceCount;

    // Flesch Reading Ease approximation (simplified)
    // Real formula requires syllable counting, this is a basic approximation
    var readingEase = 206.835 - (1.015 * averageWordsPerSentence);
    readingEase = math.max(0, math.min(100, readingEase));

    // Grade level approximation
    var gradeLevel = (0.39 * averageWordsPerSentence) + (11.8) - 15.59;
    gradeLevel = math.max(1, gradeLevel);

    return ComplexityMetrics(
      averageWordsPerSentence: averageWordsPerSentence,
      readingEaseScore: readingEase,
      gradeLevel: gradeLevel,
    );
  }

  /// Calculate words per minute for a time period
  static double calculateWPM(int wordCount, Duration timeSpent) {
    if (timeSpent.inSeconds == 0) return 0.0;
    return (wordCount * 60.0) / timeSpent.inSeconds;
  }

  /// Get reading difficulty description
  static String getReadingDifficulty(double readingEaseScore) {
    if (readingEaseScore >= 90) return 'Very Easy';
    if (readingEaseScore >= 80) return 'Easy';
    if (readingEaseScore >= 70) return 'Fairly Easy';
    if (readingEaseScore >= 60) return 'Standard';
    if (readingEaseScore >= 50) return 'Fairly Difficult';
    if (readingEaseScore >= 30) return 'Difficult';
    return 'Very Difficult';
  }
}

/// Text analysis results
class TextStatistics {
  final int wordCount;
  final int characterCount;
  final int characterCountNoSpaces;
  final int paragraphCount;
  final int sentenceCount;
  final int totalLines;
  final int nonEmptyLines;
  final int readingTimeMinutes;
  final MarkdownStatistics markdownStats;
  final ComplexityMetrics complexityMetrics;

  const TextStatistics({
    required this.wordCount,
    required this.characterCount,
    required this.characterCountNoSpaces,
    required this.paragraphCount,
    required this.sentenceCount,
    required this.totalLines,
    required this.nonEmptyLines,
    required this.readingTimeMinutes,
    required this.markdownStats,
    required this.complexityMetrics,
  });

  factory TextStatistics.empty() => TextStatistics(
    wordCount: 0,
    characterCount: 0,
    characterCountNoSpaces: 0,
    paragraphCount: 0,
    sentenceCount: 0,
    totalLines: 0,
    nonEmptyLines: 0,
    readingTimeMinutes: 0,
    markdownStats: MarkdownStatistics.empty(),
    complexityMetrics: ComplexityMetrics.empty(),
  );

  String get readingTimeFormatted {
    if (readingTimeMinutes < 1) return 'Less than 1 min';
    if (readingTimeMinutes == 1) return '1 min';
    if (readingTimeMinutes < 60) return '$readingTimeMinutes min';

    final hours = readingTimeMinutes ~/ 60;
    final minutes = readingTimeMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
}

/// Markdown-specific statistics
class MarkdownStatistics {
  final int headingCount;
  final Map<int, int> headingLevels;
  final int linkCount;
  final int imageCount;
  final int codeBlockCount;
  final int inlineCodeCount;
  final int listItemCount;
  final int numberedListItemCount;
  final int boldCount;
  final int italicCount;

  const MarkdownStatistics({
    required this.headingCount,
    required this.headingLevels,
    required this.linkCount,
    required this.imageCount,
    required this.codeBlockCount,
    required this.inlineCodeCount,
    required this.listItemCount,
    required this.numberedListItemCount,
    required this.boldCount,
    required this.italicCount,
  });

  factory MarkdownStatistics.empty() => const MarkdownStatistics(
    headingCount: 0,
    headingLevels: {},
    linkCount: 0,
    imageCount: 0,
    codeBlockCount: 0,
    inlineCodeCount: 0,
    listItemCount: 0,
    numberedListItemCount: 0,
    boldCount: 0,
    italicCount: 0,
  );
}

/// Text complexity metrics
class ComplexityMetrics {
  final double averageWordsPerSentence;
  final double readingEaseScore;
  final double gradeLevel;

  const ComplexityMetrics({
    required this.averageWordsPerSentence,
    required this.readingEaseScore,
    required this.gradeLevel,
  });

  factory ComplexityMetrics.empty() => const ComplexityMetrics(
    averageWordsPerSentence: 0.0,
    readingEaseScore: 0.0,
    gradeLevel: 0.0,
  );
}