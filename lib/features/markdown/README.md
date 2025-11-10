# Enhanced Syntax Highlighting System

This enhanced syntax highlighting system provides intelligent code highlighting with automatic language detection, theme support, and performance optimizations for the markflow Flutter app.

## Features

- **Automatic Language Detection**: Intelligently detects programming languages from code content
- **15+ Language Support**: Supports all languages from the syntax_highlight package
- **Theme Integration**: Works seamlessly with light/dark themes
- **Performance Optimized**: Caching, debouncing, and memory management
- **Rich UI Components**: Enhanced code blocks with copy buttons, language labels, and line numbers
- **Fallback Handling**: Graceful degradation for unsupported languages
- **Comprehensive Testing**: Unit tests, widget tests, and integration tests

## Supported Languages

- CSS
- Dart
- Go
- HTML
- Java
- JavaScript
- JSON
- Kotlin
- Python
- Rust
- SQL
- Swift
- TypeScript
- YAML

## Language Aliases

The system supports common language aliases:

| Alias | Maps To |
|-------|---------|
| js, jsx | javascript |
| ts, tsx | typescript |
| py, python3 | python |
| htm, xml | html |
| scss, sass, less | css |
| kt, kts | kotlin |
| golang | go |
| sqlite, mysql, postgresql, postgres | sql |
| yml | yaml |
| jsonc | json |
| rs | rust |

## Components

### SyntaxHighlightService

The core service that provides syntax highlighting functionality.

```dart
// Get the singleton instance
final service = SyntaxHighlightService.instance;

// Initialize with specific languages (optional)
await service.initialize(['dart', 'javascript', 'python']);

// Highlight code with automatic detection
final highlightedSpan = await service.highlight(
  'console.log("Hello, World!");',
  null, // Auto-detect language
  isDarkMode: true,
);

// Highlight code with specified language
final highlightedSpan = await service.highlight(
  'def hello(): pass',
  'python',
  isDarkMode: false,
);

// Detect language only
final language = service.detectLanguage('console.log("test");');
print(language); // outputs: javascript
```

### EnhancedCodeBlock

A comprehensive code block widget with syntax highlighting and additional features.

```dart
const EnhancedCodeBlock(
  code: '''
function greet(name) {
  console.log(`Hello, \${name}!`);
  return true;
}
''',
  language: 'javascript', // Optional - will auto-detect if omitted
  showLineNumbers: true,
  showCopyButton: true,
  showLanguageLabel: true,
  fontSize: 14.0,
  fontFamily: 'GeistMono',
)
```

### EnhancedMarkdown

A markdown widget that automatically applies syntax highlighting to code blocks.

```dart
const EnhancedMarkdown(
  data: '''
# My Document

```dart
void main() {
  print('Hello, World!');
}
```

```javascript
console.log('Hello, World!');
```
''',
  showCopyButton: true,
  showLanguageLabel: true,
  showLineNumbers: false,
  codeBlockFontSize: 13,
  codeBlockFontFamily: 'GeistMono',
)
```

### DebouncedCodeBlock

A performance-optimized code block that debounces highlighting updates during rapid text changes.

```dart
const DebouncedCodeBlock(
  code: dynamicCode, // Updates frequently
  debounceDelay: Duration(milliseconds: 300),
  showCopyButton: true,
  showLanguageLabel: true,
)
```

## Usage Examples

### Basic Code Highlighting

```dart
import 'package:markflow/features/markdown/services/syntax_highlight_service.dart';

class MyCodeWidget extends StatefulWidget {
  @override
  _MyCodeWidgetState createState() => _MyCodeWidgetState();
}

class _MyCodeWidgetState extends State<MyCodeWidget> {
  TextSpan? highlightedCode;

  @override
  void initState() {
    super.initState();
    _highlightCode();
  }

  Future<void> _highlightCode() async {
    final service = SyntaxHighlightService.instance;
    final result = await service.highlight(
      'print("Hello from Python!")',
      'python',
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
    );

    setState(() {
      highlightedCode = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: highlightedCode != null
        ? SelectableText.rich(highlightedCode!)
        : const CircularProgressIndicator(),
    );
  }
}
```

