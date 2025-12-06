import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../models/task.dart';

/// Visual Time Remaining - A shrinking circle showing time left.
///
/// Designed to combat time blindness in ADHD-I by making abstract time VISIBLE.
/// The circle shrinks as time passes, creating urgency through physics.
///
/// Features:
/// - Animated shrinking circle proportional to time remaining
/// - Color gradient from green (safe) to red (urgent)
/// - Real-time updates every second
/// - Percentage text showing time remaining
class TimeRemainingDial extends StatefulWidget {
  final Task task;
  final Color courseColor;

  const TimeRemainingDial({
    required this.task,
    required this.courseColor,
    super.key,
  });

  @override
  State<TimeRemainingDial> createState() => _TimeRemainingDialState();
}

class _TimeRemainingDialState extends State<TimeRemainingDial> {
  late Timer _updateTimer;

  @override
  void initState() {
    super.initState();
    // Update the dial every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  /// Calculate percentage of time remaining (0.0 to 1.0).
  double _getTimeRemainingPercent() {
    if (widget.task.dueDate == null) {
      return 0; // No time limit
    }

    final now = DateTime.now();
    final createdAt = widget.task.createdAt;
    final dueDate = widget.task.dueDate!;

    // If already overdue, return 0
    if (now.isAfter(dueDate)) {
      if (now.difference(createdAt) < const Duration(minutes: 1)) {
        return 1.0; // Grace period for newly created tasks
      }
      return 0;
    }

    // Total duration from creation to due date
    final totalDuration = dueDate.difference(createdAt);
    // Remaining duration from now to due date
    final remainingDuration = dueDate.difference(now);

    // Calculate percentage
    if (totalDuration.inSeconds <= 0) return 0;
    return remainingDuration.inSeconds / totalDuration.inSeconds;
  }

  /// Get color based on time remaining percentage.
  /// Green (safe) -> Yellow (warning) -> Red (urgent)
  /// For newly created tasks (<1 min old), use blue to indicate "fresh/ready"
  Color _getColorForPercent(double percent) {
    final now = DateTime.now();
    final age = now.difference(widget.task.createdAt);

    // Brand new task - blue to indicate "ready to work on"
    if (age < const Duration(minutes: 1)) {
      return Colors.blue;
    }

    if (percent > 0.5) {
      // Green zone (50-100%)
      return Colors.green;
    } else if (percent > 0.25) {
      // Yellow zone (25-50%)
      return Colors.orange;
    } else {
      // Red zone (0-25%)
      return Colors.red;
    }
  }

  /// Format time remaining as human-readable string.
  String _getTimeRemainingText(double percent) {
    if (widget.task.dueDate == null) {
      return 'No deadline';
    }

    final now = DateTime.now();
    final dueDate = widget.task.dueDate!;

    if (now.isAfter(dueDate)) {
      if (now.difference(widget.task.createdAt) < const Duration(minutes: 1)) {
        return 'Starting now';
      }
      return 'Overdue';
    }

    final remaining = dueDate.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else if (minutes > 0) {
      return '${minutes}m left';
    } else {
      return 'Soon!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentRemaining = _getTimeRemainingPercent();
    final color = _getColorForPercent(percentRemaining);
    final timeText = _getTimeRemainingText(percentRemaining);

    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle (static)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
            ),

            // Animated shrinking circle
            CustomPaint(
              size: const Size(200, 200),
              painter: _TimeDialPainter(
                percent: percentRemaining,
                color: color,
                courseColor: widget.courseColor,
              ),
            ),

            // Center text showing time remaining
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(percentRemaining * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the shrinking time dial.
class _TimeDialPainter extends CustomPainter {
  final double percent; // 0.0 to 1.0
  final Color color;
  final Color courseColor;

  _TimeDialPainter({
    required this.percent,
    required this.color,
    required this.courseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw filled circle arc from top, going clockwise
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw arc as wedge (like a pie slice)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      2 * pi * percent, // Sweep angle proportional to remaining time
      true,
      paint,
    );

    // Draw border circle
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(_TimeDialPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.color != color ||
        oldDelegate.courseColor != courseColor;
  }
}
