import 'package:flutter/material.dart';

/// Horizontal progress bar showing time used (red, left) vs time available (green, right).
/// Red on left = time elapsed since task creation
/// Green on right = time available until due date
/// Displays remaining time in days, hours, and minutes below the bar.
class DueDateProgressBar extends StatelessWidget {
  final DateTime createdAt;
  final DateTime? dueDate;

  const DueDateProgressBar({
    required this.createdAt,
    this.dueDate,
    super.key,
  });

  String _formatTimeRemaining(Duration duration) {
    if (duration.isNegative) {
      return 'OVERDUE';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days day${days != 1 ? 's' : ''} ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '$hours hour${hours != 1 ? 's' : ''} ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dueDate == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final totalDuration = dueDate!.difference(createdAt);
    final elapsedDuration = now.difference(createdAt);
    final remainingDuration = dueDate!.difference(now);

    // Calculate percentage elapsed (clamped 0-100)
    double percentageUsed = 0.0;
    if (totalDuration.inSeconds > 0) {
      percentageUsed = (elapsedDuration.inSeconds / totalDuration.inSeconds) * 100;
      percentageUsed = percentageUsed.clamp(0, 100);
    }

    // If task is overdue, show 100% red
    final isOverdue = remainingDuration.isNegative;

    // Show minimum 3% red to prevent all-green bar when task just created
    final displayPercentageUsed = percentageUsed > 0 && percentageUsed < 3 ? 3.0 : percentageUsed;

    // Indicate abundance of time (>90% remaining)
    final hasPlentyOfTime = percentageUsed < 10;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              width: double.infinity,
              child: Stack(
                children: [
                  // Background (green = available time)
                  Container(
                    color: Colors.green.shade400,
                  ),
                  // Foreground (red = elapsed time)
                  FractionallySizedBox(
                    widthFactor: displayPercentageUsed / 100,
                    child: Container(
                      color: isOverdue ? Colors.red.shade600 : Colors.red.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time remaining: ${_formatTimeRemaining(remainingDuration)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isOverdue ? Colors.red.shade600 : Colors.grey.shade600,
                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (hasPlentyOfTime)
                Text(
                  '✓ Plenty of time',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
