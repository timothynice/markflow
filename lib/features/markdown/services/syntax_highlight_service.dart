import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import '../../../theme_controller.dart';

/// Enhanced syntax highlighting service with language detection and theme support
class SyntaxHighlightService {
  static SyntaxHighlightService? _instance;
  static SyntaxHighlightService get instance => _instance ??= SyntaxHighlightService._();

  SyntaxHighlightService._();

  // Cache for highlighters by language and theme
  final Map<String, Map<String, Highlighter>> _highlighterCache = {};

  // Cache for highlighted code to avoid re-processing
  final Map<String, TextSpan> _resultCache = {};
  static const int _maxCacheSize = 100; // Limit cache size to prevent memory issues

  // Currently loaded languages
  final Set<String> _loadedLanguages = {};

  // Initialization status
  bool _isInitialized = false;
  Completer<void>? _initializationCompleter;

  // Performance tracking
  final Map<String, int> _languageUsageCount = {};
  final Map<String, Duration> _highlightingTimes = {};

  /// All supported languages in syntax_highlight package
  static const List<String> supportedLanguages = [
    'css',
    'dart',
    'go',
    'html',
    'java',
    'javascript',
    'json',
    'kotlin',
    'python',
    'rust',
    'sql',
    'swift',
    'typescript',
    'yaml',
  ];

  /// Common language aliases and mappings
  static const Map<String, String> languageAliases = {
    // JavaScript variants
    'js': 'javascript',
    'jsx': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',

    // Python variants
    'py': 'python',
    'python3': 'python',

    // HTML variants
    'htm': 'html',
    'xml': 'html',

    // CSS variants
    'scss': 'css',
    'sass': 'css',
    'less': 'css',

    // Java variants
    'kt': 'kotlin',
    'kts': 'kotlin',

    // Go variants
    'golang': 'go',

    // SQL variants
    'sqlite': 'sql',
    'mysql': 'sql',
    'postgresql': 'sql',
    'postgres': 'sql',

    // YAML variants
    'yml': 'yaml',

    // JSON variants
    'jsonc': 'json',

    // Rust variants
    'rs': 'rust',
  };

  /// Initialize the service with commonly used languages
  Future<void> initialize({List<String>? languages}) async {
    if (_isInitialized) return;

    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<void>();

    try {
      // Load all supported languages by default for better UX
      final languagesToLoad = languages ?? supportedLanguages;
      await Highlighter.initialize(languagesToLoad);
      _loadedLanguages.addAll(languagesToLoad);
      _isInitialized = true;
      _initializationCompleter!.complete();
    } catch (e) {
      debugPrint('Failed to initialize SyntaxHighlightService: $e');
      _initializationCompleter!.completeError(e);
      _initializationCompleter = null;
    }
  }

  /// Get a highlighter for the specified language and theme
  Future<Highlighter?> getHighlighter(String language, {bool isDarkMode = false}) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Normalize language name
    final normalizedLang = _normalizeLanguage(language);
    if (!supportedLanguages.contains(normalizedLang)) {
      return null;
    }

    final themeKey = isDarkMode ? 'dark' : 'light';
    final cacheKey = '${normalizedLang}_$themeKey';

    // Check cache first
    if (_highlighterCache[normalizedLang]?.containsKey(themeKey) == true) {
      return _highlighterCache[normalizedLang]![themeKey];
    }

    // Load additional language if needed
    if (!_loadedLanguages.contains(normalizedLang)) {
      try {
        await Highlighter.initialize([normalizedLang]);
        _loadedLanguages.add(normalizedLang);
      } catch (e) {
        debugPrint('Failed to load language $normalizedLang: $e');
        return null;
      }
    }

