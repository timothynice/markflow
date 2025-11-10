import 'package:flutter/material.dart';
import '../models/completion_suggestion.dart';
import 'completion_provider.dart';

/// Provider for markdown link and image completions
class LinkCompletionProvider extends CompletionProvider with TriggerBasedProvider, UniversalProvider {
  @override
  String get name => 'Link Completion';

  @override
  Set<String> get triggerCharacters => {'[', '!'};

  @override
  int get priority => 9;

  @override
  Future<List<CompletionSuggestion>> getSuggestions(CompletionContext context) async {
    final suggestions = <CompletionSuggestion>[];

    final trigger = context.triggerCharacter;

    if (trigger == '[') {
      suggestions.addAll(_getLinkSuggestions(context));
    } else if (trigger == '!') {
      suggestions.addAll(_getImageSuggestions(context));
    }

    return suggestions;
  }

  List<CompletionSuggestion> _getLinkSuggestions(CompletionContext context) {
    final suggestions = <CompletionSuggestion>[];

    // Basic link formats
    suggestions.addAll([
      CompletionSuggestion(
        insertText: '[text](url)',
        displayText: '[text](url)',
        description: 'Basic link',
        type: CompletionType.link,
        icon: Icons.link,
        trigger: '[',
        priority: 10,
        cursorOffset: -5, // Position cursor at 'text'
        selectionLength: 4,
      ),
      CompletionSuggestion(
        insertText: '[text](url "title")',
        displayText: '[text](url "title")',
        description: 'Link with title',
        type: CompletionType.link,
        icon: Icons.link,
        trigger: '[',
        priority: 9,
        cursorOffset: -15,
        selectionLength: 4,
      ),
      CompletionSuggestion(
        insertText: '[text][ref]',
        displayText: '[text][ref]',
        description: 'Reference link',
        type: CompletionType.link,
        icon: Icons.link,
        trigger: '[',
        priority: 8,
        cursorOffset: -6,
        selectionLength: 4,
      ),
    ]);

    // Common link types
    final commonLinks = [
      ('[Homepage](https://)', 'Website homepage link'),
      ('[Documentation](https://)', 'Documentation link'),
      ('[GitHub](https://github.com/)', 'GitHub repository link'),
      ('[Download](https://)', 'Download link'),
      ('[Read more](https://)', 'Read more link'),
      ('[API Reference](https://)', 'API documentation link'),
      ('[Tutorial](https://)', 'Tutorial link'),
      ('[Example](https://)', 'Example link'),
    ];

    for (final (linkText, description) in commonLinks) {
      suggestions.add(CompletionSuggestion(
        insertText: linkText,
        displayText: linkText,
        description: description,
        type: CompletionType.link,
        icon: Icons.link,
        trigger: '[',
        priority: 7,
        cursorOffset: linkText.indexOf('https://') - linkText.length,
        selectionLength: 8, // Select 'https://'
      ));
    }

    // Internal reference links
    suggestions.addAll([
      CompletionSuggestion(
        insertText: '[Section](#section)',
        displayText: '[Section](#section)',
        description: 'Internal heading link',
        type: CompletionType.link,
        icon: Icons.tag,
        trigger: '[',
        priority: 6,
        cursorOffset: -9,
        selectionLength: 7,
      ),
      CompletionSuggestion(
        insertText: '[Back to top](#top)',
        displayText: '[Back to top](#top)',
        description: 'Back to top link',
        type: CompletionType.link,
        icon: Icons.keyboard_arrow_up,
        trigger: '[',
        priority: 5,
      ),
    ]);

    // Email and other special links
    suggestions.addAll([
      CompletionSuggestion(
        insertText: '[email@example.com](mailto:email@example.com)',
        displayText: '[email](mailto:...)',
        description: 'Email link',
        type: CompletionType.link,
        icon: Icons.email,
        trigger: '[',
        priority: 5,
        cursorOffset: -39,
        selectionLength: 17,
      ),
      CompletionSuggestion(
        insertText: '[tel:+1234567890](tel:+1234567890)',
        displayText: '[tel:...](tel:...)',
        description: 'Phone number link',
        type: CompletionType.link,
        icon: Icons.phone,
        trigger: '[',
        priority: 4,
        cursorOffset: -22,
        selectionLength: 12,
      ),
    ]);

    return suggestions;
  }

  List<CompletionSuggestion> _getImageSuggestions(CompletionContext context) {
    final suggestions = <CompletionSuggestion>[];

    // Check if we're completing an image (starts with !)
    final beforeCursor = context.textBeforeCursor;
    if (!beforeCursor.endsWith('!')) {
      return suggestions;
    }

    // Basic image formats
    suggestions.addAll([
      CompletionSuggestion(
        insertText: '![alt text](url)',
        displayText: '![alt text](url)',
        description: 'Basic image',
        type: CompletionType.image,
        icon: Icons.image,
        trigger: '!',
        priority: 10,
        cursorOffset: -5,
        selectionLength: 3,
      ),
      CompletionSuggestion(
        insertText: '![alt text](url "title")',
        displayText: '![alt text](url "title")',
        description: 'Image with title',
        type: CompletionType.image,
        icon: Icons.image,
        trigger: '!',
        priority: 9,
        cursorOffset: -15,
        selectionLength: 3,
      ),
      CompletionSuggestion(
        insertText: '![alt text][ref]',
        displayText: '![alt text][ref]',
        description: 'Reference image',
        type: CompletionType.image,
        icon: Icons.image,
        trigger: '!',
        priority: 8,
        cursorOffset: -6,
        selectionLength: 3,
      ),
    ]);

    // Common image types
    final commonImages = [
      ('![Screenshot](screenshot.png)', 'Screenshot image'),
      ('![Logo](logo.png)', 'Logo image'),
      ('![Diagram](diagram.svg)', 'Diagram image'),
      ('![Chart](chart.png)', 'Chart image'),
      ('![Icon](icon.svg)', 'Icon image'),
      ('![Photo](photo.jpg)', 'Photo image'),
      ('![Avatar](avatar.png)', 'Avatar image'),
      ('![Badge](https://img.shields.io/badge/)', 'Shield badge'),
    ];

    for (final (imageText, description) in commonImages) {
      suggestions.add(CompletionSuggestion(
        insertText: imageText,
        displayText: imageText,
        description: description,
        type: CompletionType.image,
        icon: Icons.image,
        trigger: '!',
        priority: 7,
        cursorOffset: imageText.indexOf(')') - imageText.length,
        selectionLength: imageText.substring(imageText.indexOf('(') + 1, imageText.indexOf(')')).length,
      ));
    }

    // Image with link wrapper
    suggestions.add(CompletionSuggestion(
      insertText: '[![alt text](image.png)](link)',
      displayText: '[![alt text](image.png)](link)',
      description: 'Clickable image',
      type: CompletionType.image,
      icon: Icons.add_link,
      trigger: '!',
      priority: 6,
      cursorOffset: -6,
      selectionLength: 4,
    ));

    // HTML img tag for more control
    suggestions.add(CompletionSuggestion(
      insertText: '<img src="url" alt="alt text" width="400">',
      displayText: '<img src="..." width="...">',
      description: 'HTML image with size',
      type: CompletionType.image,
      icon: Icons.code,
      trigger: '!',
      priority: 5,
      cursorOffset: -28,
      selectionLength: 3,
    ));

    return suggestions;
  }

  @override
  bool shouldActivate(CompletionContext context) {
    // Don't activate inside code blocks
    if (context.isInCodeBlock) return false;

    return super.shouldActivate(context);
  }
}