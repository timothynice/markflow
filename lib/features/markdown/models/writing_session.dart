import 'dart:convert';

/// Represents a writing session with productivity metrics
class WritingSession {
  final String id;
  final String documentId;
  final DateTime startTime;
  DateTime? endTime;
  int initialWordCount;
  int currentWordCount;
  int totalCharactersTyped;
  Duration activeDuration; // Time actually spent typing
  Duration totalDuration; // Total elapsed time
  List<WritingSnapshot> snapshots;

  WritingSession({
    required this.id,
    required this.documentId,
    required this.startTime,
    this.endTime,
    this.initialWordCount = 0,
    this.currentWordCount = 0,
    this.totalCharactersTyped = 0,
    this.activeDuration = Duration.zero,
    this.totalDuration = Duration.zero,
    List<WritingSnapshot>? snapshots,
  }) : snapshots = snapshots ?? [];

  /// Calculate words per minute during active writing time
  double get wordsPerMinute {
    if (activeDuration.inSeconds == 0) return 0.0;
    final wordsAdded = currentWordCount - initialWordCount;
    return (wordsAdded * 60.0) / activeDuration.inSeconds;
  }

  /// Calculate characters per minute during active writing time
  double get charactersPerMinute {
    if (activeDuration.inSeconds == 0) return 0.0;
    return (totalCharactersTyped * 60.0) / activeDuration.inSeconds;
  }

  /// Get words added during this session
  int get wordsAdded => currentWordCount - initialWordCount;

  /// Get writing efficiency (active time vs total time)
  double get efficiency {
    if (totalDuration.inSeconds == 0) return 0.0;
    return activeDuration.inSeconds / totalDuration.inSeconds;
  }

  /// Check if session is currently active
  bool get isActive => endTime == null;

  /// End the writing session
  WritingSession endSession() {
    return WritingSession(
      id: id,
      documentId: documentId,
      startTime: startTime,
      endTime: DateTime.now(),
      initialWordCount: initialWordCount,
      currentWordCount: currentWordCount,
      totalCharactersTyped: totalCharactersTyped,
      activeDuration: activeDuration,
      totalDuration: DateTime.now().difference(startTime),
      snapshots: snapshots,
    );
  }

  /// Add a snapshot of the current writing state
  WritingSession addSnapshot(WritingSnapshot snapshot) {
    return WritingSession(
      id: id,
      documentId: documentId,
      startTime: startTime,
      endTime: endTime,
      initialWordCount: initialWordCount,
      currentWordCount: snapshot.wordCount,
      totalCharactersTyped: totalCharactersTyped,
      activeDuration: activeDuration,
      totalDuration: totalDuration,
      snapshots: [...snapshots, snapshot],
    );
  }

