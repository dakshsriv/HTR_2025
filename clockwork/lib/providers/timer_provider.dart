import 'package:flutter/material.dart';
import 'dart:async';
import '../models/task.dart';
import '../models/timer_session.dart';

/// Manages timer state for task work sessions.
/// Handles dual timers (task total + current step/break), pausing, and completion.
class TimerProvider extends ChangeNotifier {
  Task? _activeTask;
  int _currentStepIndex = 0;
  bool _isTimerActive = false;
  bool _isPaused = false;

  // Timers and timing state
  Timer? _taskTimer;
  Timer? _stepTimer;
  DateTime? _sessionStartTime;
  DateTime? _pauseStartTime;
  Duration _totalPausedTime = Duration.zero;

  // Accumulated durations
  Duration _totalTaskDuration = Duration.zero;
  Duration _currentStepDuration = Duration.zero;

  // Extension tracking
  int _extensionsUsed = 0;

  // Getters
  Task? get activeTask => _activeTask;
  int get currentStepIndex => _currentStepIndex;
  bool get isTimerActive => _isTimerActive;
  bool get isPaused => _isPaused;
  int get extensionsUsed => _extensionsUsed;

  /// Get remaining time for task (0 or negative if overtime)
  Duration get taskTimeRemaining {
    if (_activeTask == null) return Duration.zero;
    final taskMinutes = _activeTask!.estimatedMinutes;
    final totalSeconds = taskMinutes * 60;
    final elapsedSeconds = _totalTaskDuration.inSeconds - _totalPausedTime.inSeconds;
    return Duration(seconds: max(0, totalSeconds - elapsedSeconds));
  }

  /// Get remaining time for current step (0 if no microsteps)
  Duration get stepTimeRemaining {
    if (_activeTask == null || _activeTask!.microSteps.isEmpty) {
      return Duration.zero;
    }

    final step = _activeTask!.microSteps[_currentStepIndex];
    final stepSeconds = step.timeMinutes * 60;
    final elapsedSeconds = _currentStepDuration.inSeconds;
    return Duration(seconds: max(0, stepSeconds - elapsedSeconds));
  }

  /// Get overtime (positive = over estimate)
  Duration get overtime {
    if (_activeTask == null) return Duration.zero;
    final taskMinutes = _activeTask!.estimatedMinutes;
    final totalSeconds = taskMinutes * 60;
    final elapsedSeconds = _totalTaskDuration.inSeconds - _totalPausedTime.inSeconds;
    final diff = elapsedSeconds - totalSeconds;
    return Duration(seconds: max(0, diff));
  }

  /// Whether task has exceeded its time estimate
  bool get isOvertime => overtime.inSeconds > 0;

  /// Whether current task has microsteps
  bool get hasMicrosteps => _activeTask?.microSteps.isNotEmpty ?? false;

  /// Get total task time in minutes
  int get totalTaskMinutes => _activeTask?.estimatedMinutes ?? 0;

  /// Get current step name (or empty string if no microsteps)
  String get currentStepName {
    if (!hasMicrosteps || _currentStepIndex >= _activeTask!.microSteps.length) {
      return '';
    }
    return _activeTask!.microSteps[_currentStepIndex].title;
  }

  /// Get current step time minutes (or 0 if no microsteps)
  int get currentStepMinutes {
    if (!hasMicrosteps || _currentStepIndex >= _activeTask!.microSteps.length) {
      return 0;
    }
    return _activeTask!.microSteps[_currentStepIndex].timeMinutes;
  }

  /// Get whether we're currently in break time (not used if no microsteps)
  bool get isInBreakTime {
    if (!hasMicrosteps) return false;
    // Break happens after each step except the last one
    return _currentStepIndex > 0 && _currentStepIndex % 2 == 1;
  }

  /// Start timer for a task
  void startTimer(Task task) {
    _activeTask = task;
    _currentStepIndex = 0;
    _isTimerActive = true;
    _isPaused = false;
    _extensionsUsed = 0;
    _totalPausedTime = Duration.zero;
    _totalTaskDuration = Duration.zero;
    _currentStepDuration = Duration.zero;
    _sessionStartTime = DateTime.now();

    _startTimers();
    notifyListeners();
  }

  /// Initialize both timers
  void _startTimers() {
    // Task timer: updates every second
    _taskTimer?.cancel();
    _taskTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _totalTaskDuration = _totalTaskDuration + const Duration(seconds: 1);
        notifyListeners();
      }
    });

    // Step timer: only if task has microsteps
    if (hasMicrosteps) {
      _stepTimer?.cancel();
      _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPaused) {
          _currentStepDuration = _currentStepDuration + const Duration(seconds: 1);
          // Check if step timer complete
          if (stepTimeRemaining.inSeconds <= 0) {
            _advanceToNextStep();
          }
          notifyListeners();
        }
      });
    }
  }

  /// Pause both timers
  void pauseTimer() {
    if (!_isTimerActive || _isPaused) return;
    _isPaused = true;
    _pauseStartTime = DateTime.now();
    notifyListeners();
  }

  /// Resume paused timers
  void resumeTimer() {
    if (!_isTimerActive || !_isPaused) return;
    if (_pauseStartTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseStartTime!);
      _totalPausedTime = _totalPausedTime + pauseDuration;
    }
    _isPaused = false;
    _pauseStartTime = null;
    notifyListeners();
  }

  /// Advance to next step (or next break)
  void _advanceToNextStep() {
    if (!hasMicrosteps) return;

    // Move to next item (step or break)
    _currentStepIndex++;

    // Check if we've completed all steps
    if (_currentStepIndex >= _activeTask!.microSteps.length * 2 - 1) {
      // Task is complete, trigger completion dialog
      _completeTask(onTime: !isOvertime);
      return;
    }

    // Reset step duration for next step/break
    _currentStepDuration = Duration.zero;
    notifyListeners();
  }

  /// Skip current step and move to next
  void skipStep() {
    if (!hasMicrosteps) return;
    _currentStepIndex++;
    _currentStepDuration = Duration.zero;
    notifyListeners();
  }

  /// Complete the task
  void _completeTask({required bool onTime}) {
    _isTimerActive = false;
    _taskTimer?.cancel();
    _stepTimer?.cancel();
    notifyListeners();
  }

  /// Start a 10-minute extension timer
  void startExtension() {
    _extensionsUsed++;
    _totalTaskDuration = Duration.zero; // Reset for extension period
    _currentStepDuration = Duration.zero;
    _isTimerActive = true;
    _isPaused = false;
    _startTimers();
    notifyListeners();
  }

  /// Switch to a new task, clearing the previous one
  void switchTask(Task newTask) {
    clearTimer();
    startTimer(newTask);
  }

  /// Clear the active timer (user switched to different task)
  void clearTimer() {
    _activeTask = null;
    _isTimerActive = false;
    _isPaused = false;
    _taskTimer?.cancel();
    _stepTimer?.cancel();
    _totalPausedTime = Duration.zero;
    _totalTaskDuration = Duration.zero;
    _currentStepDuration = Duration.zero;
    _extensionsUsed = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _taskTimer?.cancel();
    _stepTimer?.cancel();
    super.dispose();
  }
}

/// Helper function for max
int max(int a, int b) => a > b ? a : b;
