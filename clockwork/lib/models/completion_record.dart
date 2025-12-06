/// Represents a single task completion record in history.
/// Used to track on-time performance and task completion statistics.
class CompletionRecord {
  final String taskId;
  final String taskTitle;
  final DateTime completedAt;
  final bool completedOnTime;
  final int overtimeMinutes;
  final int extensionsUsed;

  CompletionRecord({
    required this.taskId,
    required this.taskTitle,
    required this.completedAt,
    required this.completedOnTime,
    this.overtimeMinutes = 0,
    this.extensionsUsed = 0,
  });

  /// Convert to JSON for storage in preferences
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskTitle': taskTitle,
      'completedAt': completedAt.toIso8601String(),
      'completedOnTime': completedOnTime,
      'overtimeMinutes': overtimeMinutes,
      'extensionsUsed': extensionsUsed,
    };
  }

  /// Create from JSON
  factory CompletionRecord.fromJson(Map<String, dynamic> json) {
    return CompletionRecord(
      taskId: json['taskId'] ?? '',
      taskTitle: json['taskTitle'] ?? '',
      completedAt: DateTime.parse(json['completedAt'] ?? DateTime.now().toIso8601String()),
      completedOnTime: json['completedOnTime'] ?? false,
      overtimeMinutes: json['overtimeMinutes'] ?? 0,
      extensionsUsed: json['extensionsUsed'] ?? 0,
    );
  }
}