### Custom Markdown with Syntax Highlighting

```dart
import 'package:markflow/features/markdown/widgets/markdown_code_builder.dart';

class MyMarkdownViewer extends StatelessWidget {
  final String markdownContent;

  const MyMarkdownViewer({required this.markdownContent});

  @override
  Widget build(BuildContext context) {
    return EnhancedMarkdown(
      data: markdownContent,
      padding: const EdgeInsets.all(16),
      showCopyButton: true,
      showLanguageLabel: true,
      showLineNumbers: false,
      onTapLink: (text, href, title) {
        // Handle link taps
        if (href != null) {
          // Launch URL or handle as needed
        }
      },
    );
  }
}
```

### Performance Monitoring

```dart
final service = SyntaxHighlightService.instance;

// Get performance statistics
final stats = service.getPerformanceStats();
print('Language usage: \${stats['languageUsage']}');
print('Highlighting times: \${stats['highlightingTimes']}');
print('Cache size: \${stats['cacheSize']}');

// Optimize cache based on usage patterns
service.optimizeCache();

// Clear cache and stats when needed
service.clearCache();
service.clearStats();
```

## Initialization

The syntax highlighting service is automatically initialized during app startup in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize syntax highlighting
  await SyntaxHighlightInitializer.initialize();

  runApp(const MyApp());
}
```

## Performance Considerations

### Caching
- Highlighter instances are cached by language and theme
- Highlighted code results are cached to avoid re-processing
- Cache size is automatically managed with a configurable limit

### Debouncing
- Use `DebouncedCodeBlock` for frequently changing code content
- Configurable debounce delays to balance responsiveness and performance

### Memory Management
- Automatic cache cleanup based on usage patterns
- Performance statistics to monitor resource usage
- Graceful degradation for unsupported languages

### Optimization Tips

1. **Preload Common Languages**: The service automatically preloads common languages during initialization
2. **Use Debouncing**: For rapidly changing content, use `DebouncedCodeBlock`
3. **Monitor Performance**: Use `getPerformanceStats()` to identify bottlenecks
4. **Optimize Cache**: Call `optimizeCache()` periodically to remove unused entries

## Testing

The system includes comprehensive tests:

### Unit Tests
```bash
flutter test test/unit/features/markdown/services/syntax_highlight_service_test.dart
```

### Widget Tests
```bash
flutter test test/widget/features/markdown/enhanced_code_block_test.dart
```

### Integration Tests
```bash
flutter test integration_test/markdown_syntax_highlighting_test.dart
```

## Architecture

### Service Layer
- `SyntaxHighlightService`: Core highlighting functionality
- `SyntaxHighlightInitializer`: Initialization and theme integration

### Widget Layer
- `EnhancedCodeBlock`: Standalone code block component
- `EnhancedMarkdown`: Markdown widget with highlighting
- `MarkdownCodeBuilder`: Custom markdown code builder
- `DebouncedCodeBlock`: Performance-optimized code block

### Performance Layer
- Result caching for highlighted code
- Highlighter instance caching
- Usage statistics and optimization
- Memory management and cleanup

## Future Enhancements

Potential improvements for future versions:

1. **More Languages**: Add support for additional programming languages
2. **Custom Themes**: Support for custom syntax highlighting themes
3. **Advanced Detection**: More sophisticated language detection algorithms
4. **Plugin System**: Extensible architecture for custom language support
5. **Performance Analytics**: Detailed performance monitoring and reporting
6. **Streaming Highlighting**: Progressive highlighting for very large documents

## Troubleshooting

### Common Issues

**Highlighting not working**: Ensure the service is properly initialized in `main.dart`

**Performance issues**: Use `DebouncedCodeBlock` for frequently changing content and monitor performance statistics

**Memory issues**: Call `optimizeCache()` periodically and monitor cache size

**Language not detected**: Check if the language is in the supported list or add appropriate patterns to the detection algorithm

**Theme issues**: Ensure theme changes trigger cache clearing via `SyntaxHighlightInitializer`