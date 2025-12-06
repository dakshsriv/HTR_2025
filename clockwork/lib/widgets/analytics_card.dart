import 'package:flutter/material.dart';

/// Reusable card widget for displaying analytics metrics.
/// Simple, clean design with title, content, and optional visualization.
class AnalyticsCard extends StatelessWidget {
  final String title;
  final Widget content;
  final Color? accentColor; // Optional color for visual emphasis
  final EdgeInsets padding;

  const AnalyticsCard({
    required this.title,
    required this.content,
    this.accentColor,
    this.padding = const EdgeInsets.all(16.0),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        border: Border.all(
          color: accentColor?.withOpacity(0.3) ?? Colors.grey.shade300,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with accent color
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accentColor ?? Theme.of(context).textTheme.titleMedium?.color,
                  ),
            ),
            const SizedBox(height: 12.0),
            // Content
            content,
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying a percentage with progress bar
class PercentageDisplay extends StatelessWidget {
  final double percentage; // 0-100
  final String label;
  final Color color;

  const PercentageDisplay({
    required this.percentage,
    required this.label,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percentage.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            Text(
              '${clampedPercent.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: LinearProgressIndicator(
            value: clampedPercent / 100,
            minHeight: 8.0,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying a large number metric
class MetricNumber extends StatelessWidget {
  final String number;
  final String label;
  final Color? color;

  const MetricNumber({
    required this.number,
    required this.label,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? Theme.of(context).textTheme.displaySmall?.color,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}

/// Widget for displaying a simple stat row
class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatRow({
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a horizontal bar chart
class BarChartRow extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const BarChartRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
