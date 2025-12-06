/// Represents a single timer session for a task.
/// Tracks elapsed time, pauses, and whether task was completed on time.
class TimerSession {
  final String taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool completedOnTime;
  final int extensionsUsed;
  final Duration totalPausedTime;

  TimerSession({
    required this.taskId,
    required this.startTime,
    this.endTime,
    this.completedOnTime = false,
    this.extensionsUsed = 0,
    this.totalPausedTime = Duration.zero,
  });

  /// Calculate elapsed time excluding pauses
  Duration get elapsedTime {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime) - totalPausedTime;
  }

  /// Whether this session is currently active
  bool get isActive => endTime == null;

  /// Convert to JSON for potential storage
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'completedOnTime': completedOnTime,
      'extensionsUsed': extensionsUsed,
      'totalPausedTime': totalPausedTime.inSeconds,
    };
  }

  /// Create from JSON
  factory TimerSession.fromJson(Map<String, dynamic> json) {
    return TimerSession(
      taskId: json['taskId'] ?? '',
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      completedOnTime: json['completedOnTime'] ?? false,
      extensionsUsed: json['extensionsUsed'] ?? 0,
      totalPausedTime: Duration(seconds: json['totalPausedTime'] ?? 0),
    );
  }
}