    try {
      // Load theme
      final theme = isDarkMode
          ? await HighlighterTheme.loadDarkTheme()
          : await HighlighterTheme.loadLightTheme();

      // Create highlighter
      final highlighter = Highlighter(
        language: normalizedLang,
        theme: theme,
      );

      // Cache the highlighter
      _highlighterCache[normalizedLang] ??= {};
      _highlighterCache[normalizedLang]![themeKey] = highlighter;

      return highlighter;
    } catch (e) {
      debugPrint('Failed to create highlighter for $normalizedLang: $e');
      return null;
    }
  }

  /// Highlight code with automatic language detection and caching
  Future<TextSpan?> highlight(
    String code,
    String? language, {
    bool isDarkMode = false,
  }) async {
    if (code.trim().isEmpty) return null;

    // Detect language if not provided
    final detectedLanguage = language ?? detectLanguage(code);
    final themeKey = isDarkMode ? 'dark' : 'light';

    // Create cache key based on code content, language, and theme
    final cacheKey = '${code.hashCode}_${detectedLanguage}_$themeKey';

    // Check cache first for performance
    if (_resultCache.containsKey(cacheKey)) {
      _updateLanguageUsage(detectedLanguage);
      return _resultCache[cacheKey];
    }

    // Start performance tracking
    final stopwatch = Stopwatch()..start();

    final highlighter = await getHighlighter(detectedLanguage, isDarkMode: isDarkMode);

    TextSpan result;
    if (highlighter == null) {
      // Return plain text if highlighting fails
      result = TextSpan(
        text: code,
        style: TextStyle(
          fontFamily: 'GeistMono',
          fontSize: 14,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
        ),
      );
    } else {
      try {
        result = highlighter.highlight(code);
      } catch (e) {
        debugPrint('Failed to highlight code: $e');
        // Return plain text as fallback
        result = TextSpan(
          text: code,
          style: TextStyle(
            fontFamily: 'GeistMono',
            fontSize: 14,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
          ),
        );
      }
    }

    stopwatch.stop();

    // Track performance
    _highlightingTimes[detectedLanguage] = stopwatch.elapsed;
    _updateLanguageUsage(detectedLanguage);

    // Cache the result with size limit
    _cacheResult(cacheKey, result);

    return result;
  }

  /// Update language usage statistics
  void _updateLanguageUsage(String language) {
    _languageUsageCount[language] = (_languageUsageCount[language] ?? 0) + 1;
  }

  /// Cache highlighting result with size management
  void _cacheResult(String key, TextSpan result) {
    // Remove oldest entries if cache is full
    if (_resultCache.length >= _maxCacheSize) {
      // Remove the first 20% of entries to make room
      final keysToRemove = _resultCache.keys.take(_maxCacheSize ~/ 5).toList();
      for (final keyToRemove in keysToRemove) {
        _resultCache.remove(keyToRemove);
      }
    }

    _resultCache[key] = result;
  }

  /// Detect programming language from code content
  String detectLanguage(String code) {
    if (code.trim().isEmpty) return 'dart'; // Default fallback

    final trimmedCode = code.trim();
    final lines = trimmedCode.split('\n');
    final firstLine = lines.first.trim().toLowerCase();

    // Check for specific patterns

    // HTML/XML
    if (trimmedCode.startsWith('<!DOCTYPE') ||
        trimmedCode.startsWith('<html') ||
        trimmedCode.startsWith('<?xml') ||
        RegExp(r'^<[a-zA-Z][^>]*>').hasMatch(trimmedCode)) {
      return 'html';
    }

    // JSON
    if ((trimmedCode.startsWith('{') && trimmedCode.endsWith('}')) ||
        (trimmedCode.startsWith('[') && trimmedCode.endsWith(']'))) {
      try {
        // Simple JSON validation check
        if (RegExp(r'^\s*[{\[].*[}\]]\s*$', dotAll: true).hasMatch(trimmedCode)) {
          return 'json';
        }
      } catch (e) {
        // Not valid JSON, continue with other checks
      }
    }

    // CSS
    if (RegExp(r'[.#][a-zA-Z][^{]*\{[^}]*\}').hasMatch(trimmedCode) ||
        firstLine.contains('@media') ||
        firstLine.contains('@import') ||
        trimmedCode.contains('selector') ||
        RegExp(r'[a-zA-Z-]+\s*:\s*[^;]+;').hasMatch(trimmedCode)) {
      return 'css';
    }

    // YAML
    if (RegExp(r'^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*:').hasMatch(firstLine) &&
        !trimmedCode.contains('{') && !trimmedCode.contains(';')) {
      return 'yaml';
    }

    // SQL
    if (RegExp(r'\b(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|FROM|WHERE|JOIN)\b', caseSensitive: false)
        .hasMatch(trimmedCode)) {
      return 'sql';
    }

    // Dart
    if (trimmedCode.contains('import \'dart:') ||
        trimmedCode.contains('import \'package:') ||
        trimmedCode.contains('void main()') ||
        trimmedCode.contains('class ') && trimmedCode.contains('extends Widget') ||
        RegExp(r'\bString\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=').hasMatch(trimmedCode)) {
      return 'dart';
    }

    // Python
    if (trimmedCode.contains('def ') ||
        trimmedCode.contains('import ') && !trimmedCode.contains(';') ||
        trimmedCode.contains('from ') && trimmedCode.contains('import') ||
        firstLine.startsWith('#!/usr/bin/env python') ||
        firstLine.startsWith('#!/usr/bin/python')) {
      return 'python';
    }

    // JavaScript/TypeScript
    if (trimmedCode.contains('function ') ||
        trimmedCode.contains('const ') ||
        trimmedCode.contains('let ') ||
        trimmedCode.contains('var ') ||
        trimmedCode.contains('console.log') ||
        trimmedCode.contains('document.') ||
        trimmedCode.contains('window.') ||
        RegExp(r'\s*export\s+(default\s+)?(function|class|const|let)').hasMatch(trimmedCode)) {

      // Check for TypeScript specific patterns
      if (trimmedCode.contains(': string') ||
          trimmedCode.contains(': number') ||
          trimmedCode.contains(': boolean') ||
          trimmedCode.contains('interface ') ||
          trimmedCode.contains('type ') ||
          trimmedCode.contains('<T>') ||
          trimmedCode.contains('extends ')) {
        return 'typescript';
      }
      return 'javascript';
    }

    // Java
    if (trimmedCode.contains('public class ') ||
        trimmedCode.contains('private ') ||
        trimmedCode.contains('public static void main') ||
        trimmedCode.contains('import java.') ||
        RegExp(r'\bpublic\s+(static\s+)?[a-zA-Z_][a-zA-Z0-9_]*\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\(').hasMatch(trimmedCode)) {
      return 'java';
    }

    // Kotlin
    if (trimmedCode.contains('fun ') ||
        trimmedCode.contains('val ') ||
        trimmedCode.contains('var ') ||
        trimmedCode.contains('class ') && trimmedCode.contains(': ') ||
        firstLine.startsWith('package ') && trimmedCode.contains('import ')) {
      return 'kotlin';
    }

    // Go
    if (trimmedCode.contains('package ') ||
        trimmedCode.contains('func ') ||
        trimmedCode.contains('import "') ||
        trimmedCode.contains('fmt.Print') ||
        firstLine.startsWith('package main')) {
      return 'go';
    }

    // Rust
    if (trimmedCode.contains('fn ') ||
        trimmedCode.contains('let ') && trimmedCode.contains('mut ') ||
        trimmedCode.contains('use ') && trimmedCode.contains('::') ||
        trimmedCode.contains('println!') ||
        trimmedCode.contains('struct ') ||
        trimmedCode.contains('impl ')) {
      return 'rust';
    }

    // Swift
    if (trimmedCode.contains('func ') ||
        trimmedCode.contains('var ') && trimmedCode.contains(': ') ||
        trimmedCode.contains('let ') && trimmedCode.contains(': ') ||
        trimmedCode.contains('import Foundation') ||
        trimmedCode.contains('import UIKit') ||
        trimmedCode.contains('print(')) {
      return 'swift';
    }

    // Default fallback based on common indicators
    if (trimmedCode.contains(';') && trimmedCode.contains('{')) {
      return 'javascript'; // C-style syntax default
    }

    return 'dart'; // Default fallback
  }

  /// Normalize language name using aliases
  String _normalizeLanguage(String language) {
    final normalized = language.toLowerCase().trim();
    return languageAliases[normalized] ?? normalized;
  }

  /// Check if a language is supported
  bool isLanguageSupported(String language) {
    return supportedLanguages.contains(_normalizeLanguage(language));
  }

  /// Get all available languages
  List<String> getAvailableLanguages() {
    return List.from(supportedLanguages);
  }

  /// Clear the cache (useful for theme changes)
  void clearCache() {
    _highlighterCache.clear();
    _resultCache.clear();
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'languageUsage': Map.from(_languageUsageCount),
      'highlightingTimes': _highlightingTimes.map((key, value) => MapEntry(key, value.inMilliseconds)),
      'cacheSize': _resultCache.length,
      'loadedLanguages': _loadedLanguages.toList(),
    };
  }

  /// Optimize cache based on usage patterns
  void optimizeCache() {
    // Keep only frequently used language highlighters
    final frequentLanguages = <String>{};
    for (final entry in _languageUsageCount.entries) {
      if (entry.value > 5) { // Threshold for frequent usage
        frequentLanguages.add(entry.key);
      }
    }

    // Remove infrequently used highlighter caches
    final keysToRemove = <String>[];
    for (final language in _highlighterCache.keys) {
      if (!frequentLanguages.contains(language)) {
        keysToRemove.add(language);
      }
    }

    for (final key in keysToRemove) {
      _highlighterCache.remove(key);
    }

    debugPrint('Cache optimized: kept ${frequentLanguages.length} frequent languages, '
              'removed ${keysToRemove.length} infrequent ones');
  }

  /// Clear performance statistics
  void clearStats() {
    _languageUsageCount.clear();
    _highlightingTimes.clear();
  }

  /// Preload commonly used languages for better performance
  Future<void> preloadCommonLanguages({bool isDarkMode = false}) async {
    const commonLanguages = ['dart', 'javascript', 'python', 'html', 'css', 'json', 'yaml'];

    final futures = commonLanguages.map((lang) =>
      getHighlighter(lang, isDarkMode: isDarkMode)
    );

    await Future.wait(futures);
  }
}