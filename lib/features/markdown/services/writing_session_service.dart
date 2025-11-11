import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/writing_session.dart';
import '../services/writing_stats_service.dart';

/// Service for managing writing sessions and productivity tracking
class WritingSessionService {
  static const String _sessionsKey = 'writing_sessions';
  static const String _goalsKey = 'writing_goals';
  static const String _dailyStatsKey = 'daily_stats';
  static const String _currentSessionKey = 'current_session';

  WritingSession? _currentSession;
  Timer? _sessionTimer;
  Timer? _inactivityTimer;
  DateTime? _lastActivity;

  final StreamController<WritingSession?> _sessionController = StreamController.broadcast();
  final StreamController<List<WritingGoal>> _goalsController = StreamController.broadcast();

  /// Stream of the current writing session
  Stream<WritingSession?> get sessionStream => _sessionController.stream;

  /// Stream of active writing goals
  Stream<List<WritingGoal>> get goalsStream => _goalsController.stream;

  /// Get the current active session
  WritingSession? get currentSession => _currentSession;

  /// Start a new writing session
  Future<WritingSession> startSession(String documentId, String initialContent) async {
    // End any existing session first
    if (_currentSession != null) {
      await endSession();
    }

    final initialStats = WritingStatsService.calculateStats(initialContent);
    final session = WritingSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      documentId: documentId,
      startTime: DateTime.now(),
      initialWordCount: initialStats.wordCount,
      currentWordCount: initialStats.wordCount,
    );

    _currentSession = session;
    _lastActivity = DateTime.now();

    // Start session tracking timers
    _startSessionTimer();
    _startInactivityTimer();

    // Persist current session
    await _saveCurrentSession();

