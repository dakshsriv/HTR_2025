import 'package:flutter/material.dart';
import '../models/analytics_data.dart';
import '../models/completion_record.dart';
import '../services/preferences_service.dart';

/// Provides computed analytics from completion history.
/// All calculations are derived from CompletionRecord data.
class AnalyticsProvider extends ChangeNotifier {
  final PreferencesService prefsService;
  late AnalyticsData _cachedAnalytics;
  DateTime? _lastComputedTime;

  AnalyticsProvider({required this.prefsService}) {
    _cachedAnalytics = AnalyticsData.empty();
    _computeAnalytics();
  }

  /// Get current analytics data (returns cached unless stale)
  AnalyticsData get analytics => _cachedAnalytics;

  /// Refresh analytics (called when new completion is saved)
  void refreshAnalytics() {
    _computeAnalytics();
    notifyListeners();
  }

  /// Compute all analytics metrics
  void _computeAnalytics() {
    final history = prefsService.loadCompletionHistory();

    if (history.isEmpty) {
      _cachedAnalytics = AnalyticsData.empty();
      _lastComputedTime = DateTime.now();
      return;
    }

    final onTimePercentage = _calculateOnTimePercentage(history);
    final totalCompletions = history.length;
    final thisMonthData = _calculateThisMonth(history);
    final thisWeekData = _calculateThisWeek(history);
    final streaks = _calculateStreaks(history);
    final overtimeData = _calculateOvertimeDistribution(history);
    final estimationData = _calculateEstimation(history);
    final hourlyData = _calculateHourlyDistribution(history);
    final peakHour = _getPeakHour(hourlyData);
    final avgPerWeek = _calculateAvgPerWeek(totalCompletions);

    _cachedAnalytics = AnalyticsData(
      onTimePercentage: onTimePercentage,
      totalCompletions: totalCompletions,
      thisMonthCompletions: thisMonthData['total'] as int,
      thisWeekCompletions: thisWeekData['total'] as int,
      currentStreak: streaks['current'] as int,
      bestStreak: streaks['best'] as int,
      thisWeekOnTime: thisWeekData['onTime'] as int,
      thisWeekLate: thisWeekData['late'] as int,
      thisWeekAvgOvertimeMinutes: thisWeekData['avgOvertime'] as int,
      avgOvertimeMinutes: overtimeData['average'] as int,
      overtimeDistribution: overtimeData['distribution'] as Map<String, int>,
      estimatedAvgMinutes: estimationData['estimated'] as int,
      actualAvgMinutes: estimationData['actual'] as int,
      estimationRatio: estimationData['ratio'] as double,
      hourlyDistribution: hourlyData,
      peakHour: peakHour,
      avgPerWeek: avgPerWeek,
    );

    _lastComputedTime = DateTime.now();
  }

  /// Calculate on-time completion percentage
  double _calculateOnTimePercentage(List<CompletionRecord> history) {
    if (history.isEmpty) return 0.0;
    final onTimeCount = history.where((r) => r.completedOnTime).length;
    return (onTimeCount / history.length) * 100;
  }

  /// Get this month's metrics
  Map<String, dynamic> _calculateThisMonth(List<CompletionRecord> history) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final thisMonth = history.where((r) => r.completedAt.isAfter(thirtyDaysAgo)).toList();

