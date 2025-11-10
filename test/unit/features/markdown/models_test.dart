import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/models.dart';

void main() {
  group('MdVersion', () {
    late DateTime testDate;
    late MdVersion testVersion;

    setUp(() {
      testDate = DateTime.parse('2023-12-01T10:30:00.000Z');
      testVersion = MdVersion(
        id: 'version-123',
        createdAt: testDate,
        content: '# Test Content\n\nThis is test markdown content.',
      );
    });

    test('should create MdVersion with required fields', () {
      expect(testVersion.id, equals('version-123'));
      expect(testVersion.createdAt, equals(testDate));
      expect(testVersion.content, equals('# Test Content\n\nThis is test markdown content.'));
    });

    test('should convert MdVersion to JSON correctly', () {
      final json = testVersion.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('version-123'));
      expect(json['createdAt'], equals('2023-12-01T10:30:00.000Z'));
      expect(json['content'], equals('# Test Content\n\nThis is test markdown content.'));
      expect(json.keys, hasLength(3));
    });

    test('should create MdVersion from JSON correctly', () {
      final json = {
        'id': 'version-456',
        'createdAt': '2023-12-02T15:45:30.123Z',
        'content': '## Another Test\n\nDifferent content.',
      };

      final version = MdVersion.fromJson(json);

      expect(version.id, equals('version-456'));
      expect(version.createdAt, equals(DateTime.parse('2023-12-02T15:45:30.123Z')));
      expect(version.content, equals('## Another Test\n\nDifferent content.'));
    });

    test('should handle ISO8601 date formatting correctly', () {
      // Test with different date formats and timezones
      final dates = [
        DateTime.parse('2023-01-01T00:00:00.000Z'),
        DateTime.parse('2023-12-31T23:59:59.999Z'),
        DateTime.now(),
      ];

      for (final date in dates) {
        final version = MdVersion(
          id: 'test',
          createdAt: date,
          content: 'test',
        );

        final json = version.toJson();
        final recreated = MdVersion.fromJson(json);

        expect(recreated.createdAt.millisecondsSinceEpoch,
               equals(date.millisecondsSinceEpoch));
      }
    });

    test('should handle empty content', () {
      final emptyVersion = MdVersion(
        id: 'empty-version',
        createdAt: testDate,
        content: '',
      );

      expect(emptyVersion.content, equals(''));

      final json = emptyVersion.toJson();
      final recreated = MdVersion.fromJson(json);

      expect(recreated.content, equals(''));
    });

    test('should handle special characters in content', () {
      const specialContent = '''
# Title with émojis 🚀
## Special chars: áéíóú ñ çĝħ
### Code: ```dart\nvoid main() => print("Hello!");\n```
#### Links: [link](https://example.com)
''';

      final version = MdVersion(
        id: 'special-chars',
        createdAt: testDate,
        content: specialContent,
      );

      final json = version.toJson();
      final recreated = MdVersion.fromJson(json);

      expect(recreated.content, equals(specialContent));
    });
  });

  group('MdDocument', () {
    late DateTime testDate;
    late MdVersion testVersion1;
    late MdVersion testVersion2;
    late MdDocument testDocument;

    setUp(() {
      testDate = DateTime.parse('2023-12-01T10:30:00.000Z');
      testVersion1 = MdVersion(
        id: 'v1',
        createdAt: testDate.subtract(const Duration(hours: 1)),
        content: 'Original content',
      );
      testVersion2 = MdVersion(
        id: 'v2',
        createdAt: testDate,
        content: 'Updated content',
      );
      testDocument = MdDocument(
        id: 'doc-123',
        title: 'Test Document',
        content: 'Current content',
        updatedAt: testDate,
        versions: [testVersion1, testVersion2],
      );
    });

    test('should create MdDocument with required fields', () {
      expect(testDocument.id, equals('doc-123'));
      expect(testDocument.title, equals('Test Document'));
      expect(testDocument.content, equals('Current content'));
      expect(testDocument.updatedAt, equals(testDate));
      expect(testDocument.versions, hasLength(2));
      expect(testDocument.versions[0].id, equals('v1'));
      expect(testDocument.versions[1].id, equals('v2'));
    });

    test('should convert MdDocument to JSON correctly', () {
      final json = testDocument.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('doc-123'));
      expect(json['title'], equals('Test Document'));
      expect(json['content'], equals('Current content'));
      expect(json['updatedAt'], equals('2023-12-01T10:30:00.000Z'));
      expect(json['versions'], isA<List>());
      expect(json['versions'], hasLength(2));
      expect(json.keys, hasLength(5));
    });

    test('should create MdDocument from JSON correctly', () {
      final json = {
        'id': 'doc-456',
        'title': 'Another Document',
        'content': 'Different content',
        'updatedAt': '2023-12-02T16:20:10.500Z',
        'versions': [
          {
            'id': 'v3',
            'createdAt': '2023-12-02T15:00:00.000Z',
            'content': 'Version 3 content',
          },
        ],
      };

      final document = MdDocument.fromJson(json);

      expect(document.id, equals('doc-456'));
      expect(document.title, equals('Another Document'));
      expect(document.content, equals('Different content'));
      expect(document.updatedAt, equals(DateTime.parse('2023-12-02T16:20:10.500Z')));
      expect(document.versions, hasLength(1));
      expect(document.versions[0].id, equals('v3'));
    });

    test('should handle empty versions list correctly', () {
      final json = {
        'id': 'doc-empty',
        'title': 'Empty Versions',
        'content': 'No versions',
        'updatedAt': '2023-12-01T10:30:00.000Z',
        'versions': <Map<String, dynamic>>[],
      };

      final document = MdDocument.fromJson(json);

      expect(document.versions, isEmpty);
    });

    test('should handle null versions list correctly', () {
      final json = {
        'id': 'doc-null-versions',
        'title': 'Null Versions',
        'content': 'Null versions handling',
        'updatedAt': '2023-12-01T10:30:00.000Z',
        // versions key intentionally omitted
      };

      final document = MdDocument.fromJson(json);

      expect(document.versions, isEmpty);
    });

    test('should convert to pretty JSON with correct indentation', () {
      final prettyJson = testDocument.toPrettyJson();

      expect(prettyJson, contains('{\n'));
      expect(prettyJson, contains('  "id": "doc-123"'));
      expect(prettyJson, contains('  "title": "Test Document"'));
      expect(prettyJson, contains('    "id": "v1"'));
      expect(prettyJson, contains('    "id": "v2"'));
    });

    test('should handle version list serialization correctly', () {
      final json = testDocument.toJson();
      final recreated = MdDocument.fromJson(json);

      expect(recreated.versions, hasLength(2));
      expect(recreated.versions[0].id, equals('v1'));
      expect(recreated.versions[0].content, equals('Original content'));
      expect(recreated.versions[1].id, equals('v2'));
      expect(recreated.versions[1].content, equals('Updated content'));
    });

    test('should update title and content fields', () {
      testDocument.title = 'Updated Title';
      testDocument.content = 'Updated Content';

      expect(testDocument.title, equals('Updated Title'));
      expect(testDocument.content, equals('Updated Content'));
    });

    test('should preserve version history when updated', () {
      final originalVersionsCount = testDocument.versions.length;
      final originalFirstVersion = testDocument.versions[0];

      testDocument.title = 'Modified Title';
      testDocument.content = 'Modified Content';

      expect(testDocument.versions, hasLength(originalVersionsCount));
      expect(testDocument.versions[0].id, equals(originalFirstVersion.id));
      expect(testDocument.versions[0].content, equals(originalFirstVersion.content));
    });

    test('should handle round-trip serialization with complex data', () {
      final complexDocument = MdDocument(
        id: 'complex-doc',
        title: 'Complex Document with Special Chars: àáâã äåæç',
        content: '''
# Complex Markdown

## Code Blocks
```dart
void main() {
  print('Hello, World! 🌍');
}
```

## Lists
- Item 1
- Item 2
  - Nested item

## Links and Images
[Google](https://google.com)
![Alt text](image.png)
        '''.trim(),
        updatedAt: DateTime.parse('2023-12-01T10:30:00.000Z'),
        versions: List.generate(5, (i) => MdVersion(
          id: 'complex-v$i',
          createdAt: DateTime.parse('2023-12-01T${10 + i}:00:00.000Z'),
          content: 'Version $i content with special chars: 测试',
        )),
      );

      final json = complexDocument.toJson();
      final recreated = MdDocument.fromJson(json);

      expect(recreated.title, equals(complexDocument.title));
      expect(recreated.content, equals(complexDocument.content));
      expect(recreated.versions, hasLength(5));

      for (int i = 0; i < 5; i++) {
        expect(recreated.versions[i].id, equals('complex-v$i'));
        expect(recreated.versions[i].content, contains('测试'));
      }
    });

    test('should handle edge case with very large content', () {
      final largeContent = 'A' * 10000; // 10k characters
      final largeDocument = MdDocument(
        id: 'large-doc',
        title: 'Large Document',
        content: largeContent,
        updatedAt: testDate,
        versions: [],
      );

      final json = largeDocument.toJson();
      final recreated = MdDocument.fromJson(json);

      expect(recreated.content, equals(largeContent));
      expect(recreated.content, hasLength(10000));
    });
  });
}