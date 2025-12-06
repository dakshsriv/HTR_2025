import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/course.dart';
import '../models/user_settings.dart';
import '../models/completion_record.dart';

/// Service for persisting app data to local storage using SharedPreferences.
///
/// This service handles:
/// - Task storage and retrieval (JSON serialization)
/// - Course configuration persistence
/// - User settings storage
/// - Local-first data management for offline functionality
class PreferencesService {
  static const String _tasksKey = 'tasks';
  static const String _coursesKey = 'courses';
  static const String _settingsKey = 'user_settings';
  static const String _completionHistoryKey = 'completion_history';

  late final SharedPreferences _prefs;

  /// Initialize the preferences service.
  /// Must be called once at app startup.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ TASK OPERATIONS ============

  /// Save a list of tasks to local storage.
  Future<void> saveTasks(List<Task> tasks) async {
    final jsonList = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await _prefs.setStringList(_tasksKey, jsonList);
  }

  /// Load all tasks from local storage.
  List<Task> loadTasks() {
    final jsonList = _prefs.getStringList(_tasksKey) ?? [];
    return jsonList.map((json) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return Task.fromJson(decoded);
    }).toList();
  }

  /// Add a single task and persist immediately.
  Future<void> addTask(Task task) async {
    final tasks = loadTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  /// Update a task and persist immediately.
  /// Returns true if task was found and updated, false otherwise.
  Future<bool> updateTask(Task updatedTask) async {
    final tasks = loadTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
      return true;
    }
    return false;
  }

  /// Delete a task by ID and persist immediately.
  /// Returns true if task was found and deleted, false otherwise.
  Future<bool> deleteTask(String taskId) async {
    final tasks = loadTasks();
    final initialLength = tasks.length;
    tasks.removeWhere((t) => t.id == taskId);
    if (tasks.length < initialLength) {
      await saveTasks(tasks);
      return true;
    }
    return false;
  }

  /// Get a single task by ID.
  Task? getTask(String taskId) {
    final tasks = loadTasks();
    try {
      return tasks.firstWhere((t) => t.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // ============ COURSE OPERATIONS ============

  /// Save a list of courses to local storage.
  Future<void> saveCourses(List<Course> courses) async {
    final jsonList = courses.map((course) => jsonEncode(course.toJson())).toList();
    await _prefs.setStringList(_coursesKey, jsonList);
  }

  /// Load all courses from local storage.
  List<Course> loadCourses() {
    final jsonList = _prefs.getStringList(_coursesKey) ?? [];
    return jsonList.map((json) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return Course.fromJson(decoded);
    }).toList();
  }

  /// Add a single course and persist immediately.
  Future<void> addCourse(Course course) async {
    final courses = loadCourses();
    courses.add(course);
    await saveCourses(courses);
  }

  /// Update a course and persist immediately.
  Future<bool> updateCourse(Course updatedCourse) async {
    final courses = loadCourses();
    final index = courses.indexWhere((c) => c.id == updatedCourse.id);
    if (index != -1) {
      courses[index] = updatedCourse;
      await saveCourses(courses);
      return true;
    }
    return false;
  }

  /// Delete a course by ID and persist immediately.
  Future<bool> deleteCourse(String courseId) async {
    final courses = loadCourses();
    final initialLength = courses.length;
    courses.removeWhere((c) => c.id == courseId);
    if (courses.length < initialLength) {
      await saveCourses(courses);
      return true;
    }
    return false;
  }

  /// Get a single course by ID.
  Course? getCourse(String courseId) {
    final courses = loadCourses();
    try {
      return courses.firstWhere((c) => c.id == courseId);
    } catch (e) {
      return null;
    }
  }

  // ============ SETTINGS OPERATIONS ============

  /// Save user settings to local storage.
  Future<void> saveSettings(UserSettings settings) async {
    final json = jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, json);
  }

  /// Load user settings from local storage.
  /// Returns defaults if no settings have been saved yet.
  UserSettings loadSettings() {
    final json = _prefs.getString(_settingsKey);
    if (json == null) {
      return UserSettings.defaults();
    }
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return UserSettings.fromJson(decoded);
  }

  // ============ COMPLETION HISTORY OPERATIONS ============

  /// Save a completion record to history.
  Future<void> saveCompletionRecord(CompletionRecord record) async {
    final history = loadCompletionHistory();
    history.add(record);
    final jsonList = history.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(_completionHistoryKey, jsonList);
  }

  /// Load all completion records from history.
  List<CompletionRecord> loadCompletionHistory() {
    final jsonList = _prefs.getStringList(_completionHistoryKey) ?? [];
    return jsonList.map((json) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return CompletionRecord.fromJson(decoded);
    }).toList();
  }

  /// Get on-time completion percentage (0.0 to 1.0).
  /// Returns 0.0 if no completions yet.
  double getOnTimeCompletionPercentage() {
    final history = loadCompletionHistory();
    if (history.isEmpty) return 0.0;

    final onTimeCount = history.where((r) => r.completedOnTime).length;
    return onTimeCount / history.length;
  }

  /// Get completion stats for a specific task.
  /// Returns null if task has no completion records.
  CompletionStats? getTaskCompletionStats(String taskId) {
    final history = loadCompletionHistory();
    final taskRecords = history.where((r) => r.taskId == taskId).toList();

    if (taskRecords.isEmpty) return null;

    final onTimeCount = taskRecords.where((r) => r.completedOnTime).length;
    final totalOvertime = taskRecords.fold<int>(0, (sum, r) => sum + r.overtimeMinutes);
    final totalExtensions = taskRecords.fold<int>(0, (sum, r) => sum + r.extensionsUsed);

    return CompletionStats(
      totalCompletions: taskRecords.length,
      onTimeCount: onTimeCount,
      totalOvertimeMinutes: totalOvertime,
      totalExtensionsUsed: totalExtensions,
    );
  }

  /// Clear all data (useful for testing or factory reset).
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

/// Statistics for a task's completion history.
class CompletionStats {
  final int totalCompletions;
  final int onTimeCount;
  final int totalOvertimeMinutes;
  final int totalExtensionsUsed;

  CompletionStats({
    required this.totalCompletions,
    required this.onTimeCount,
    required this.totalOvertimeMinutes,
    required this.totalExtensionsUsed,
  });

  /// Get on-time percentage for this task (0.0 to 1.0)
  double get onTimePercentage =>
      totalCompletions > 0 ? onTimeCount / totalCompletions : 0.0;

  /// Get average overtime minutes for this task
  int get averageOvertimeMinutes =>
      totalCompletions > 0 ? totalOvertimeMinutes ~/ totalCompletions : 0;

  /// Get average extensions used per completion
  int get averageExtensionsPerCompletion =>
      totalCompletions > 0 ? totalExtensionsUsed ~/ totalCompletions : 0;
}
