/// Analytics data model holding computed metrics from completion history.
/// All fields are calculated from CompletionRecord data, not stored.
class AnalyticsData {
  // Overall performance
  final double onTimePercentage; // 0.0 to 100.0
  final int totalCompletions; // All-time count
  final int thisMonthCompletions;
  final int thisWeekCompletions;

  // Streak tracking
  final int currentStreak; // Days with ≥1 completion
  final int bestStreak; // Best streak all-time

  // This week breakdown
  final int thisWeekOnTime;
  final int thisWeekLate;
  final int thisWeekAvgOvertimeMinutes;

  // Overtime patterns
  final int avgOvertimeMinutes; // Average across all completions
  final Map<String, int> overtimeDistribution; // "0" → %, "5-15" → %, "15+" → %

  // Time estimation
  final int estimatedAvgMinutes; // Average estimated time
  final int actualAvgMinutes; // Average actual time spent
  final double estimationRatio; // Actual / Estimated (e.g., 1.4)

  // Peak hours
  final Map<String, int> hourlyDistribution; // "10-12" → count, "14-16" → count

  // Computed helpers
  final String peakHour; // "10am-12pm" (most common)
  final int avgPerWeek; // Total / weeks

  AnalyticsData({
    required this.onTimePercentage,
    required this.totalCompletions,
    required this.thisMonthCompletions,
    required this.thisWeekCompletions,
    required this.currentStreak,
    required this.bestStreak,
    required this.thisWeekOnTime,
    required this.thisWeekLate,
    required this.thisWeekAvgOvertimeMinutes,
    required this.avgOvertimeMinutes,
    required this.overtimeDistribution,
    required this.estimatedAvgMinutes,
    required this.actualAvgMinutes,
    required this.estimationRatio,
    required this.hourlyDistribution,
    required this.peakHour,
    required this.avgPerWeek,
  });

  /// Create empty analytics (for when no data exists)
  factory AnalyticsData.empty() {
    return AnalyticsData(
      onTimePercentage: 0.0,
      totalCompletions: 0,
      thisMonthCompletions: 0,
      thisWeekCompletions: 0,
      currentStreak: 0,
      bestStreak: 0,
      thisWeekOnTime: 0,
      thisWeekLate: 0,
      thisWeekAvgOvertimeMinutes: 0,
      avgOvertimeMinutes: 0,
      overtimeDistribution: {'0': 0, '5-15': 0, '15+': 0},
      estimatedAvgMinutes: 0,
      actualAvgMinutes: 0,
      estimationRatio: 0.0,
      hourlyDistribution: {},
      peakHour: 'N/A',
      avgPerWeek: 0,
    );
  }
}
