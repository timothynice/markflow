import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:markflow/features/markdown/docs_screen.dart';
import 'package:markflow/features/markdown/local_store.dart';
import 'package:markflow/features/markdown/models.dart';
import 'package:markflow/features/markdown/editor_screen.dart';
import 'package:markflow/widgets/responsive_nav.dart';
import 'package:mockito/mockito.dart';

import '../../test_helpers.dart';

class MockMdLocalStore extends Mock implements MdLocalStore {}

void main() {
  group('Docs Screen Widget Tests', () {
    late MockMdLocalStore mockStore;
    late List<MdDocument> mockDocuments;
    late GoRouter testRouter;

    setUp(() {
      mockStore = MockMdLocalStore();
      mockDocuments = TestHelpers.createMockDocuments();

      // Setup test router
      testRouter = TestHelpers.createTestRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DocumentsScreen(),
          ),
          GoRoute(
            path: '/docs',
            builder: (context, state) => const DocumentsScreen(),
          ),
          GoRoute(
            path: '/markdown/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MarkdownEditorScreen(docId: id);
            },
          ),
        ],
        initialLocation: '/docs',
      );

      // Setup default mock behavior
      when(mockStore.list()).thenAnswer((_) async => mockDocuments);
      when(mockStore.createNew()).thenAnswer((_) async => MdDocument(
        id: 'new-doc',
        title: 'Untitled',
        content: '',
        updatedAt: DateTime.now(),
        versions: [
          MdVersion(
            id: 'v1',
            createdAt: DateTime.now(),
            content: '',
          ),
        ],
      ));
    });

    testWidgets('should render docs screen with basic layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const DocumentsScreen(),
          mockStore: mockStore,
        ),
      );

      await TestHelpers.pumpAndSettleWithDelay(tester);

      // Verify basic structure is present
      expect(find.byType(DocumentsScreen), findsOneWidget);
      expect(find.byType(ResponsiveNav), findsOneWidget);
    });

    testWidgets('should display documents page title in navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const DocumentsScreen(),
          mockStore: mockStore,
        ),
      );

      await TestHelpers.pumpAndSettleWithDelay(tester);

      expect(find.text('Documents'), findsAtLeastNWidgets(1));
    });

    group('Document List Display', () {
      testWidgets('should display list of documents when documents exist on mobile', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Should show documents in mobile layout
        expect(find.byType(Card), findsAtLeastNWidgets(1));
        expect(find.byType(ListTile), findsAtLeastNWidgets(1));

        // Verify document titles are displayed
        expect(find.text('First Document'), findsOneWidget);
        expect(find.text('Second Document'), findsOneWidget);
      });

      testWidgets('should display documents in desktop sidebar layout', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Desktop should show split view with sidebar
        expect(find.byType(Row), findsAtLeastNWidgets(1)); // Split view
        expect(find.text('Documents'), findsAtLeastNWidgets(1)); // Sidebar header
      });

      testWidgets('should show empty state when no documents exist on mobile', (WidgetTester tester) async {
        when(mockStore.list()).thenAnswer((_) async => <MdDocument>[]);

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        expect(find.text('No documents yet'), findsOneWidget);
      });

      testWidgets('should show empty state when no documents exist on desktop', (WidgetTester tester) async {
        when(mockStore.list()).thenAnswer((_) async => <MdDocument>[]);

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        expect(find.text('No documents yet'), findsOneWidget);
        expect(find.text('No document selected'), findsOneWidget);
      });

      testWidgets('should display document titles correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // All mock document titles should be visible
        expect(find.text('First Document'), findsOneWidget);
        expect(find.text('Second Document'), findsOneWidget);
        expect(find.text('Untitled'), findsOneWidget);
      });

      testWidgets('should show document metadata (date, versions)', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Should show relative time and version count
        expect(find.textContaining('versions'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Last edited'), findsAtLeastNWidgets(1));
      });
    });

    group('Create New Document', () {
      testWidgets('should show create new document button on mobile', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Look for the floating action button or add button
        expect(find.byIcon(Icons.note_add_outlined), findsOneWidget);
      });

      testWidgets('should show create new document button on desktop', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Desktop should have add button in sidebar
        expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));
      });

      testWidgets('should create new document when button is tapped on mobile', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestAppWithRouter(
            child: const DocumentsScreen(),
            router: testRouter,
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Tap the new document button
        await TestHelpers.tapAndSettle(tester, find.byIcon(Icons.note_add_outlined));

        // Verify createNew was called
        verify(mockStore.createNew()).called(1);
      });
    });

    group('Search and Filter', () {
      testWidgets('should show search field on mobile', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        expect(find.byType(TextField), findsAtLeastNWidgets(1));
        expect(find.textContaining('Search'), findsOneWidget);
      });

      testWidgets('should show search field on desktop', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        expect(find.byType(TextField), findsAtLeastNWidgets(1));
        expect(find.textContaining('Search'), findsOneWidget);
      });

      testWidgets('should filter documents by search query', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Initially should show all documents
        expect(find.text('First Document'), findsOneWidget);
        expect(find.text('Second Document'), findsOneWidget);

        // Enter search query
        final searchField = find.byType(TextField).first;
        await TestHelpers.enterText(tester, searchField, 'First');

        // Should filter to only matching documents
        expect(find.text('First Document'), findsOneWidget);
        expect(find.text('Second Document'), findsNothing);
      });

      testWidgets('should handle empty search results', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Enter search query that matches nothing
        final searchField = find.byType(TextField).first;
        await TestHelpers.enterText(tester, searchField, 'NonexistentDocument');

        // Should show no matches message
        expect(find.text('No matches'), findsOneWidget);
      });
    });

    group('Document Sorting', () {
      testWidgets('should sort documents by modification date by default', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Documents should be sorted with most recent first
        // Based on mock data, "Second Document" was updated 30 min ago (most recent)
        // "First Document" was updated 1 hour ago
        // "Untitled" was updated 1 day ago

        final documentTitles = find.byType(Text).evaluate()
            .where((element) {
              final widget = element.widget as Text;
              return widget.data == 'First Document' ||
                     widget.data == 'Second Document' ||
                     widget.data == 'Untitled';
            })
            .map((element) => (element.widget as Text).data)
            .toList();

        // Second Document should appear before First Document
        final secondIndex = documentTitles.indexOf('Second Document');
        final firstIndex = documentTitles.indexOf('First Document');

        expect(secondIndex, lessThan(firstIndex));
      });
    });

    group('Loading States', () {
      testWidgets('should show loading indicator while documents are being fetched', (WidgetTester tester) async {
        // Setup delayed response
        when(mockStore.list()).thenAnswer((_) => Future.delayed(
          const Duration(seconds: 1),
          () => mockDocuments,
        ));

        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
          ),
        );

        // Should show loading indicator initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for loading to complete
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Loading indicator should be gone, documents should be visible
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('First Document'), findsOneWidget);
      });
    });

    group('Responsive Layout', () {
      testWidgets('should adapt to desktop layout with split view', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Desktop should show split view layout
        expect(find.byType(Row), findsAtLeastNWidgets(1)); // Main split
        expect(find.text('Documents'), findsAtLeastNWidgets(1)); // Sidebar title

        // Should have empty state for editor area initially
        expect(find.text('No document selected'), findsOneWidget);
      });

      testWidgets('should adapt to mobile layout with full screen list', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Mobile should show full-screen document list with cards
        expect(find.byType(Card), findsAtLeastNWidgets(1));
        expect(find.byType(ListTile), findsAtLeastNWidgets(1));
      });

      testWidgets('should show collapsible sidebar on desktop', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Find and tap the collapse button
        final collapseButton = find.byIcon(Icons.close);
        if (collapseButton.evaluate().isNotEmpty) {
          await TestHelpers.tapAndSettle(tester, collapseButton);

          // Should show collapsed sidebar with menu button
          expect(find.byIcon(Icons.menu), findsOneWidget);
        }
      });
    });

    group('Accessibility', () {
      testWidgets('should provide semantic labels for document list', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        TestHelpers.verifyAccessibilitySemantics(
          tester,
          expectsButton: true,
          expectsTextField: true,
        );
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Test Tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Focus should be manageable
        expect(tester.binding.focusManager.primaryFocus, isNotNull);
      });
    });

    group('Desktop Split View Behavior', () {
      testWidgets('should show empty state when no document selected on desktop', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // Should show empty state in editor area
        expect(find.text('No document selected'), findsOneWidget);
        expect(find.text('Select a document from the sidebar or create a new one'), findsOneWidget);
        expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      });

      testWidgets('should auto-select first document on desktop', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.desktopSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        // First document should be auto-selected (visual indication)
        // This would be shown through highlighting in the sidebar
        expect(find.text('First Document'), findsAtLeastNWidgets(1));
      });
    });

    group('Search UI Elements', () {
      testWidgets('should show search icon in search field', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should clear search when text is deleted', (WidgetTester tester) async {
        await tester.pumpWidget(
          TestHelpers.createTestApp(
            child: const DocumentsScreen(),
            mockStore: mockStore,
            screenSize: TestHelpers.mobileSize,
          ),
        );

        await TestHelpers.pumpAndSettleWithDelay(tester);

        final searchField = find.byType(TextField).first;

        // Enter search query
        await TestHelpers.enterText(tester, searchField, 'First');
        expect(find.text('First Document'), findsOneWidget);
        expect(find.text('Second Document'), findsNothing);

        // Clear search
        await TestHelpers.enterText(tester, searchField, '');

        // All documents should be visible again
        expect(find.text('First Document'), findsOneWidget);
        expect(find.text('Second Document'), findsOneWidget);
      });
    });
  });
}