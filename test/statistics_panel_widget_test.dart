import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/widgets/statistics_panel.dart';
import 'package:markflow/features/markdown/services/writing_stats_service.dart';
import 'package:markflow/features/markdown/models/writing_session.dart';

void main() {
  group('StatisticsPanel Widget Tests', () {
    late TextStatistics sampleStats;
    late WritingSession sampleSession;
    late List<WritingGoal> sampleGoals;

    setUp(() {
      sampleStats = const TextStatistics(
        wordCount: 250,
        characterCount: 1250,
        characterCountNoSpaces: 1000,
        paragraphCount: 5,
        sentenceCount: 12,
        totalLines: 20,
        nonEmptyLines: 18,
        readingTimeMinutes: 2,
        markdownStats: MarkdownStatistics(
          headingCount: 3,
          headingLevels: {1: 1, 2: 2},
          linkCount: 2,
          imageCount: 1,
          codeBlockCount: 1,
          inlineCodeCount: 3,
          listItemCount: 5,
          numberedListItemCount: 2,
          boldCount: 4,
          italicCount: 2,
        ),
        complexityMetrics: ComplexityMetrics(
          averageWordsPerSentence: 20.8,
          readingEaseScore: 65.0,
          gradeLevel: 8.5,
        ),
      );

      sampleSession = WritingSession(
        id: 'session-1',
        documentId: 'doc-1',
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        initialWordCount: 100,
        currentWordCount: 250,
        totalCharactersTyped: 750,
        activeDuration: const Duration(minutes: 20),
        totalDuration: const Duration(minutes: 30),
      );

      sampleGoals = [
        WritingGoal(
          id: 'goal-1',
          title: 'Write 500 words today',
          type: WritingGoalType.words,
          targetValue: 500,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
          deadline: DateTime.now().add(const Duration(hours: 16)),
        ),
        WritingGoal(
          id: 'goal-2',
          title: 'Complete 2 documents this week',
          type: WritingGoalType.documents,
          targetValue: 2,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          deadline: DateTime.now().add(const Duration(days: 5)),
        ),
      ];
    });

    Widget createWidget({
      TextStatistics? statistics,
      WritingSession? currentSession,
      List<WritingGoal>? activeGoals,
      bool isExpanded = false,
      bool isMobile = false,
      VoidCallback? onToggle,
      VoidCallback? onGoalTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: StatisticsPanel(
            statistics: statistics ?? sampleStats,
            currentSession: currentSession,
            activeGoals: activeGoals ?? [],
            isExpanded: isExpanded,
            onToggle: onToggle,
            onGoalTap: onGoalTap,
            isMobile: isMobile,
          ),
        ),
      );
    }

    testWidgets('displays basic statistics in compact mode', (tester) async {
      await tester.pumpWidget(createWidget());

      // Check header
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);

      // Check basic stats
      expect(find.text('Words'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('1250'), findsOneWidget);
      expect(find.text('Reading time'), findsOneWidget);
      expect(find.text('2 min'), findsOneWidget);
      expect(find.text('Paragraphs'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays detailed statistics in expanded mode', (tester) async {
      await tester.pumpWidget(createWidget(isExpanded: true));

      // Should show detailed stats
      expect(find.text('Document Stats'), findsOneWidget);
      expect(find.text('Markdown Elements'), findsOneWidget);
      expect(find.text('Text Complexity'), findsOneWidget);

      // Check detailed counts
      expect(find.text('Characters (no spaces)'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('Sentences'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Lines'), findsOneWidget);
      expect(find.text('18/20'), findsOneWidget);

      // Check markdown elements
      expect(find.text('Headings'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Links'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Check complexity metrics
      expect(find.text('Avg words per sentence'), findsOneWidget);
      expect(find.text('20.8'), findsOneWidget);
      expect(find.text('Reading ease'), findsOneWidget);
      expect(find.text('65/100'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
    });

    testWidgets('displays session statistics when session is active', (tester) async {
      await tester.pumpWidget(createWidget(
        currentSession: sampleSession,
        isExpanded: true,
      ));

      expect(find.text('Current Session'), findsOneWidget);
      expect(find.text('Words added'), findsOneWidget);
      expect(find.text('150'), findsOneWidget); // 250 - 100
      expect(find.text('Words per minute'), findsOneWidget);
      expect(find.text('Active time'), findsOneWidget);
      expect(find.text('20m 0s'), findsOneWidget);
    });

    testWidgets('displays goals section when goals are present', (tester) async {
      await tester.pumpWidget(createWidget(
        activeGoals: sampleGoals,
        isExpanded: true,
      ));

      expect(find.text('Goals'), findsOneWidget);
      expect(find.text('Write 500 words today'), findsOneWidget);
      expect(find.text('Complete 2 documents this week'), findsOneWidget);
      expect(find.text('250/500'), findsOneWidget); // Progress for word goal
    });

    testWidgets('calls onToggle when expand button is pressed', (tester) async {
      bool toggleCalled = false;

      await tester.pumpWidget(createWidget(
        onToggle: () => toggleCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(toggleCalled, isTrue);
    });

    testWidgets('calls onGoalTap when manage goals button is pressed', (tester) async {
      bool goalTapCalled = false;

      await tester.pumpWidget(createWidget(
        activeGoals: sampleGoals,
        isExpanded: true,
        onGoalTap: () => goalTapCalled = true,
      ));

      await tester.tap(find.text('Manage'));
      await tester.pump();

      expect(goalTapCalled, isTrue);
    });

    testWidgets('displays mobile layout correctly', (tester) async {
      await tester.pumpWidget(createWidget(isMobile: true));

      // Should show mobile stat cards
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.view_headline), findsOneWidget);

      // Should show handle bar
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('handles empty statistics correctly', (tester) async {
      final emptyStats = TextStatistics.empty();

      await tester.pumpWidget(createWidget(statistics: emptyStats));

      expect(find.text('0'), findsAtLeastNWidget(3)); // Multiple zero values
      expect(find.text('Less than 1 min'), findsOneWidget);
    });

    testWidgets('shows progress bars for goals', (tester) async {
      await tester.pumpWidget(createWidget(
        activeGoals: sampleGoals,
        isExpanded: true,
      ));

      // Should show progress indicators
      expect(find.byType(LinearProgressIndicator), findsAtLeastNWidget(2));
    });

    testWidgets('displays goal deadlines correctly', (tester) async {
      final todayGoal = WritingGoal(
        id: 'today-goal',
        title: 'Goal due today',
        type: WritingGoalType.words,
        targetValue: 500,
        createdAt: DateTime.now(),
        deadline: DateTime.now(),
      );

      final overdueGoal = WritingGoal(
        id: 'overdue-goal',
        title: 'Overdue goal',
        type: WritingGoalType.words,
        targetValue: 500,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(createWidget(
        activeGoals: [todayGoal, overdueGoal],
        isExpanded: true,
      ));

      expect(find.text('Due today'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('displays session efficiency correctly', (tester) async {
      final efficientSession = WritingSession(
        id: 'session',
        documentId: 'doc',
        startTime: DateTime.now().subtract(const Duration(minutes: 60)),
        activeDuration: const Duration(minutes: 45),
        totalDuration: const Duration(minutes: 60),
      );

      await tester.pumpWidget(createWidget(
        currentSession: efficientSession,
        isExpanded: true,
      ));

      expect(find.text('Efficiency'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('truncates long goal lists in compact mode', (tester) async {
      final manyGoals = List.generate(
        5,
        (i) => WritingGoal(
          id: 'goal-$i',
          title: 'Goal $i',
          type: WritingGoalType.words,
          targetValue: 500,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createWidget(
        activeGoals: manyGoals,
        isExpanded: false,
      ));

      // Should only show first 2 goals in compact mode
      expect(find.text('Goal 0'), findsOneWidget);
      expect(find.text('Goal 1'), findsOneWidget);
      expect(find.text('+3 more'), findsOneWidget);
    });
  });
}