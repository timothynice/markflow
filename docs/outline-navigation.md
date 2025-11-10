# Document Outline Navigation

The markflow editor now includes a comprehensive document outline navigation system that provides a hierarchical table of contents sidebar for markdown documents.

## Features

### 🗂️ **Hierarchical Outline Sidebar**
- Automatically parses markdown headers (H1-H6) from document content
- Displays nested structure with proper indentation
- Collapsible tree view for better organization
- Visual level indicators with color coding

### 🎯 **Section Jumping**
- Click any header in the outline to jump to that section
- Smooth scrolling animation to target location
- Keyboard shortcuts for quick navigation

### ⚡ **Real-time Updates**
- Outline updates automatically as you type
- Debounced parsing (500ms delay) for optimal performance
- Instant visual feedback for document structure changes

### 📱 **Responsive Design**
- Automatically hidden on mobile devices (< 720px width)
- Always visible on desktop with toggle functionality
- Collapsible sidebar that doesn't interfere with editing

### 🎨 **Visual Indicators**
- Current section highlighting based on scroll position
- Level-based color coding for different header depths
- Active section tracking with visual feedback
- Expand/collapse indicators for nested sections

### ⌨️ **Keyboard Shortcuts**
- `Cmd/Ctrl + \` - Toggle outline visibility
- `Cmd/Ctrl + 1/2/3` - Jump to next H1/H2/H3 header
- Standard navigation within the outline panel

## Architecture

### Core Components

#### **OutlineItem Model** (`models/outline_item.dart`)
```dart
class OutlineItem {
  final String title;        // Header text without markdown formatting
  final int level;           // Header level (1-6)
  final int position;        // Text position for jumping
  final String id;           // Unique identifier
  final List<OutlineItem> children;  // Nested headers
  final bool isActive;       // Current section indicator
}
```

#### **OutlineService** (`services/outline_service.dart`)
- **Header Parsing**: Extracts headers using regex patterns
- **Hierarchy Building**: Constructs nested tree structure
- **Position Tracking**: Calculates text positions for navigation
- **Active State Management**: Updates current section highlighting

Key methods:
```dart
static List<OutlineItem> parseOutline(String content)
static OutlineItem? findNearestHeader(List<OutlineItem> outline, int position)
static List<OutlineItem> updateActiveItem(List<OutlineItem> outline, int position)
```

#### **OutlineNavigator Widget** (`widgets/outline_navigator.dart`)
- **Animated Sidebar**: Smooth slide-in/out animations
- **Hierarchical Display**: Nested tree view with expand/collapse
- **Visual Styling**: Level indicators, active states, typography
- **Interaction Handling**: Tap navigation, keyboard shortcuts

### Integration Points

#### **Editor Screen Updates**
The main editor screen has been enhanced with:

1. **State Management**:
   - `_outline` - Current outline items
   - `_outlineVisible` - Sidebar visibility state
   - `_currentScrollPosition` - Scroll position tracking

2. **Real-time Updates**:
   - Debounced outline parsing on content changes
   - Scroll listener for active section tracking
   - Automatic outline refresh on document load

3. **Layout Integration**:
   - Row layout with sidebar and main content
   - Responsive breakpoints for mobile/desktop
   - Navigation bar with outline toggle button

## Usage

### For Users

1. **Viewing the Outline**:
   - The outline sidebar is visible by default on desktop
   - Click the "Outline" button in the navigation bar to toggle visibility
   - Use keyboard shortcut `Cmd/Ctrl + \` to toggle

2. **Navigation**:
   - Click any header in the outline to jump to that section
   - Use `Cmd/Ctrl + 1/2/3` to jump to next H1/H2/H3 header
   - The current section is highlighted automatically

3. **Organization**:
   - Click expand/collapse icons to organize the view
   - Headers are color-coded by level
   - Nested structure reflects document hierarchy

### For Developers

#### **Adding New Outline Features**:

1. **Extend OutlineItem**:
```dart
// Add new properties to the model
final DateTime createdAt;
final List<String> tags;
```

2. **Enhance OutlineService**:
```dart
// Add custom parsing logic
static List<OutlineItem> parseCustomHeaders(String content) {
  // Custom implementation
}
```

3. **Customize OutlineNavigator**:
```dart
// Add new visual elements or interactions
Widget _buildCustomOutlineItem(OutlineItem item) {
  // Custom UI implementation
}
```

## Performance Considerations

### **Optimization Strategies**

1. **Debounced Updates**: 500ms delay prevents excessive parsing during typing
2. **Efficient Parsing**: Regex-based header detection with single-pass processing
3. **Lazy Rendering**: Tree view items are rendered on-demand
4. **Memory Management**: Proper disposal of timers and controllers

### **Large Document Handling**

- Optimized for documents with hundreds of headers
- Efficient tree structure for nested hierarchies
- Minimal memory footprint with shared immutable data
- Smooth scrolling with calculated positions

## Testing

Comprehensive test coverage includes:

### **Unit Tests**
- `outline_service_test.dart` - Service logic and parsing
- `outline_item_test.dart` - Data model functionality

### **Widget Tests**
- `outline_navigator_test.dart` - UI interactions and rendering

### **Integration Tests**
- End-to-end navigation scenarios
- Performance testing with large documents
- Responsive behavior across device sizes

## Future Enhancements

### **Planned Features**
- [ ] Search within outline
- [ ] Bookmarks for frequently accessed sections
- [ ] Mini-map visualization for document structure
- [ ] Export outline as separate document
- [ ] Drag-and-drop header reordering

### **Advanced Navigation**
- [ ] Breadcrumb navigation
- [ ] Previous/next section buttons
- [ ] Go-to-line functionality from outline
- [ ] Section folding in main editor

## Accessibility

The outline navigation system includes:

- **Screen Reader Support**: Semantic HTML structure
- **Keyboard Navigation**: Full keyboard accessibility
- **High Contrast**: Proper color contrast ratios
- **Focus Management**: Clear focus indicators
- **ARIA Labels**: Descriptive labels for interactive elements

## Browser Compatibility

Tested and optimized for:
- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

---

This outline navigation system significantly enhances the document editing experience by providing clear document structure visualization and efficient navigation capabilities while maintaining excellent performance and user experience standards.