    return {
      'total': thisMonth.length,
    };
  }

  /// Get this week's metrics
  Map<String, dynamic> _calculateThisWeek(List<CompletionRecord> history) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final thisWeek = history.where((r) => r.completedAt.isAfter(sevenDaysAgo)).toList();

    final onTimeCount = thisWeek.where((r) => r.completedOnTime).length;
    final lateCount = thisWeek.length - onTimeCount;
    final avgOvertime = thisWeek.isEmpty
        ? 0
        : thisWeek.fold<int>(0, (sum, r) => sum + r.overtimeMinutes) ~/ thisWeek.length;

    return {
      'total': thisWeek.length,
      'onTime': onTimeCount,
      'late': lateCount,
      'avgOvertime': avgOvertime,
    };
  }

  /// Calculate current and best streaks
  Map<String, int> _calculateStreaks(List<CompletionRecord> history) {
    if (history.isEmpty) {
      return {'current': 0, 'best': 0};
    }

    // Get unique dates from completion history
    final completionDates = history
        .map((r) => DateTime(r.completedAt.year, r.completedAt.month, r.completedAt.day))
        .toSet();

    // Calculate current streak (from today backwards)
    int currentStreak = 0;
    DateTime checkDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    while (completionDates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Calculate best streak (iterate through sorted dates)
    int bestStreak = 0;
    int tempStreak = 1;

    final sortedDates = completionDates.toList()..sort((a, b) => a.compareTo(b));

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        tempStreak++;
      } else {
        bestStreak = max(bestStreak, tempStreak);
        tempStreak = 1;
      }
    }
    bestStreak = max(bestStreak, tempStreak);

    return {'current': currentStreak, 'best': bestStreak};
  }

  /// Calculate overtime distribution
  Map<String, dynamic> _calculateOvertimeDistribution(List<CompletionRecord> history) {
    if (history.isEmpty) {
      return {
        'average': 0,
        'distribution': {'0': 0, '5-15': 0, '15+': 0},
      };
    }

    final avgOvertime = history.fold<int>(0, (sum, r) => sum + r.overtimeMinutes) ~/ history.length;

    // Count distribution
    final zeroCount = history.where((r) => r.overtimeMinutes == 0).length;
    final fiveFifteenCount = history.where((r) => r.overtimeMinutes > 0 && r.overtimeMinutes <= 15).length;
    final fifteenPlusCount = history.where((r) => r.overtimeMinutes > 15).length;

    return {
      'average': avgOvertime,
      'distribution': {
        '0': zeroCount,
        '5-15': fiveFifteenCount,
        '15+': fifteenPlusCount,
      },
    };
  }

  /// Calculate time estimation accuracy
  Map<String, dynamic> _calculateEstimation(List<CompletionRecord> history) {
    if (history.isEmpty) {
      return {
        'estimated': 0,
        'actual': 0,
        'ratio': 0.0,
      };
    }

    // Note: CompletionRecord doesn't store estimated vs actual time yet
    // For now, we'll use overtime as a proxy
    // In future: could add actualTimeMinutes to CompletionRecord

    final estimatedAvg = 30; // Placeholder - would need to store in CompletionRecord
    final avgActual = estimatedAvg + (history.fold<int>(0, (sum, r) => sum + r.overtimeMinutes) ~/ history.length);
    final ratio = estimatedAvg > 0 ? avgActual / estimatedAvg : 0.0;

    return {
      'estimated': estimatedAvg,
      'actual': avgActual,
      'ratio': ratio,
    };
  }

  /// Calculate hourly distribution (when tasks are completed)
  Map<String, int> _calculateHourlyDistribution(List<CompletionRecord> history) {
    final hourBuckets = <String, int>{};

    for (var record in history) {
      final hour = record.completedAt.hour;
      final nextHour = hour + 2;
      final bucket = '$hour-$nextHour';
      hourBuckets[bucket] = (hourBuckets[bucket] ?? 0) + 1;
    }

    // Sort buckets by hour
    final sortedBuckets = <String, int>{};
    for (int h = 0; h < 24; h += 2) {
      final key = '$h-${h + 2}';
      sortedBuckets[key] = hourBuckets[key] ?? 0;
    }

    return sortedBuckets;
  }

  /// Get peak hour as formatted string
  String _getPeakHour(Map<String, int> hourlyData) {
    if (hourlyData.isEmpty) return 'N/A';

    var peak = hourlyData.entries.first;
    for (var entry in hourlyData.entries) {
      if (entry.value > peak.value) {
        peak = entry;
      }
    }

    final parts = peak.key.split('-');
    final startHour = int.parse(parts[0]);
    final period = startHour >= 12 ? 'pm' : 'am';
    final displayHour = startHour > 12 ? startHour - 12 : (startHour == 0 ? 12 : startHour);

    return '${displayHour}${period}-${startHour + 2 > 12 ? (startHour + 2 - 12) : (startHour + 2)}${startHour + 2 >= 12 ? 'pm' : 'am'}';
  }

  /// Calculate average tasks per week
  int _calculateAvgPerWeek(int totalCompletions) {
    if (totalCompletions == 0) return 0;
    // Estimate weeks since first completion (assume 52 weeks max)
    return (totalCompletions / 4).toInt(); // Simple average: assume ~4 weeks active
  }

  /// Helper function for max
  int max(int a, int b) => a > b ? a : b;
}
