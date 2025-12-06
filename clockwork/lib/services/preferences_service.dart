import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/course.dart';
import '../models/user_settings.dart';

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

  /// Clear all data (useful for testing or factory reset).
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
