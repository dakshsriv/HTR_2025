import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/course.dart';
import '../models/user_settings.dart';
import '../services/preferences_service.dart';

/// Provider for managing tasks, courses, and settings using Provider pattern.
///
/// This provider handles:
/// - Task CRUD operations with persistence
/// - Course management
/// - User settings management
/// - Notifying listeners of state changes
class TaskProvider extends ChangeNotifier {
  final PreferencesService _prefsService;

  List<Task> _tasks = [];
  List<Course> _courses = [];
  UserSettings _settings = UserSettings.defaults();

  final _uuid = const Uuid();

  TaskProvider({required PreferencesService prefsService})
      : _prefsService = prefsService;

  // ============ GETTERS ============

  List<Task> get tasks => _tasks;
  List<Course> get courses => _courses;
  UserSettings get settings => _settings;

  /// Get incomplete tasks sorted by most recent first.
  List<Task> get incompleteTasks =>
      _tasks.where((t) => !t.isCompleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Get the next task to display in "Right Now" view.
  /// Returns the oldest incomplete task that should be worked on now.
  /// Shows newly created tasks (8 hour window) but hides snoozed tasks (>24 hours in future).
  Task? get nextActiveTask {
    final now = DateTime.now();
    final oneDay = Duration(hours: 24);

    // Show tasks that are:
    // - Due now or in the past, OR
    // - Due within 24 hours (newly created tasks with 8hr window)
    // Hide tasks snoozed beyond 24 hours
    final incomplete = incompleteTasks
        .where((t) {
          if (t.dueDate == null) return true; // No deadline = show it
          final timeUntilDue = t.dueDate!.difference(now);
          // Show if due now/past, or within 24 hours (catch newly added tasks)
          return timeUntilDue.inHours <= 24;
        })
        .toList();
    return incomplete.isNotEmpty ? incomplete.last : null;
  }

  /// Get a course by ID.
  Course? getCourse(String? courseId) {
    if (courseId == null) return null;
    try {
      return _courses.firstWhere((c) => c.id == courseId);
    } catch (e) {
      return null;
    }
  }

  /// Get a single task by ID.
  Task? getTask(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (e) {
      return null;
    }
  }

  // ============ INITIALIZATION ============

  /// Initialize the provider by loading all data from storage.
  Future<void> initialize() async {
    _tasks = _prefsService.loadTasks();
    _courses = _prefsService.loadCourses();
    _settings = _prefsService.loadSettings();
    notifyListeners();
  }

  // ============ TASK OPERATIONS ============

  /// Create and add a new task.
  ///
  /// Parameters:
  /// - title: Task description (required)
  /// - description: Optional longer description
  /// - dueDate: Optional due date/time
  /// - courseId: Optional course ID
  /// - estimatedMinutes: Estimated duration (triggers micro-steps if >45 mins)
  Future<Task> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String? courseId,
    int estimatedMinutes = 0,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      courseId: courseId,
      estimatedMinutes: estimatedMinutes,
    );
    _tasks.add(task);
    await _prefsService.addTask(task);
    notifyListeners();
    return task;
  }

  /// Check if a task can be completed.
  /// Returns false if task needs micro-steps but doesn't have them.
  bool canCompleteTask(String taskId) {
    final task = getTask(taskId);
    if (task == null) return false;

    // If task is longer than threshold and has no micro-steps, block completion
    if (task.estimatedMinutes > _settings.microStepThresholdMinutes &&
        task.microSteps.isEmpty) {
      return false;
    }

    return true;
  }

  /// Mark a task as completed.
  /// If task needs micro-steps, this will be blocked by the UI.
  Future<void> completeTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isCompleted: true);
      await _prefsService.updateTask(_tasks[index]);
      notifyListeners();
    }
  }

  /// Mark a task as incomplete (undo completion).
  Future<void> uncompleteTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isCompleted: false);
      await _prefsService.updateTask(_tasks[index]);
      notifyListeners();
    }
  }

  /// Delete a task by ID.
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _prefsService.deleteTask(taskId);
    notifyListeners();
  }

  /// Update a task with new values.
  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      await _prefsService.updateTask(updatedTask);
      notifyListeners();
    }
  }

  /// Re-roll (reschedule) a task to the next available time.
  /// Increments the due date by 1 day and resets micro-step completions.
  Future<void> rerollTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newDueDate = task.dueDate?.add(const Duration(days: 1)) ??
          DateTime.now().add(const Duration(days: 1));

      _tasks[index] = task.copyWith(
        dueDate: newDueDate,
        isCompleted: false,
        microSteps: task.microSteps
            .map((ms) => ms.copyWith(isCompleted: false))
            .toList(),
      );
      await _prefsService.updateTask(_tasks[index]);
      notifyListeners();
    }
  }

  /// Add micro-steps to a task.
  Future<void> addMicroSteps(String taskId, List<MicroStep> microSteps) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(microSteps: microSteps);
      await _prefsService.updateTask(_tasks[index]);
      notifyListeners();
    }
  }

  /// Toggle micro-step completion status.
  Future<void> toggleMicroStepComplete(String taskId, String microStepId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedSteps = task.microSteps.map((ms) {
        if (ms.id == microStepId) {
          return ms.copyWith(isCompleted: !ms.isCompleted);
        }
        return ms;
      }).toList();
      _tasks[taskIndex] = task.copyWith(microSteps: updatedSteps);
      await _prefsService.updateTask(_tasks[taskIndex]);
      notifyListeners();
    }
  }

  // ============ COURSE OPERATIONS ============

  /// Create and add a new course.
  Future<Course> addCourse({
    required String name,
    required Color color,
  }) async {
    final course = Course(
      id: _uuid.v4(),
      name: name,
      color: color,
    );
    _courses.add(course);
    await _prefsService.addCourse(course);
    notifyListeners();
    return course;
  }

  /// Update a course.
  Future<void> updateCourse(Course updatedCourse) async {
    final index = _courses.indexWhere((c) => c.id == updatedCourse.id);
    if (index != -1) {
      _courses[index] = updatedCourse;
      await _prefsService.updateCourse(updatedCourse);
      notifyListeners();
    }
  }

  /// Delete a course by ID.
  /// Also removes course assignment from any tasks using this course.
  Future<void> deleteCourse(String courseId) async {
    _courses.removeWhere((c) => c.id == courseId);

    // Remove course references from tasks
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].courseId == courseId) {
        _tasks[i] = _tasks[i].copyWith(courseId: null);
        await _prefsService.updateTask(_tasks[i]);
      }
    }

    await _prefsService.deleteCourse(courseId);
    notifyListeners();
  }

  // ============ SETTINGS OPERATIONS ============

  /// Update user settings.
  Future<void> updateSettings(UserSettings newSettings) async {
    _settings = newSettings;
    await _prefsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Update the micro-step threshold and persist.
  Future<void> setMicroStepThreshold(int minutes) async {
    _settings = _settings.copyWith(microStepThresholdMinutes: minutes);
    await _prefsService.saveSettings(_settings);
    notifyListeners();
  }

  /// Update the break nudge frequency and persist.
  Future<void> setBreakNudgeFrequency(int frequency) async {
    _settings = _settings.copyWith(breakNudgeFrequency: frequency);
    await _prefsService.saveSettings(_settings);
    notifyListeners();
  }
}
