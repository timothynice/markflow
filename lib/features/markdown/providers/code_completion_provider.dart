import 'package:flutter/material.dart';
import '../models/completion_suggestion.dart';
import 'completion_provider.dart';

/// Provider for markdown code block and inline code completions
class CodeCompletionProvider extends CompletionProvider with TriggerBasedProvider, UniversalProvider {
  @override
  String get name => 'Code Completion';

  @override
  Set<String> get triggerCharacters => {'`'};

  @override
  int get priority => 8;

  @override
  Future<List<CompletionSuggestion>> getSuggestions(CompletionContext context) async {
    final suggestions = <CompletionSuggestion>[];

    // Count backticks before cursor to determine context
    final beforeCursor = context.textBeforeCursor;
    final backticksCount = _countTrailingBackticks(beforeCursor);

    if (backticksCount == 1) {
      suggestions.addAll(_getInlineCodeSuggestions(context));
    } else if (backticksCount >= 3) {
      suggestions.addAll(_getCodeBlockSuggestions(context));
    } else {
      // Show both options
      suggestions.addAll(_getInlineCodeSuggestions(context));
      suggestions.addAll(_getCodeBlockSuggestions(context));
    }

    return suggestions;
  }

  List<CompletionSuggestion> _getInlineCodeSuggestions(CompletionContext context) {
    final suggestions = <CompletionSuggestion>[];

    // Basic inline code
    suggestions.add(CompletionSuggestion(
      insertText: '`code`',
      displayText: '`code`',
      description: 'Inline code',
      type: CompletionType.emphasis,
      icon: Icons.code,
      trigger: '`',
      priority: 10,
      cursorOffset: -1,
      selectionLength: 4,
    ));

    // Common inline code patterns
    final commonPatterns = [
      ('`function()`', 'Function call'),
      ('`variable`', 'Variable name'),
      ('`className`', 'Class name'),
      ('`filename.ext`', 'Filename'),
      ('`npm install`', 'Command'),
      ('`ctrl+c`', 'Keyboard shortcut'),
      ('`true`', 'Boolean value'),
      ('`null`', 'Null value'),
      ('`undefined`', 'Undefined value'),
      ('`0`', 'Number value'),
    ];

    for (final (pattern, description) in commonPatterns) {
      suggestions.add(CompletionSuggestion(
        insertText: pattern,
        displayText: pattern,
        description: description,
        type: CompletionType.emphasis,
        icon: Icons.code,
        trigger: '`',
        priority: 8,
        cursorOffset: -1,
        selectionLength: pattern.length - 2,
      ));
    }

    return suggestions;
  }

  List<CompletionSuggestion> _getCodeBlockSuggestions(CompletionContext context) {
    final suggestions = <CompletionSuggestion>[];

    // Basic code block
    suggestions.add(CompletionSuggestion(
      insertText: '```\ncode\n```',
      displayText: '``` Code block',
      description: 'Code block without language',
      type: CompletionType.codeBlock,
      icon: Icons.code,
      trigger: '`',
      priority: 10,
      isSnippet: true,
      cursorOffset: -5,
      selectionLength: 4,
    ));

    // Language-specific code blocks
    final languages = [
      ('javascript', 'JavaScript code'),
      ('typescript', 'TypeScript code'),
      ('python', 'Python code'),
      ('java', 'Java code'),
      ('dart', 'Dart code'),
      ('cpp', 'C++ code'),
      ('c', 'C code'),
      ('csharp', 'C# code'),
      ('go', 'Go code'),
      ('rust', 'Rust code'),
      ('php', 'PHP code'),
      ('ruby', 'Ruby code'),
      ('swift', 'Swift code'),
      ('kotlin', 'Kotlin code'),
      ('html', 'HTML markup'),
      ('css', 'CSS styles'),
      ('scss', 'SCSS styles'),
      ('json', 'JSON data'),
      ('yaml', 'YAML configuration'),
      ('toml', 'TOML configuration'),
      ('xml', 'XML markup'),
      ('sql', 'SQL query'),
      ('bash', 'Bash script'),
      ('shell', 'Shell script'),
      ('powershell', 'PowerShell script'),
      ('dockerfile', 'Dockerfile'),
      ('markdown', 'Markdown text'),
      ('diff', 'Diff/Patch'),
      ('plaintext', 'Plain text'),
    ];

    for (final (lang, description) in languages) {
      suggestions.add(CompletionSuggestion(
        insertText: '```$lang\ncode\n```',
        displayText: '```$lang',
        description: description,
        type: CompletionType.codeBlock,
        icon: Icons.code,
        trigger: '`',
        priority: 9,
        isSnippet: true,
        cursorOffset: -5,
        selectionLength: 4,
      ));
    }

    // Code block templates
    final templates = [
      (
        '```javascript\nfunction example() {\n  // Your code here\n  return true;\n}\n```',
        'JavaScript function template',
      ),
      (
        '```python\ndef example():\n    """Your function here"""\n    pass\n```',
        'Python function template',
      ),
      (
        '```dart\nclass Example {\n  // Your class here\n}\n```',
        'Dart class template',
      ),
      (
        '```json\n{\n  "key": "value"\n}\n```',
        'JSON object template',
      ),
      (
        '```yaml\nkey: value\nlist:\n  - item1\n  - item2\n```',
        'YAML configuration template',
      ),
      (
        '```bash\n#!/bin/bash\necho "Hello World"\n```',
        'Bash script template',
      ),
      (
        '```css\n.class {\n  property: value;\n}\n```',
        'CSS rule template',
      ),
      (
        '```html\n<div class="container">\n  <p>Content</p>\n</div>\n```',
        'HTML element template',
      ),
    ];

    for (final (template, description) in templates) {
      final lang = template.substring(3, template.indexOf('\n'));
      suggestions.add(CompletionSuggestion(
        insertText: template,
        displayText: '```$lang template',
        description: description,
        type: CompletionType.codeBlock,
        icon: Icons.snippet_folder,
        trigger: '`',
        priority: 7,
        isSnippet: true,
      ));
    }

    // Mermaid diagrams
    final mermaidTemplates = [
      (
        '```mermaid\ngraph TD\n    A[Start] --> B[Process]\n    B --> C[End]\n```',
        'Mermaid flowchart',
      ),
      (
        '```mermaid\nsequenceDiagram\n    participant A\n    participant B\n    A->>B: Message\n    B->>A: Response\n```',
        'Mermaid sequence diagram',
      ),
      (
        '```mermaid\ngantt\n    title Project Timeline\n    section Phase 1\n    Task 1 :2023-01-01, 30d\n```',
        'Mermaid Gantt chart',
      ),
    ];

    for (final (template, description) in mermaidTemplates) {
      suggestions.add(CompletionSuggestion(
        insertText: template,
        displayText: description,
        description: description,
        type: CompletionType.codeBlock,
        icon: Icons.account_tree,
        trigger: '`',
        priority: 6,
        isSnippet: true,
      ));
    }

    return suggestions;
  }

  int _countTrailingBackticks(String text) {
    int count = 0;
    for (int i = text.length - 1; i >= 0; i--) {
      if (text[i] == '`') {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  @override
  bool shouldActivate(CompletionContext context) {
    return super.shouldActivate(context);
  }
}