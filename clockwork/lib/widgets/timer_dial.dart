import 'package:flutter/material.dart';
import 'dart:math';

/// Visual timer dial displaying remaining time as a shrinking circle.
/// Color changes based on time remaining: green → yellow → red.
class TimerDial extends StatelessWidget {
  final Duration timeRemaining;
  final Duration totalTime;
  final String label;
  final bool isOvertime;

  const TimerDial({
    required this.timeRemaining,
    required this.totalTime,
    required this.label,
    this.isOvertime = false,
    super.key,
  });

  /// Calculate percentage of time remaining (0.0 to 1.0)
  double _getTimeRemainingPercent() {
    if (totalTime.inSeconds <= 0) return 0.0;
    return max(0, timeRemaining.inSeconds) / totalTime.inSeconds;
  }

  /// Get color based on time remaining
  Color _getColor() {
    if (isOvertime) return Colors.red;

    final percent = _getTimeRemainingPercent();
    if (percent > 0.5) {
      return Colors.green;
    } else if (percent > 0.25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  /// Format duration as MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final percent = _getTimeRemainingPercent();
    final color = _getColor();
    final remainingText = _formatDuration(timeRemaining);
    final totalText = _formatDuration(totalTime);

    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle (static, light gray)
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
            ),

            // Animated shrinking filled arc
            CustomPaint(
              size: const Size(220, 220),
              painter: _TimerArcPainter(
                percent: percent,
                color: color,
              ),
            ),

            // Center text showing time remaining
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  remainingText,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
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

/// Custom painter for the timer arc
class _TimerArcPainter extends CustomPainter {
  final double percent; // 0.0 to 1.0
  final Color color;

  _TimerArcPainter({
    required this.percent,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw filled arc (pie slice from top, clockwise)
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      2 * pi * percent, // Sweep angle proportional to remaining time
      true,
      paint,
    );

    // Draw border circle (solid color)
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(_TimerArcPainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.color != color;
  }
}
