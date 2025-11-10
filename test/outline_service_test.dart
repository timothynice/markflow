import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/services/outline_service.dart';
import 'package:markflow/features/markdown/models/outline_item.dart';

void main() {
  group('OutlineService', () {
    group('parseOutline', () {
      test('should return empty list for empty content', () {
        final result = OutlineService.parseOutline('');
        expect(result, isEmpty);
      });

      test('should return empty list for content without headers', () {
        const content = '''
This is regular text.
Another paragraph here.
No headers in this content.
''';
        final result = OutlineService.parseOutline(content);
        expect(result, isEmpty);
      });

      test('should parse single level headers', () {
        const content = '''
# First Header
Some content here.

# Second Header
More content.

# Third Header
Final content.
''';
        final result = OutlineService.parseOutline(content);

        expect(result, hasLength(3));
        expect(result[0].title, 'First Header');
        expect(result[0].level, 1);
        expect(result[1].title, 'Second Header');
        expect(result[1].level, 1);
        expect(result[2].title, 'Third Header');
        expect(result[2].level, 1);
      });

      test('should parse multi-level headers and create hierarchy', () {
        const content = '''
# Main Chapter
Introduction to the chapter.

## Section 1
Content of section 1.

### Subsection 1.1
Detailed content.

### Subsection 1.2
More detailed content.

## Section 2
Content of section 2.

# Another Chapter
New chapter content.
''';
        final result = OutlineService.parseOutline(content);

        expect(result, hasLength(2)); // Two main chapters

        // First chapter
        expect(result[0].title, 'Main Chapter');
        expect(result[0].level, 1);
        expect(result[0].children, hasLength(2)); // Two sections

        // First section
        expect(result[0].children[0].title, 'Section 1');
        expect(result[0].children[0].level, 2);
        expect(result[0].children[0].children, hasLength(2)); // Two subsections

        // Subsections
        expect(result[0].children[0].children[0].title, 'Subsection 1.1');
        expect(result[0].children[0].children[0].level, 3);
        expect(result[0].children[0].children[1].title, 'Subsection 1.2');
        expect(result[0].children[0].children[1].level, 3);

        // Second section
        expect(result[0].children[1].title, 'Section 2');
        expect(result[0].children[1].level, 2);

        // Second chapter
        expect(result[1].title, 'Another Chapter');
        expect(result[1].level, 1);
      });

      test('should handle headers with various levels (H1-H6)', () {
        const content = '''
# Level 1
## Level 2
### Level 3
#### Level 4
##### Level 5
###### Level 6
''';
        final result = OutlineService.parseOutline(content);

        expect(result, hasLength(1)); // Only one top-level
        expect(result[0].level, 1);

        var current = result[0];
        for (int i = 2; i <= 6; i++) {
          expect(current.children, hasLength(1));
          current = current.children[0];
          expect(current.level, i);
          expect(current.title, 'Level $i');
        }
      });

      test('should calculate correct positions', () {
        const content = '''Line 1
# Header 1
Line 3
Line 4
## Header 2
Line 6''';
        final result = OutlineService.parseOutline(content);

        expect(result, hasLength(1));
        expect(result[0].title, 'Header 1');
        expect(result[0].position, 7); // After "Line 1\n"

        expect(result[0].children, hasLength(1));
        expect(result[0].children[0].title, 'Header 2');
        expect(result[0].children[0].position, 32); // After "Line 1\n# Header 1\nLine 3\nLine 4\n"
      });

      test('should handle headers with special characters', () {
        const content = '''
# Header with "quotes"
## Header with *emphasis*
### Header with `code`
#### Header with [link](url)
''';
        final result = OutlineService.parseOutline(content);

        expect(result, hasLength(1));
        expect(result[0].title, 'Header with "quotes"');

        var current = result[0];
        expect(current.children[0].title, 'Header with *emphasis*');
        current = current.children[0];
        expect(current.children[0].title, 'Header with `code`');
        current = current.children[0];
        expect(current.children[0].title, 'Header with [link](url)');
      });
    });

    group('findNearestHeader', () {
      test('should find correct header for given position', () {
        const content = '''# Header 1
Content 1
## Header 2
Content 2
# Header 3
Content 3''';
        final outline = OutlineService.parseOutline(content);

        // Position at start
        var nearest = OutlineService.findNearestHeader(outline, 0);
        expect(nearest?.title, 'Header 1');

        // Position in middle content
        nearest = OutlineService.findNearestHeader(outline, 25);
        expect(nearest?.title, 'Header 2');

        // Position at end
        nearest = OutlineService.findNearestHeader(outline, 100);
        expect(nearest?.title, 'Header 3');
      });

      test('should return null for position before first header', () {
        const content = '''Some content before headers
# First Header
Content''';
        final outline = OutlineService.parseOutline(content);

        final nearest = OutlineService.findNearestHeader(outline, 5);
        expect(nearest, isNull);
      });
    });

    group('updateActiveItem', () {
      test('should mark correct item as active', () {
        const content = '''# Header 1
## Header 2
# Header 3''';
        final outline = OutlineService.parseOutline(content);

        final updated = OutlineService.updateActiveItem(outline, 15);

        expect(updated[0].children[0].isActive, isTrue);
        expect(updated[0].isActive, isFalse);
        expect(updated[1].isActive, isFalse);
      });
    });

    group('flattenOutline', () {
      test('should flatten hierarchical outline to flat list', () {
        const content = '''# Header 1
## Header 2
### Header 3
# Header 4''';
        final outline = OutlineService.parseOutline(content);
        final flattened = OutlineService.flattenOutline(outline);

        expect(flattened, hasLength(4));
        expect(flattened[0].title, 'Header 1');
        expect(flattened[1].title, 'Header 2');
        expect(flattened[2].title, 'Header 3');
        expect(flattened[3].title, 'Header 4');
      });
    });

    group('getHeaderPositions', () {
      test('should return sorted list of header positions', () {
        const content = '''# Header 1
Content
## Header 2
More content
# Header 3''';
        final outline = OutlineService.parseOutline(content);
        final positions = OutlineService.getHeaderPositions(outline);

        expect(positions, hasLength(3));
        expect(positions[0], lessThan(positions[1]));
        expect(positions[1], lessThan(positions[2]));
      });
    });
  });
}