    _sessionController.add(_currentSession);
    return session;
  }

  /// Update the current session with new content
  Future<void> updateSession(String content, {int? additionalCharacters}) async {
    if (_currentSession == null) return;

    final stats = WritingStatsService.calculateStats(content);
    final now = DateTime.now();

    // Calculate additional active time since last activity
    Duration additionalActiveTime = Duration.zero;
    if (_lastActivity != null) {
      final timeSinceLastActivity = now.difference(_lastActivity!);
      // Only count as active time if less than 30 seconds since last activity
      if (timeSinceLastActivity.inSeconds < 30) {
        additionalActiveTime = timeSinceLastActivity;
      }
    }

    _currentSession = _currentSession!.updateMetrics(
      wordCount: stats.wordCount,
      additionalCharacters: additionalCharacters,
      additionalActiveTime: additionalActiveTime,
    );

    _lastActivity = now;

    // Reset inactivity timer
    _startInactivityTimer();

    // Persist updated session
    await _saveCurrentSession();

    _sessionController.add(_currentSession);
  }

  /// Add a snapshot to the current session
  Future<void> addSessionSnapshot(String content) async {
    if (_currentSession == null) return;

    final stats = WritingStatsService.calculateStats(content);
    final snapshot = WritingSnapshot(
      timestamp: DateTime.now(),
      wordCount: stats.wordCount,
      characterCount: stats.characterCount,
      contentPreview: content.length > 100 ? content.substring(0, 100) : content,
    );

    _currentSession = _currentSession!.addSnapshot(snapshot);

    await _saveCurrentSession();
    _sessionController.add(_currentSession);
  }

  /// End the current writing session
  Future<WritingSession?> endSession() async {
    if (_currentSession == null) return null;

    _sessionTimer?.cancel();
    _inactivityTimer?.cancel();

    final endedSession = _currentSession!.endSession();

    // Save completed session to history
    await _saveSessionToHistory(endedSession);

    // Update daily statistics
    await _updateDailyStats(endedSession);

    // Clear current session
    _currentSession = null;
    await _clearCurrentSession();

    _sessionController.add(null);
    return endedSession;
  }

  /// Get writing sessions for a date range
  Future<List<WritingSession>> getSessionHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString(_sessionsKey);

    if (sessionsJson == null) return [];

    final sessions = (jsonDecode(sessionsJson) as List)
        .map((json) => WritingSession.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();

    // Filter by date range if provided
    var filteredSessions = sessions;
    if (startDate != null) {
      filteredSessions = filteredSessions
          .where((s) => s.startTime.isAfter(startDate.subtract(const Duration(days: 1))))
          .toList();
    }
    if (endDate != null) {
      filteredSessions = filteredSessions
          .where((s) => s.startTime.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    // Sort by start time (most recent first)
    filteredSessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    // Apply limit if provided
    if (limit != null && limit > 0) {
      filteredSessions = filteredSessions.take(limit).toList();
    }

    return filteredSessions;
  }

  /// Get daily statistics for a date range
  Future<List<DailyStats>> getDailyStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_dailyStatsKey);

    if (statsJson == null) return [];

    final stats = (jsonDecode(statsJson) as List)
        .map((json) => DailyStats.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();

    // Filter by date range if provided
    var filteredStats = stats;
    if (startDate != null) {
      filteredStats = filteredStats
          .where((s) => s.date.isAfter(startDate.subtract(const Duration(days: 1))))
          .toList();
    }
    if (endDate != null) {
      filteredStats = filteredStats
          .where((s) => s.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    // Sort by date (most recent first)
    filteredStats.sort((a, b) => b.date.compareTo(a.date));

    return filteredStats;
  }

  /// Create a new writing goal
  Future<WritingGoal> createGoal({
    required String title,
    required WritingGoalType type,
    required int targetValue,
    DateTime? deadline,
    Map<String, dynamic>? metadata,
  }) async {
    final goal = WritingGoal(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      type: type,
      targetValue: targetValue,
      createdAt: DateTime.now(),
      deadline: deadline,
      metadata: metadata ?? {},
    );

    await _saveGoal(goal);
    await _notifyGoalsChanged();

    return goal;
  }

  /// Update an existing writing goal
  Future<void> updateGoal(WritingGoal goal) async {
    await _saveGoal(goal);
    await _notifyGoalsChanged();
  }

  /// Complete a writing goal
  Future<void> completeGoal(String goalId) async {
    final goals = await getGoals();
    final goalIndex = goals.indexWhere((g) => g.id == goalId);

    if (goalIndex != -1) {
      final completedGoal = goals[goalIndex].complete();
      await _saveGoal(completedGoal);
      await _notifyGoalsChanged();
    }
  }

  /// Delete a writing goal
  Future<void> deleteGoal(String goalId) async {
    final goals = await getGoals();
    final updatedGoals = goals.where((g) => g.id != goalId).toList();

    final prefs = await SharedPreferences.getInstance();
    final goalsJson = jsonEncode(updatedGoals.map((g) => g.toJson()).toList());
    await prefs.setString(_goalsKey, goalsJson);

    await _notifyGoalsChanged();
  }

  /// Get all writing goals
  Future<List<WritingGoal>> getGoals({bool activeOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getString(_goalsKey);

    if (goalsJson == null) return [];

    var goals = (jsonDecode(goalsJson) as List)
        .map((json) => WritingGoal.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();

    if (activeOnly) {
      goals = goals.where((g) => !g.isCompleted).toList();
    }

    // Sort by created date (newest first)
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return goals;
  }

  /// Get today's writing statistics
  Future<DailyStats?> getTodayStats() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final stats = await getDailyStats(
      startDate: todayDate,
      endDate: todayDate,
    );

    return stats.isNotEmpty ? stats.first : null;
  }

  /// Calculate writing streaks
  Future<int> calculateCurrentStreak() async {
    final stats = await getDailyStats();
    if (stats.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    var currentDate = DateTime(today.year, today.month, today.day);

    for (final dayStat in stats) {
      final statDate = DateTime(dayStat.date.year, dayStat.date.month, dayStat.date.day);

      if (statDate.isAtSameMomentAs(currentDate) && dayStat.wordsWritten > 0) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (statDate.isBefore(currentDate)) {
        // Gap in the streak
        break;
      }
    }

    return streak;
  }

  /// Restore session from storage on app startup
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_currentSessionKey);

    if (sessionJson != null) {
      try {
        _currentSession = WritingSession.fromJson(
          jsonDecode(sessionJson) as Map<String, dynamic>,
        );
        _lastActivity = DateTime.now();

        // Resume session tracking
        _startSessionTimer();
        _startInactivityTimer();

        _sessionController.add(_currentSession);
      } catch (e) {
        // Clear corrupted session data
        await prefs.remove(_currentSessionKey);
      }
    }
  }

  /// Start the session timer to track total duration
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentSession != null) {
        _currentSession = _currentSession!.updateMetrics();
        _sessionController.add(_currentSession);
        _saveCurrentSession();
      }
    });
  }

  /// Start the inactivity timer to pause active time tracking
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      // User has been inactive for 5 minutes, pause active time tracking
      _lastActivity = null;
    });
  }

  /// Save the current session to storage
  Future<void> _saveCurrentSession() async {
    if (_currentSession == null) return;

    final prefs = await SharedPreferences.getInstance();
    final sessionJson = jsonEncode(_currentSession!.toJson());
    await prefs.setString(_currentSessionKey, sessionJson);
  }

  /// Clear the current session from storage
  Future<void> _clearCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSessionKey);
  }

  /// Save a completed session to history
  Future<void> _saveSessionToHistory(WritingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString(_sessionsKey);

    List<WritingSession> sessions = [];
    if (sessionsJson != null) {
      sessions = (jsonDecode(sessionsJson) as List)
          .map((json) => WritingSession.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    }

    sessions.add(session);

    // Keep only the last 100 sessions to avoid storage bloat
    if (sessions.length > 100) {
      sessions = sessions.sublist(sessions.length - 100);
    }

    final updatedJson = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, updatedJson);
  }

  /// Update daily statistics with session data
  Future<void> _updateDailyStats(WritingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_dailyStatsKey);

    List<DailyStats> stats = [];
    if (statsJson != null) {
      stats = (jsonDecode(statsJson) as List)
          .map((json) => DailyStats.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    }

    final sessionDate = DateTime(
      session.startTime.year,
      session.startTime.month,
      session.startTime.day,
    );

    // Find or create stats for the session date
    final existingIndex = stats.indexWhere((s) =>
        s.date.year == sessionDate.year &&
        s.date.month == sessionDate.month &&
        s.date.day == sessionDate.day);

    if (existingIndex != -1) {
      // Update existing stats
      final existing = stats[existingIndex];
      final documentsWorkedOn = Set<String>.from(existing.documentsWorkedOn);
      documentsWorkedOn.add(session.documentId);

      stats[existingIndex] = DailyStats(
        date: existing.date,
        wordsWritten: existing.wordsWritten + session.wordsAdded,
        charactersTyped: existing.charactersTyped + session.totalCharactersTyped,
        timeSpent: existing.timeSpent + session.activeDuration,
        sessionsCount: existing.sessionsCount + 1,
        documentsWorkedOn: documentsWorkedOn.toList(),
      );
    } else {
      // Create new stats entry
      stats.add(DailyStats(
        date: sessionDate,
        wordsWritten: session.wordsAdded,
        charactersTyped: session.totalCharactersTyped,
        timeSpent: session.activeDuration,
        sessionsCount: 1,
        documentsWorkedOn: [session.documentId],
      ));
    }

    // Keep only the last 90 days of stats
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    stats = stats.where((s) => s.date.isAfter(cutoffDate)).toList();

    final updatedJson = jsonEncode(stats.map((s) => s.toJson()).toList());
    await prefs.setString(_dailyStatsKey, updatedJson);
  }

  /// Save a goal to storage
  Future<void> _saveGoal(WritingGoal goal) async {
    final goals = await getGoals();
    final existingIndex = goals.indexWhere((g) => g.id == goal.id);

    if (existingIndex != -1) {
      goals[existingIndex] = goal;
    } else {
      goals.add(goal);
    }

    final prefs = await SharedPreferences.getInstance();
    final goalsJson = jsonEncode(goals.map((g) => g.toJson()).toList());
    await prefs.setString(_goalsKey, goalsJson);
  }

  /// Notify listeners that goals have changed
  Future<void> _notifyGoalsChanged() async {
    final goals = await getGoals(activeOnly: true);
    _goalsController.add(goals);
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    _sessionTimer?.cancel();
    _inactivityTimer?.cancel();
    _sessionController.close();
    _goalsController.close();
  }
}