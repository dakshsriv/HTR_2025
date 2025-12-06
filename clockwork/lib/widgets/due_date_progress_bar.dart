import 'package:flutter/material.dart';

/// Horizontal progress bar showing time used (red, left) vs time available (green, right).
/// Fixed-size bar for all tasks, regardless of actual time budget.
/// Red on left = time elapsed since task creation
/// Green on right = time available until due date
class DueDateProgressBar extends StatelessWidget {
  final DateTime createdAt;
  final DateTime? dueDate;

  const DueDateProgressBar({
    required this.createdAt,
    this.dueDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (dueDate == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final totalDuration = dueDate!.difference(createdAt);
    final elapsedDuration = now.difference(createdAt);

    // Calculate percentage elapsed (clamped 0-100)
    double percentageUsed = 0.0;
    if (totalDuration.inSeconds > 0) {
      percentageUsed = (elapsedDuration.inSeconds / totalDuration.inSeconds) * 100;
      percentageUsed = percentageUsed.clamp(0, 100);
    }

    // If task is overdue, show 100% red
    final isOverdue = now.isAfter(dueDate!);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 6,
          child: Stack(
            children: [
              // Background (green = available time)
              Container(
                color: Colors.green.shade400,
              ),
              // Foreground (red = elapsed time)
              Container(
                width: double.infinity * (percentageUsed / 100),
                color: isOverdue ? Colors.red.shade600 : Colors.red.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
