/// User settings and preferences for the Flow Anchor app.
///
/// Stores user-configurable settings such as:
/// - Micro-step threshold (default 45 minutes)
/// - Break nudge frequency (after N completed tasks)
/// - Personal courses (max 4 for high school context)
class UserSettings {
  /// Minimum estimated time (in minutes) before a task requires micro-steps.
  /// Default: 45 minutes. Tasks exceeding this must be broken down.
  final int microStepThresholdMinutes;

  /// Number of tasks to complete before suggesting a break.
  /// Default: 3. After this many completions, user sees "Take a break?" prompt.
  final int breakNudgeFrequency;

  /// Whether break nudges are enabled.
  final bool breakNudgesEnabled;

  /// List of user's courses (typically 4 for high school).
  final List<String> courseIds;

  UserSettings({
    this.microStepThresholdMinutes = 45,
    this.breakNudgeFrequency = 3,
    this.breakNudgesEnabled = true,
    this.courseIds = const [],
  });

  /// Create a copy with modified values.
  UserSettings copyWith({
    int? microStepThresholdMinutes,
    int? breakNudgeFrequency,
    bool? breakNudgesEnabled,
    List<String>? courseIds,
  }) {
    return UserSettings(
      microStepThresholdMinutes:
          microStepThresholdMinutes ?? this.microStepThresholdMinutes,
      breakNudgeFrequency: breakNudgeFrequency ?? this.breakNudgeFrequency,
      breakNudgesEnabled: breakNudgesEnabled ?? this.breakNudgesEnabled,
      courseIds: courseIds ?? this.courseIds,
    );
  }

  /// Serialize settings to JSON for storage.
  Map<String, dynamic> toJson() {
    return {
      'microStepThresholdMinutes': microStepThresholdMinutes,
      'breakNudgeFrequency': breakNudgeFrequency,
      'breakNudgesEnabled': breakNudgesEnabled,
      'courseIds': courseIds,
    };
  }

  /// Deserialize settings from JSON.
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      microStepThresholdMinutes: json['microStepThresholdMinutes'] ?? 45,
      breakNudgeFrequency: json['breakNudgeFrequency'] ?? 3,
      breakNudgesEnabled: json['breakNudgesEnabled'] ?? true,
      courseIds: List<String>.from(json['courseIds'] ?? []),
    );
  }

  /// Get default settings (factory method for clarity).
  factory UserSettings.defaults() {
    return UserSettings();
  }
}
