import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/services/writing_stats_service.dart';
import 'package:markflow/features/markdown/models/writing_session.dart';

void main() {
  group('WritingStatsService', () {
    test('should calculate basic statistics correctly', () {
      const text = '''# Hello World

This is a **test document** with *some* formatting.

It has multiple paragraphs and sentences. This is the second sentence.

- List item 1
- List item 2

1. Numbered item
2. Another item

```dart
void main() {
  print("Hello, World!");
}
```

Here's a [link](https://example.com) and an image: ![alt](image.jpg)

`inline code` is also supported.
''';

      final stats = WritingStatsService.calculateStats(text);

      expect(stats.wordCount, greaterThan(0));
      expect(stats.characterCount, equals(text.length));
      expect(stats.characterCountNoSpaces, lessThan(stats.characterCount));
      expect(stats.paragraphCount, greaterThan(1));
      expect(stats.sentenceCount, greaterThan(1));
      expect(stats.readingTimeMinutes, greaterThan(0));
    });

    test('should handle markdown elements correctly', () {
      const text = '''# Heading 1
## Heading 2
### Heading 3

This text has **bold** and *italic* formatting.

Here's a [link](https://example.com) and ![image](test.jpg).

```javascript
console.log("Hello");
```

- List item
- Another item

1. Numbered
2. List

`inline code`
''';

      final stats = WritingStatsService.calculateStats(text);

      expect(stats.markdownStats.headingCount, equals(3));
      expect(stats.markdownStats.headingLevels[1], equals(1));
      expect(stats.markdownStats.headingLevels[2], equals(1));
      expect(stats.markdownStats.headingLevels[3], equals(1));
      expect(stats.markdownStats.linkCount, equals(1));
      expect(stats.markdownStats.imageCount, equals(1));
      expect(stats.markdownStats.codeBlockCount, equals(1));
      expect(stats.markdownStats.inlineCodeCount, equals(1));
      expect(stats.markdownStats.boldCount, equals(1));
      expect(stats.markdownStats.italicCount, equals(1));
      expect(stats.markdownStats.listItemCount, equals(2));
      expect(stats.markdownStats.numberedListItemCount, equals(2));
    });

    test('should handle empty text', () {
      final stats = WritingStatsService.calculateStats('');

      expect(stats.wordCount, equals(0));
      expect(stats.characterCount, equals(0));
      expect(stats.paragraphCount, equals(0));
      expect(stats.sentenceCount, equals(0));
      expect(stats.readingTimeMinutes, equals(0));
    });

    test('should calculate words per minute correctly', () {
      const wordCount = 120;
      const duration = Duration(minutes: 2);

      final wpm = WritingStatsService.calculateWPM(wordCount, duration);

      expect(wpm, equals(60.0));
    });

    test('should return zero WPM for zero duration', () {
      const wordCount = 120;
      const duration = Duration.zero;

      final wpm = WritingStatsService.calculateWPM(wordCount, duration);

      expect(wpm, equals(0.0));
    });

    test('should categorize reading difficulty correctly', () {
      expect(WritingStatsService.getReadingDifficulty(95), equals('Very Easy'));
      expect(WritingStatsService.getReadingDifficulty(85), equals('Easy'));
      expect(WritingStatsService.getReadingDifficulty(75), equals('Fairly Easy'));
      expect(WritingStatsService.getReadingDifficulty(65), equals('Standard'));
      expect(WritingStatsService.getReadingDifficulty(55), equals('Fairly Difficult'));
      expect(WritingStatsService.getReadingDifficulty(40), equals('Difficult'));
      expect(WritingStatsService.getReadingDifficulty(20), equals('Very Difficult'));
    });

    test('should count words accurately excluding markdown syntax', () {
      const text = '''# Heading with **bold** text

This is a paragraph with [link](url) and `code`.

```
This is a code block that should not count words
```

- List item one
- List item two
''';

      final stats = WritingStatsService.calculateStats(text);

      // Should count actual words, not markdown syntax
      expect(stats.wordCount, greaterThan(0));
      expect(stats.wordCount, lessThan(30)); // Approximate expected count
    });
  });

  group('WritingSession', () {
    test('should create session with correct initial values', () {
      final session = WritingSession(
        id: 'test-session',
        documentId: 'doc-1',
        startTime: DateTime.now(),
        initialWordCount: 100,
        currentWordCount: 150,
      );

      expect(session.id, equals('test-session'));
      expect(session.documentId, equals('doc-1'));
      expect(session.wordsAdded, equals(50));
      expect(session.isActive, isTrue);
    });

    test('should calculate WPM correctly', () {
      final startTime = DateTime.now();
      final session = WritingSession(
        id: 'test',
        documentId: 'doc',
        startTime: startTime,
        initialWordCount: 0,
        currentWordCount: 60,
        activeDuration: const Duration(minutes: 1),
      );

      expect(session.wordsPerMinute, equals(60.0));
    });

    test('should calculate efficiency correctly', () {
      final session = WritingSession(
        id: 'test',
        documentId: 'doc',
        startTime: DateTime.now(),
        activeDuration: const Duration(minutes: 30),
        totalDuration: const Duration(minutes: 60),
      );

      expect(session.efficiency, equals(0.5));
    });

    test('should update metrics correctly', () {
      final originalSession = WritingSession(
        id: 'test',
        documentId: 'doc',
        startTime: DateTime.now(),
        currentWordCount: 100,
        totalCharactersTyped: 500,
      );

      final updatedSession = originalSession.updateMetrics(
        wordCount: 150,
        additionalCharacters: 250,
        additionalActiveTime: const Duration(minutes: 5),
      );

      expect(updatedSession.currentWordCount, equals(150));
      expect(updatedSession.totalCharactersTyped, equals(750));
      expect(updatedSession.activeDuration, equals(const Duration(minutes: 5)));
    });

    test('should end session correctly', () {
      final session = WritingSession(
        id: 'test',
        documentId: 'doc',
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        currentWordCount: 200,
      );

      final endedSession = session.endSession();

      expect(endedSession.isActive, isFalse);
      expect(endedSession.endTime, isNotNull);
      expect(endedSession.totalDuration.inMinutes, greaterThanOrEqualTo(30));
    });

    test('should serialize and deserialize correctly', () {
      final originalSession = WritingSession(
        id: 'test-session',
        documentId: 'doc-1',
        startTime: DateTime.parse('2024-01-01T12:00:00'),
        endTime: DateTime.parse('2024-01-01T13:00:00'),
        initialWordCount: 100,
        currentWordCount: 200,
        totalCharactersTyped: 1000,
        activeDuration: const Duration(minutes: 45),
        totalDuration: const Duration(minutes: 60),
        snapshots: [
          WritingSnapshot(
            timestamp: DateTime.parse('2024-01-01T12:30:00'),
            wordCount: 150,
            characterCount: 750,
            contentPreview: 'Test content preview',
          ),
        ],
      );

      final json = originalSession.toJson();
      final deserializedSession = WritingSession.fromJson(json);

      expect(deserializedSession.id, equals(originalSession.id));
      expect(deserializedSession.documentId, equals(originalSession.documentId));
      expect(deserializedSession.startTime, equals(originalSession.startTime));
      expect(deserializedSession.endTime, equals(originalSession.endTime));
      expect(deserializedSession.initialWordCount, equals(originalSession.initialWordCount));
      expect(deserializedSession.currentWordCount, equals(originalSession.currentWordCount));
      expect(deserializedSession.totalCharactersTyped, equals(originalSession.totalCharactersTyped));
      expect(deserializedSession.activeDuration, equals(originalSession.activeDuration));
      expect(deserializedSession.totalDuration, equals(originalSession.totalDuration));
      expect(deserializedSession.snapshots.length, equals(1));
    });
  });

  group('WritingGoal', () {
    test('should calculate progress correctly', () {
      final goal = WritingGoal(
        id: 'goal-1',
        title: 'Write 1000 words',
        type: WritingGoalType.words,
        targetValue: 1000,
        createdAt: DateTime.now(),
      );

      expect(goal.calculateProgress(500), equals(0.5));
      expect(goal.calculateProgress(1000), equals(1.0));
      expect(goal.calculateProgress(1500), equals(1.0)); // Clamped to 1.0
      expect(goal.calculateProgress(0), equals(0.0));
    });

    test('should detect due dates correctly', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));

      final goalDueToday = WritingGoal(
        id: 'goal-1',
        title: 'Goal due today',
        type: WritingGoalType.words,
        targetValue: 500,
        createdAt: today,
        deadline: today,
      );

      final goalDueTomorrow = WritingGoal(
        id: 'goal-2',
        title: 'Goal due tomorrow',
        type: WritingGoalType.words,
        targetValue: 500,
        createdAt: today,
        deadline: tomorrow,
      );

      final overDueGoal = WritingGoal(
        id: 'goal-3',
        title: 'Overdue goal',
        type: WritingGoalType.words,
        targetValue: 500,
        createdAt: yesterday,
        deadline: yesterday,
      );

      expect(goalDueToday.isDueToday, isTrue);
      expect(goalDueTomorrow.isDueToday, isFalse);
      expect(overDueGoal.isOverdue, isTrue);
      expect(goalDueToday.isOverdue, isFalse);
    });

    test('should mark goal as completed', () {
      final goal = WritingGoal(
        id: 'goal-1',
        title: 'Test goal',
        type: WritingGoalType.words,
        targetValue: 500,
        createdAt: DateTime.now(),
      );

      final completedGoal = goal.complete();

      expect(completedGoal.isCompleted, isTrue);
      expect(completedGoal.completedAt, isNotNull);
      expect(completedGoal.id, equals(goal.id));
      expect(completedGoal.title, equals(goal.title));
    });

    test('should serialize and deserialize correctly', () {
      final originalGoal = WritingGoal(
        id: 'goal-1',
        title: 'Test Goal',
        type: WritingGoalType.words,
        targetValue: 1000,
        createdAt: DateTime.parse('2024-01-01T12:00:00'),
        deadline: DateTime.parse('2024-01-07T23:59:59'),
        isCompleted: false,
        metadata: {'category': 'daily'},
      );

      final json = originalGoal.toJson();
      final deserializedGoal = WritingGoal.fromJson(json);

      expect(deserializedGoal.id, equals(originalGoal.id));
      expect(deserializedGoal.title, equals(originalGoal.title));
      expect(deserializedGoal.type, equals(originalGoal.type));
      expect(deserializedGoal.targetValue, equals(originalGoal.targetValue));
      expect(deserializedGoal.createdAt, equals(originalGoal.createdAt));
      expect(deserializedGoal.deadline, equals(originalGoal.deadline));
      expect(deserializedGoal.isCompleted, equals(originalGoal.isCompleted));
      expect(deserializedGoal.metadata, equals(originalGoal.metadata));
    });
  });

  group('DailyStats', () {
    test('should calculate average WPM correctly', () {
      final stats = DailyStats(
        date: DateTime.now(),
        wordsWritten: 120,
        charactersTyped: 600,
        timeSpent: const Duration(minutes: 2),
        sessionsCount: 1,
        documentsWorkedOn: ['doc-1'],
      );

      expect(stats.averageWPM, equals(60.0));
    });

    test('should format time correctly', () {
      final stats1 = DailyStats(
        date: DateTime.now(),
        wordsWritten: 100,
        charactersTyped: 500,
        timeSpent: const Duration(minutes: 45),
        sessionsCount: 1,
        documentsWorkedOn: ['doc-1'],
      );

      final stats2 = DailyStats(
        date: DateTime.now(),
        wordsWritten: 100,
        charactersTyped: 500,
        timeSpent: const Duration(hours: 2, minutes: 30),
        sessionsCount: 1,
        documentsWorkedOn: ['doc-1'],
      );

      expect(stats1.formattedTimeSpent, equals('45m'));
      expect(stats2.formattedTimeSpent, equals('2h 30m'));
    });

    test('should serialize and deserialize correctly', () {
      final originalStats = DailyStats(
        date: DateTime.parse('2024-01-01'),
        wordsWritten: 500,
        charactersTyped: 2500,
        timeSpent: const Duration(minutes: 60),
        sessionsCount: 2,
        documentsWorkedOn: ['doc-1', 'doc-2'],
      );

      final json = originalStats.toJson();
      final deserializedStats = DailyStats.fromJson(json);

      expect(deserializedStats.date, equals(originalStats.date));
      expect(deserializedStats.wordsWritten, equals(originalStats.wordsWritten));
      expect(deserializedStats.charactersTyped, equals(originalStats.charactersTyped));
      expect(deserializedStats.timeSpent, equals(originalStats.timeSpent));
      expect(deserializedStats.sessionsCount, equals(originalStats.sessionsCount));
      expect(deserializedStats.documentsWorkedOn, equals(originalStats.documentsWorkedOn));
    });
  });

  group('Complex Statistics Scenarios', () {
    test('should handle mixed content correctly', () {
      const text = '''
# My Writing Project

This document contains various **markdown elements** that should be *properly analyzed*.

## Introduction

Writing statistics are important for tracking progress. Here's why:

1. **Word count tracking** - helps monitor daily goals
2. **Reading time estimation** - useful for content planning
3. **Complexity analysis** - ensures readability

### Technical Details

```dart
// Code blocks should be handled properly
class WritingStats {
  int wordCount;
  Duration readingTime;

  WritingStats(this.wordCount, this.readingTime);
}
```

The above code demonstrates a simple `WritingStats` class.

## Links and Media

Check out this [writing guide](https://example.com/guide) for more tips.

![Writing workflow](images/workflow.png)

## Conclusion

This document has multiple paragraphs. Each paragraph contains several sentences. Some sentences are longer than others, which affects readability metrics.

> Blockquotes like this one add variety to the text structure.

### Final Thoughts

- Keep writing consistently
- Track your progress
- Set achievable goals

That's all for now!
''';

      final stats = WritingStatsService.calculateStats(text);

      // Verify comprehensive analysis
      expect(stats.wordCount, greaterThan(50));
      expect(stats.paragraphCount, greaterThan(5));
      expect(stats.sentenceCount, greaterThan(10));
      expect(stats.readingTimeMinutes, greaterThan(0));

      // Verify markdown elements
      expect(stats.markdownStats.headingCount, equals(4));
      expect(stats.markdownStats.codeBlockCount, equals(1));
      expect(stats.markdownStats.linkCount, equals(1));
      expect(stats.markdownStats.imageCount, equals(1));
      expect(stats.markdownStats.listItemCount, equals(3));
      expect(stats.markdownStats.numberedListItemCount, equals(3));

      // Verify complexity metrics
      expect(stats.complexityMetrics.averageWordsPerSentence, greaterThan(0));
      expect(stats.complexityMetrics.readingEaseScore, greaterThan(0));
      expect(stats.complexityMetrics.gradeLevel, greaterThan(0));
    });
  });
}