  /// Update session with new metrics
  WritingSession updateMetrics({
    int? wordCount,
    int? additionalCharacters,
    Duration? additionalActiveTime,
  }) {
    return WritingSession(
      id: id,
      documentId: documentId,
      startTime: startTime,
      endTime: endTime,
      initialWordCount: initialWordCount,
      currentWordCount: wordCount ?? currentWordCount,
      totalCharactersTyped: totalCharactersTyped + (additionalCharacters ?? 0),
      activeDuration: activeDuration + (additionalActiveTime ?? Duration.zero),
      totalDuration: isActive ? DateTime.now().difference(startTime) : totalDuration,
      snapshots: snapshots,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'documentId': documentId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'initialWordCount': initialWordCount,
        'currentWordCount': currentWordCount,
        'totalCharactersTyped': totalCharactersTyped,
        'activeDuration': activeDuration.inMilliseconds,
        'totalDuration': totalDuration.inMilliseconds,
        'snapshots': snapshots.map((s) => s.toJson()).toList(),
      };

  factory WritingSession.fromJson(Map<String, dynamic> json) => WritingSession(
        id: json['id'] as String,
        documentId: json['documentId'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        initialWordCount: json['initialWordCount'] as int? ?? 0,
        currentWordCount: json['currentWordCount'] as int? ?? 0,
        totalCharactersTyped: json['totalCharactersTyped'] as int? ?? 0,
        activeDuration: Duration(milliseconds: json['activeDuration'] as int? ?? 0),
        totalDuration: Duration(milliseconds: json['totalDuration'] as int? ?? 0),
        snapshots: (json['snapshots'] as List? ?? [])
            .map((s) => WritingSnapshot.fromJson(Map<String, dynamic>.from(s)))
            .toList(),
      );
}

/// Snapshot of writing state at a point in time
class WritingSnapshot {
  final DateTime timestamp;
  final int wordCount;
  final int characterCount;
  final String contentPreview; // First 100 characters for context

  const WritingSnapshot({
    required this.timestamp,
    required this.wordCount,
    required this.characterCount,
    required this.contentPreview,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'wordCount': wordCount,
        'characterCount': characterCount,
        'contentPreview': contentPreview,
      };

  factory WritingSnapshot.fromJson(Map<String, dynamic> json) => WritingSnapshot(
        timestamp: DateTime.parse(json['timestamp'] as String),
        wordCount: json['wordCount'] as int,
        characterCount: json['characterCount'] as int,
        contentPreview: json['contentPreview'] as String,
      );
}

/// Writing goals and progress tracking
class WritingGoal {
  final String id;
  final String title;
  final WritingGoalType type;
  final int targetValue;
  final DateTime createdAt;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  const WritingGoal({
    required this.id,
    required this.title,
    required this.type,
    required this.targetValue,
    required this.createdAt,
    this.deadline,
    this.isCompleted = false,
    this.completedAt,
    this.metadata = const {},
  });

  /// Calculate progress towards the goal
  double calculateProgress(int currentValue) {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Check if the goal is due today
  bool get isDueToday {
    if (deadline == null) return false;
    final today = DateTime.now();
    final deadlineDate = DateTime(deadline!.year, deadline!.month, deadline!.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    return deadlineDate.isAtSameMomentAs(todayDate);
  }

  /// Check if the goal is overdue
  bool get isOverdue {
    if (deadline == null || isCompleted) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// Mark goal as completed
  WritingGoal complete() {
    return WritingGoal(
      id: id,
      title: title,
      type: type,
      targetValue: targetValue,
      createdAt: createdAt,
      deadline: deadline,
      isCompleted: true,
      completedAt: DateTime.now(),
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'targetValue': targetValue,
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'metadata': metadata,
      };

  factory WritingGoal.fromJson(Map<String, dynamic> json) => WritingGoal(
        id: json['id'] as String,
        title: json['title'] as String,
        type: WritingGoalType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => WritingGoalType.words,
        ),
        targetValue: json['targetValue'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        deadline: json['deadline'] != null
            ? DateTime.parse(json['deadline'] as String)
            : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
}

/// Types of writing goals
enum WritingGoalType {
  words,
  characters,
  pages,
  time,
  documents,
}

/// Daily writing statistics summary
class DailyStats {
  final DateTime date;
  final int wordsWritten;
  final int charactersTyped;
  final Duration timeSpent;
  final int sessionsCount;
  final List<String> documentsWorkedOn;

  const DailyStats({
    required this.date,
    required this.wordsWritten,
    required this.charactersTyped,
    required this.timeSpent,
    required this.sessionsCount,
    required this.documentsWorkedOn,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'wordsWritten': wordsWritten,
        'charactersTyped': charactersTyped,
        'timeSpent': timeSpent.inMilliseconds,
        'sessionsCount': sessionsCount,
        'documentsWorkedOn': documentsWorkedOn,
      };

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
        date: DateTime.parse(json['date'] as String),
        wordsWritten: json['wordsWritten'] as int,
        charactersTyped: json['charactersTyped'] as int,
        timeSpent: Duration(milliseconds: json['timeSpent'] as int),
        sessionsCount: json['sessionsCount'] as int,
        documentsWorkedOn: List<String>.from(json['documentsWorkedOn'] as List),
      );

  /// Calculate average words per minute
  double get averageWPM {
    if (timeSpent.inSeconds == 0) return 0.0;
    return (wordsWritten * 60.0) / timeSpent.inSeconds;
  }

  /// Get formatted time spent
  String get formattedTimeSpent {
    final hours = timeSpent.inHours;
    final minutes = (timeSpent.inMinutes % 60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}