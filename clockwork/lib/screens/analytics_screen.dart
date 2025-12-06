import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_card.dart';

/// Analytics dashboard showing task completion patterns and metrics.
/// Displays 7 key metrics focused on ADHD-relevant insights.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AnalyticsProvider>().refreshAnalytics();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics updated'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
            tooltip: 'Refresh analytics',
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analyticsProvider, _) {
          final analytics = analyticsProvider.analytics;

          // Handle empty state
          if (analytics.totalCompletions == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete some tasks to see your analytics!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                // Card 1: On-Time Performance (Primary Metric)
                AnalyticsCard(
                  title: 'On-Time Performance',
                  accentColor: Colors.green,
                  content: PercentageDisplay(
                    percentage: analytics.onTimePercentage,
                    label: '${analytics.thisWeekOnTime} of ${analytics.thisWeekCompletions} this week',
                    color: Colors.green,
                  ),
                ),

                // Card 2: Current Streak
                AnalyticsCard(
                  title: 'Current Streak',
                  accentColor: Colors.orange,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          MetricNumber(
                            number: '${analytics.currentStreak}',
                            label: 'days',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StatRow(
                        label: 'Best streak',
                        value: '${analytics.bestStreak} days',
                      ),
                    ],
                  ),
                ),

                // Card 3: This Week Summary
                AnalyticsCard(
                  title: 'This Week',
                  accentColor: Colors.blue,
                  content: Column(
                    children: [
                      StatRow(
                        label: 'Total completed',
                        value: '${analytics.thisWeekCompletions} tasks',
                      ),
                      StatRow(
                        label: 'On-time',
                        value: '${analytics.thisWeekOnTime} tasks',
                        valueColor: Colors.green,
                      ),
                      StatRow(
                        label: 'Late',
                        value: '${analytics.thisWeekLate} tasks',
                        valueColor: Colors.orange,
                      ),
                      const SizedBox(height: 4),
                      StatRow(
                        label: 'Avg overtime',
                        value: '+${analytics.thisWeekAvgOvertimeMinutes} min',
                        valueColor: Colors.orange,
                      ),
                    ],
                  ),
                ),

                // Card 4: Total Completions
                AnalyticsCard(
                  title: 'Total Completions',
                  accentColor: Colors.indigo,
                  content: Column(
                    children: [
                      StatRow(
                        label: 'This month',
                        value: '${analytics.thisMonthCompletions}',
                      ),
                      StatRow(
                        label: 'All-time',
                        value: '${analytics.totalCompletions}',
                        valueColor: Colors.indigo,
                      ),
                      const SizedBox(height: 4),
                      StatRow(
                        label: 'Avg per week',
                        value: '${analytics.avgPerWeek}',
                      ),
                    ],
                  ),
                ),

                // Card 5: Typical Overtime
                AnalyticsCard(
                  title: 'Typical Overtime',
                  accentColor: Colors.orange,
                  content: Column(
                    children: [
                      StatRow(
                        label: 'Average per task',
                        value: '+${analytics.avgOvertimeMinutes} min',
                        valueColor: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Distribution',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      BarChartRow(
                        label: 'On-time (0 min)',
                        value: analytics.overtimeDistribution['0'] ?? 0,
                        maxValue: analytics.totalCompletions,
                        color: Colors.green,
                      ),
                      BarChartRow(
                        label: 'Mild (5-15 min)',
                        value: analytics.overtimeDistribution['5-15'] ?? 0,
                        maxValue: analytics.totalCompletions,
                        color: Colors.yellow.shade700,
                      ),
                      BarChartRow(
                        label: 'Significant (15+ min)',
                        value: analytics.overtimeDistribution['15+'] ?? 0,
                        maxValue: analytics.totalCompletions,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),

                // Card 6: Peak Productivity Hours
                AnalyticsCard(
                  title: 'Peak Productivity Hours',
                  accentColor: Colors.purple,
                  content: Column(
                    children: [
                      _buildHourlyChart(context, analytics.hourlyDistribution),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.purple),
                            const SizedBox(width: 8),
                            Text(
                              'Most productive: ${analytics.peakHour}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Card 7: Time Estimation Accuracy
                AnalyticsCard(
                  title: 'Time Estimation Accuracy',
                  accentColor: Colors.teal,
                  content: Column(
                    children: [
                      StatRow(
                        label: 'Avg estimated',
                        value: '${analytics.estimatedAvgMinutes} min',
                      ),
                      StatRow(
                        label: 'Avg actual',
                        value: '${analytics.actualAvgMinutes} min',
                        valueColor: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, size: 16, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your pattern: ${analytics.estimationRatio.toStringAsFixed(1)}x longer than estimated',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build hourly distribution chart
  Widget _buildHourlyChart(BuildContext context, Map<String, int> hourlyData) {
    if (hourlyData.isEmpty) {
      return Text(
        'No data',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
      );
    }

    final maxCount = hourlyData.values.isNotEmpty ? hourlyData.values.reduce((a, b) => a > b ? a : b) : 1;
    final filteredData = hourlyData.entries.where((e) => e.value > 0).toList();

    return Column(
      children: filteredData.map((entry) {
        final hour = entry.key;
        final count = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: BarChartRow(
            label: hour,
            value: count,
            maxValue: maxCount,
            color: Colors.purple,
          ),
        );
      }).toList(),
    );
  }
}
