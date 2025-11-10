# Advanced Search & Replace Functionality

This document describes the advanced find & replace functionality implemented in the markflow Flutter app.

## Overview

The search functionality provides powerful text search and replacement capabilities with regex support, visual highlighting, and comprehensive navigation features.

## Features

### 🔍 Search Interface
- **Floating Search Bar**: Modern UI design that appears as an overlay
- **Mobile-Optimized**: Dedicated mobile interface that slides up from bottom
- **Real-time Search**: Search as you type with configurable debouncing
- **Visual Indicators**: Match count display and navigation controls

### ⚙️ Advanced Search Options
- **Case Sensitivity**: Toggle case-sensitive searching
- **Whole Word Matching**: Match complete words only
- **Regex Support**: Full regular expression pattern matching with error handling
- **Search History**: Remember and reuse recent search queries

### 🔄 Replace Functionality
- **Replace Single**: Replace the currently active match
- **Replace All**: Replace all matches at once
- **Visual Confirmation**: See changes immediately with highlighting
- **Undo Support**: Works with standard text editing undo operations

### 🧭 Navigation
- **Next/Previous**: Navigate between matches with visual indicators
- **Wrap Around**: Seamless navigation from last to first match
- **Jump to Match**: Click on match counter to jump to specific matches
- **Auto-scroll**: Automatically scroll active matches into view

### ⌨️ Keyboard Shortcuts
- `Cmd/Ctrl + F`: Open search overlay
- `F3`: Navigate to next match
- `Shift + F3`: Navigate to previous match
- `Escape`: Close search overlay or exit various modes
- `Enter`: Execute search or replace all

### 🎨 Visual Highlighting
- **Match Highlighting**: All matches highlighted in the editor
- **Active Match**: Currently selected match with distinct highlighting
- **Real-time Updates**: Highlighting updates as you type

## Architecture

### Core Components

#### 📊 Data Models (`models/search_result.dart`)
- `SearchMatch`: Represents individual search matches with position info
- `SearchResult`: Container for all search results and state
- `SearchOptions`: Configuration for search behavior

#### 🔧 Search Service (`services/search_service.dart`)
- `SearchService`: Core search logic with regex support and highlighting
- Handles search execution, navigation, and replace operations
- Manages search history with persistent storage
- Provides reactive updates via `ChangeNotifier`

#### 🎨 UI Components (`widgets/search_replace_overlay.dart`)
- `SearchReplaceOverlay`: Desktop search interface with full feature set
- `MobileSearchOverlay`: Mobile-optimized bottom sheet interface
- Animated transitions and responsive design

#### 🔗 Integration (`editor_screen.dart`)
- Integrated into markdown editor with keyboard shortcuts
- Text highlighting with TextSpan-based rendering
- Coordinated with editor scroll position and selection

### Key Features Implementation

#### Regex Search Engine
```dart
// Supports both literal and regex patterns
final pattern = options.useRegex
    ? RegExp(query, caseSensitive: options.caseSensitive)
    : RegExp(RegExp.escape(query), caseSensitive: options.caseSensitive);
```

#### Smart Text Highlighting
```dart
// Creates highlighted TextSpans for visual feedback
List<TextSpan> _createHighlightedSpans(String text, SearchResult result) {
  // Processes matches and creates appropriate highlighting
}
```

#### Debounced Search
```dart
// Optimizes performance with configurable debouncing
Timer? _debounceTimer;
_debounceTimer = Timer(debounce, () => _performSearch());
```

#### Persistent History
```dart
// Stores search history using SharedPreferences
Future<void> _saveSearchHistory() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_historyKey, _searchHistory);
}
```

## Usage Examples

### Basic Text Search
```dart
final searchService = SearchService();
final result = searchService.searchImmediate(
  text,
  'hello',
  options: SearchOptions(caseSensitive: false),
);
print('Found ${result.matchCount} matches');
```

### Regex Pattern Search
```dart
final result = searchService.searchImmediate(
  text,
  r'\b\w+@\w+\.\w+\b', // Email pattern
  options: SearchOptions(useRegex: true),
);
```

### Replace Operations
```dart
// Replace current match
final newText = searchService.replaceCurrent(text, 'replacement');

// Replace all matches
final allReplacedText = searchService.replaceAll(text, 'replacement');
```

### Navigation
```dart
// Navigate through matches
searchService.navigateToNext();
searchService.navigateToPrevious();
searchService.navigateToMatch(specificIndex);
```

## Testing

The search functionality includes comprehensive tests:

### Unit Tests
- **SearchResult Model Tests**: Data structure validation and operations
- **SearchService Tests**: Core search logic, regex handling, and edge cases
- **Performance Tests**: Debouncing and large text handling

### Widget Tests
- **SearchReplaceOverlay Tests**: UI interactions and state management
- **MobileSearchOverlay Tests**: Mobile-specific interface testing
- **Animation Tests**: Visual transition verification

### Integration Tests
- **End-to-End Workflows**: Complete search and replace scenarios
- **Keyboard Shortcut Tests**: Hotkey functionality verification
- **Mobile Interface Tests**: Touch interaction testing
- **Error Handling Tests**: Invalid regex and edge case handling

## Performance Considerations

- **Debounced Search**: Reduces unnecessary search operations while typing
- **Efficient Regex**: Uses compiled patterns for repeated searches
- **Lazy Highlighting**: Updates highlighting only when necessary
- **Memory Management**: Proper disposal of controllers and timers
- **Large Document Handling**: Optimized for documents up to several MB

## Error Handling

- **Regex Validation**: Catches and displays invalid regex patterns
- **Graceful Degradation**: Falls back to literal search on regex errors
- **User Feedback**: Clear error messages with suggestions
- **State Recovery**: Maintains previous valid search state on errors

## Accessibility

- **Keyboard Navigation**: Full keyboard accessibility
- **Screen Reader Support**: Proper semantic labeling
- **High Contrast**: Supports system accessibility settings
- **Focus Management**: Logical tab order and focus handling

## Future Enhancements

Potential improvements for future versions:

1. **Advanced Regex Builder**: Visual regex pattern builder
2. **Search Scope**: Limit search to selected text regions
3. **Multi-file Search**: Search across multiple documents
4. **Search Templates**: Saved search patterns with names
5. **Search Statistics**: Performance metrics and usage analytics
6. **Advanced Replace**: Conditional replacement with preview
7. **Search Bookmarks**: Mark and name specific search locations

## Files Modified/Created

### New Files
- `lib/features/markdown/models/search_result.dart`
- `lib/features/markdown/services/search_service.dart`
- `lib/features/markdown/widgets/search_replace_overlay.dart`

### Modified Files
- `lib/features/markdown/editor_screen.dart` - Integrated search functionality

### Test Files
- `test/unit/search/search_result_test.dart`
- `test/unit/search/search_service_test.dart`
- `test/widget/search/search_replace_overlay_test.dart`
- `test/integration/search_integration_test.dart`

## Dependencies

The search functionality uses these dependencies (all already present in the project):

- `flutter/material.dart` - UI components
- `shared_preferences` - Search history persistence
- `shadcn_ui` - UI component library
- Various testing packages for comprehensive test coverage

## Conclusion

This implementation provides a robust, user-friendly search and replace system that enhances the markdown editing experience with powerful features while maintaining excellent performance and accessibility.