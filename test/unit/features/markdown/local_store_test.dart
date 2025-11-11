import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/local_store.dart';
import 'package:markflow/features/markdown/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MdLocalStore', () {
    late MdLocalStore localStore;

    setUp(() {
      localStore = MdLocalStore();
      // Reset shared preferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      // Clean up is handled by setUp() resetting mock values
    });

    group('Document Loading', () {
      test('should create starter document when no documents exist', () async {
        final doc = await localStore.load();

        expect(doc.title, equals('Welcome'));
        expect(doc.content, contains('# Welcome to Markdown Editor'));
        expect(doc.id, startsWith('local-'));
        expect(doc.versions, hasLength(1));
        expect(doc.versions[0].content, equals(doc.content));
      });

      test('should load current document when currentId exists', () async {
        // Setup: Save a document first
        final testDoc = MdDocument(
          id: 'test-doc-123',
          title: 'Test Document',
          content: 'Test content',
          updatedAt: DateTime.now(),
          versions: [],
        );
        await localStore.save(testDoc);

        // Test: Load should return the saved document
        final loaded = await localStore.load();

        expect(loaded.id, equals('test-doc-123'));
        expect(loaded.title, equals('Test Document'));
        expect(loaded.content, equals('Test content'));
      });

      test('should migrate legacy document when found', () async {
        final legacyDoc = MdDocument(
          id: 'legacy-doc',
          title: 'Legacy Title',
          content: 'Legacy content',
          updatedAt: DateTime.parse('2023-12-01T10:00:00.000Z'),
          versions: [],
        );

        // Setup: Simulate legacy document storage
        SharedPreferences.setMockInitialValues({
          'markdown.currentDoc': jsonEncode(legacyDoc.toJson()),
        });

        final loaded = await localStore.load();

        expect(loaded.id, equals('legacy-doc'));
        expect(loaded.title, equals('Legacy Title'));

        // Verify it was migrated to new storage
        final docs = await localStore.list();
        expect(docs, hasLength(1));
        expect(docs[0].id, equals('legacy-doc'));
      });

      test('should fallback to starter when currentId points to non-existent doc', () async {
        // Setup: Set current ID to non-existent document
        SharedPreferences.setMockInitialValues({
          'markdown.currentDocId': 'non-existent-id',
        });

        final loaded = await localStore.load();

        expect(loaded.title, equals('Welcome'));
        expect(loaded.content, contains('# Welcome to Markdown Editor'));
      });
    });

    group('Document List Management', () {
      test('should return empty list when no documents exist', () async {
        final docs = await localStore.list();
        expect(docs, isEmpty);
      });

      test('should return all documents ordered by update time', () async {
        final now = DateTime.now();
        final doc1 = MdDocument(
          id: 'doc-1',
          title: 'First Document',
          content: 'Content 1',
          updatedAt: now.subtract(const Duration(hours: 2)),
          versions: [],
        );
        final doc2 = MdDocument(
          id: 'doc-2',
          title: 'Second Document',
          content: 'Content 2',
          updatedAt: now.subtract(const Duration(hours: 1)),
          versions: [],
        );
        final doc3 = MdDocument(
          id: 'doc-3',
          title: 'Third Document',
          content: 'Content 3',
          updatedAt: now,
          versions: [],
        );

        await localStore.save(doc1);
        await localStore.save(doc2);
        await localStore.save(doc3);

        final docs = await localStore.list();

        expect(docs, hasLength(3));
        // Should be ordered by updatedAt desc (most recent first)
        expect(docs[0].id, equals('doc-3')); // most recent
        expect(docs[1].id, equals('doc-2')); // middle
        expect(docs[2].id, equals('doc-1')); // oldest
      });

      test('should handle corrupted document data gracefully', () async {
        // Setup: Insert corrupted JSON data
        SharedPreferences.setMockInitialValues({
          'markdown.docs': '{"corrupted": json}',
        });

        final docs = await localStore.list();

        expect(docs, isEmpty);

        // Verify corrupted data was cleared
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('markdown.docs'), isNull);
      });

      test('should handle empty JSON string', () async {
        SharedPreferences.setMockInitialValues({
          'markdown.docs': '',
        });

        final docs = await localStore.list();
        expect(docs, isEmpty);
      });

      test('should handle null storage value', () async {
        SharedPreferences.setMockInitialValues({});

        final docs = await localStore.list();
        expect(docs, isEmpty);
      });
    });

    group('Document Finding', () {
      test('should find document by id from document list', () async {
        final testDoc = MdDocument(
          id: 'findable-doc',
          title: 'Findable Document',
          content: 'Content to find',
          updatedAt: DateTime.now(),
          versions: [],
        );
        await localStore.save(testDoc);

        final found = await localStore.findById('findable-doc');

        expect(found, isNotNull);
        expect(found!.id, equals('findable-doc'));
        expect(found.title, equals('Findable Document'));
      });

      test('should find document by id from legacy storage', () async {
        final legacyDoc = MdDocument(
          id: 'legacy-find-doc',
          title: 'Legacy Find Document',
          content: 'Legacy content',
          updatedAt: DateTime.now(),
          versions: [],
        );

        SharedPreferences.setMockInitialValues({
          'markdown.currentDoc': jsonEncode(legacyDoc.toJson()),
        });

        final found = await localStore.findById('legacy-find-doc');

        expect(found, isNotNull);
        expect(found!.id, equals('legacy-find-doc'));
        expect(found.title, equals('Legacy Find Document'));
      });

      test('should return null when document not found', () async {
        final found = await localStore.findById('non-existent-doc');
        expect(found, isNull);
      });

      test('should prioritize document list over legacy storage', () async {
        // Setup: Same ID in both storages
        final newDoc = MdDocument(
          id: 'same-id',
          title: 'New Document',
          content: 'New content',
          updatedAt: DateTime.now(),
          versions: [],
        );

        final legacyDoc = MdDocument(
          id: 'same-id',
          title: 'Legacy Document',
          content: 'Legacy content',
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          versions: [],
        );

        await localStore.save(newDoc);

        SharedPreferences.setMockInitialValues({
          'markdown.docs': jsonEncode([newDoc.toJson()]),
          'markdown.currentDoc': jsonEncode(legacyDoc.toJson()),
          'markdown.currentDocId': 'same-id',
        });

        final found = await localStore.findById('same-id');

        expect(found, isNotNull);
        expect(found!.title, equals('New Document')); // Should find new, not legacy
      });
    });

    group('Document Saving', () {
      test('should save new document and mark as current', () async {
        final testDoc = MdDocument(
          id: 'new-save-doc',
          title: 'New Save Document',
          content: 'Save content',
          updatedAt: DateTime.now(),
          versions: [],
        );

        await localStore.save(testDoc);

        final docs = await localStore.list();
        expect(docs, hasLength(1));
        expect(docs[0].id, equals('new-save-doc'));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('markdown.currentDocId'), equals('new-save-doc'));
      });

      test('should update existing document in place', () async {
        final originalDoc = MdDocument(
          id: 'update-doc',
          title: 'Original Title',
          content: 'Original content',
          updatedAt: DateTime.now(),
          versions: [],
        );
        await localStore.save(originalDoc);

        final updatedDoc = MdDocument(
          id: 'update-doc', // Same ID
          title: 'Updated Title',
          content: 'Updated content',
          updatedAt: DateTime.now().add(const Duration(minutes: 1)),
          versions: [],
        );
        await localStore.save(updatedDoc);

        final docs = await localStore.list();
        expect(docs, hasLength(1)); // Should still be only 1 document
        expect(docs[0].title, equals('Updated Title'));
        expect(docs[0].content, equals('Updated content'));
      });

      test('should maintain legacy storage compatibility', () async {
        final testDoc = MdDocument(
          id: 'legacy-compat',
          title: 'Legacy Compatible',
          content: 'Legacy content',
          updatedAt: DateTime.now(),
          versions: [],
        );

        await localStore.save(testDoc);

        final prefs = await SharedPreferences.getInstance();
        final legacyJson = prefs.getString('markdown.currentDoc');
        expect(legacyJson, isNotNull);

        final parsed = MdDocument.fromJson(
          jsonDecode(legacyJson!) as Map<String, dynamic>,
        );
        expect(parsed.id, equals('legacy-compat'));
        expect(parsed.title, equals('Legacy Compatible'));
      });

      test('should cap version history at maximum', () async {
        final versions = List.generate(25, (i) => MdVersion(
          id: 'v$i',
          createdAt: DateTime.now().subtract(Duration(minutes: i)),
          content: 'Version $i content',
        ));

        final docWithManyVersions = MdDocument(
          id: 'version-capped-doc',
          title: 'Version Capped',
          content: 'Current content',
          updatedAt: DateTime.now(),
          versions: versions,
        );

        await localStore.save(docWithManyVersions);

        final saved = await localStore.findById('version-capped-doc');
        expect(saved, isNotNull);
        expect(saved!.versions, hasLength(20)); // Should be capped at 20

        // Should keep the most recent 20 versions
        expect(saved.versions[0].id, equals('v5')); // 25-20 = 5, so starts from v5
        expect(saved.versions[19].id, equals('v24')); // Last one should be v24
      });
    });

    group('Document Creation', () {
      test('should create new document with unique ID and default title', () async {
        final newDoc = await localStore.createNew();

        expect(newDoc.id, startsWith('local-'));
        expect(newDoc.title, equals('Untitled'));
        expect(newDoc.content, equals(''));
        expect(newDoc.versions, hasLength(1));
        expect(newDoc.versions[0].content, equals(''));
      });

      test('should create new document with custom title', () async {
        final newDoc = await localStore.createNew(title: 'Custom Title');

        expect(newDoc.title, equals('Custom Title'));
        expect(newDoc.content, equals(''));
      });

      test('should trim and handle empty title', () async {
        final newDoc1 = await localStore.createNew(title: '   ');
        expect(newDoc1.title, equals('Untitled'));

        final newDoc2 = await localStore.createNew(title: '  Custom  ');
        expect(newDoc2.title, equals('Custom'));
      });

      test('should set new document as current', () async {
        final newDoc = await localStore.createNew(title: 'New Current');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('markdown.currentDocId'), equals(newDoc.id));

        final legacyJson = prefs.getString('markdown.currentDoc');
        expect(legacyJson, isNotNull);
        final legacy = MdDocument.fromJson(
          jsonDecode(legacyJson!) as Map<String, dynamic>,
        );
        expect(legacy.id, equals(newDoc.id));
      });

      test('should generate unique IDs for multiple documents', () async {
        final doc1 = await localStore.createNew();
        final doc2 = await localStore.createNew();
        final doc3 = await localStore.createNew();

        expect(doc1.id, isNot(equals(doc2.id)));
        expect(doc2.id, isNot(equals(doc3.id)));
        expect(doc1.id, isNot(equals(doc3.id)));

        expect(doc1.id, startsWith('local-'));
        expect(doc2.id, startsWith('local-'));
        expect(doc3.id, startsWith('local-'));
      });
    });

    group('Version Snapshotting', () {
      test('should create snapshot with current content', () async {
        final originalDoc = MdDocument(
          id: 'snapshot-doc',
          title: 'Snapshot Test',
          content: 'Original content',
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          versions: [
            MdVersion(
              id: 'v1',
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
              content: 'Initial content',
            ),
          ],
        );

        originalDoc.content = 'Updated content for snapshot';

        final snapshotted = await localStore.snapshot(originalDoc);

        expect(snapshotted.versions, hasLength(2));
        expect(snapshotted.versions[0].content, equals('Initial content'));
        expect(snapshotted.versions[1].content, equals('Updated content for snapshot'));
        expect(snapshotted.updatedAt.isAfter(originalDoc.updatedAt), isTrue);
      });

      test('should limit versions when snapshotting', () async {
        final versions = List.generate(20, (i) => MdVersion(
          id: 'v$i',
          createdAt: DateTime.now().subtract(Duration(minutes: i)),
          content: 'Version $i content',
        ));

        final docWithMaxVersions = MdDocument(
          id: 'max-versions-doc',
          title: 'Max Versions',
          content: 'Current content',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          versions: versions,
        );

        final snapshotted = await localStore.snapshot(docWithMaxVersions);

        expect(snapshotted.versions, hasLength(20)); // Should still be 20

        // First version should be removed, new one added
        expect(snapshotted.versions[0].id, equals('v1')); // v0 should be removed
        expect(snapshotted.versions[18].id, equals('v19')); // v19 still there
        expect(snapshotted.versions[19].content, equals('Current content')); // New snapshot
      });

      test('should persist snapshotted document', () async {
        final doc = MdDocument(
          id: 'persist-snapshot-doc',
          title: 'Persist Snapshot',
          content: 'Content to snapshot',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          versions: [],
        );

        await localStore.snapshot(doc);

        final found = await localStore.findById('persist-snapshot-doc');
        expect(found, isNotNull);
        expect(found!.versions, hasLength(1));
        expect(found.versions[0].content, equals('Content to snapshot'));
      });

      test('should generate unique version IDs', () async {
        final doc = MdDocument(
          id: 'unique-version-doc',
          title: 'Unique Versions',
          content: 'Content 1',
          updatedAt: DateTime.now(),
          versions: [],
        );

        final snapshot1 = await localStore.snapshot(doc);

        doc.content = 'Content 2';
        final snapshot2 = await localStore.snapshot(doc);

        expect(snapshot1.versions[0].id, isNot(equals(snapshot2.versions[1].id)));
        expect(snapshot2.versions[0].id, startsWith('v_'));
        expect(snapshot2.versions[1].id, startsWith('v_'));
      });
    });

    group('Legacy Support', () {
      test('should clear legacy storage', () async {
        SharedPreferences.setMockInitialValues({
          'markdown.currentDoc': '{"some": "data"}',
        });

        await localStore.clear();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('markdown.currentDoc'), isNull);
      });

      test('should handle missing legacy data gracefully', () async {
        // No exception should be thrown
        await localStore.clear();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('markdown.currentDoc'), isNull);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle malformed JSON in legacy storage', () async {
        SharedPreferences.setMockInitialValues({
          'markdown.currentDoc': 'malformed-json{',
        });

        expect(() => localStore.load(), returnsNormally);

        final loaded = await localStore.load();
        expect(loaded.title, equals('Welcome')); // Should fallback to starter
      });

      test('should handle empty string in storage', () async {
        SharedPreferences.setMockInitialValues({
          'markdown.docs': '',
          'markdown.currentDoc': '',
        });

        final docs = await localStore.list();
        expect(docs, isEmpty);

        final loaded = await localStore.load();
        expect(loaded.title, equals('Welcome')); // Should create starter
      });

      test('should handle concurrent saves gracefully', () async {
        final doc1 = MdDocument(
          id: 'concurrent-1',
          title: 'Concurrent 1',
          content: 'Content 1',
          updatedAt: DateTime.now(),
          versions: [],
        );

        final doc2 = MdDocument(
          id: 'concurrent-2',
          title: 'Concurrent 2',
          content: 'Content 2',
          updatedAt: DateTime.now(),
          versions: [],
        );

        // Save multiple documents simultaneously
        await Future.wait([
          localStore.save(doc1),
          localStore.save(doc2),
        ]);

        final docs = await localStore.list();
        expect(docs, hasLength(2));

        final ids = docs.map((d) => d.id).toList();
        expect(ids, contains('concurrent-1'));
        expect(ids, contains('concurrent-2'));
      });
    });
  });
}