import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/completion_record.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/analytics_provider.dart';
import '../services/preferences_service.dart';
import '../widgets/timer_dial.dart';
import '../widgets/celebration_animation.dart';

/// Timer screen for focused task work.
/// Displays dual timers (task total + microstep) or single timer depending on task.
/// Includes pause, skip step (if microsteps), and completion controls.
class TimerScreen extends StatefulWidget {
  final Task task;

  const TimerScreen({
    required this.task,
    super.key,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  @override
  void initState() {
    super.initState();
    // Start the timer when screen opens
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<TimerProvider>().startTimer(widget.task);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Timer'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close timer',
        ),
      ),
      body: Consumer<TimerProvider>(
        builder: (context, timerProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Task title
                Text(
                  widget.task.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Dual timers OR single timer based on microsteps
                if (timerProvider.hasMicrosteps)
                  _buildDualTimerUI(context, timerProvider)
                else
                  _buildSingleTimerUI(context, timerProvider),

                const SizedBox(height: 32),

                // Overtime display
                if (timerProvider.isOvertime)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Overtime: +${timerProvider.overtime.inMinutes}m ${timerProvider.overtime.inSeconds % 60}s',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Control buttons
                _buildControlButtons(context, timerProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build dual timer UI (task + step/break) - side by side
  Widget _buildDualTimerUI(BuildContext context, TimerProvider timerProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Task total timer
        Expanded(
          child: Column(
            children: [
              Text(
                'Total Task Time',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TimerDial(
                timeRemaining: timerProvider.taskTimeRemaining,
                totalTime: Duration(minutes: timerProvider.totalTaskMinutes),
                label: 'Total',
                isOvertime: timerProvider.isOvertime,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Right: Current step/break timer
        Expanded(
          child: Column(
            children: [
              Text(
                timerProvider.isInBreakTime ? 'Break Time' : 'Current Step',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (!timerProvider.isInBreakTime && timerProvider.currentStepName.isNotEmpty)
                Text(
                  timerProvider.currentStepName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              TimerDial(
                timeRemaining: timerProvider.stepTimeRemaining,
                totalTime: Duration(minutes: timerProvider.currentStepMinutes),
                label: timerProvider.isInBreakTime ? 'Break' : 'Step',
                isOvertime: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build single timer UI (task only)
  Widget _buildSingleTimerUI(BuildContext context, TimerProvider timerProvider) {
    return Column(
      children: [
        TimerDial(
          timeRemaining: timerProvider.taskTimeRemaining,
          totalTime: Duration(minutes: timerProvider.totalTaskMinutes),
          label: 'Task Time',
          isOvertime: timerProvider.isOvertime,
        ),
      ],
    );
  }

  /// Build control buttons (pause/resume, skip, etc)
  Widget _buildControlButtons(BuildContext context, TimerProvider timerProvider) {
    return Column(
      children: [
        // Pause/Resume button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: timerProvider.isPaused
                  ? () => timerProvider.resumeTimer()
                  : () => timerProvider.pauseTimer(),
              icon: Icon(timerProvider.isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(timerProvider.isPaused ? 'Resume' : 'Pause'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Skip step button (only if microsteps)
        if (timerProvider.hasMicrosteps)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final isLastStep = timerProvider.skipStep();
                  if (isLastStep) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('No More Steps'),
                        content: const Text('You\'re on the last step! Complete the task to finish.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.skip_next),
                label: const Text('Skip Step'),
              ),
            ],
          ),

        const SizedBox(height: 24),

        // Complete task button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCompletionDialog(context),
            icon: const Icon(Icons.check_circle),
            label: const Text('Task Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// Show completion dialog
  void _showCompletionDialog(BuildContext context) {
    final timerProvider = context.read<TimerProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Task Status'),
        content: Text(
          'Did you complete "${widget.task.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Keep Working'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleNotCompleted(context, timerProvider);
            },
            child: const Text('Not Completed'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleCompleted(context, timerProvider);
            },
            child: const Text('Completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle task completed
  void _handleCompleted(BuildContext context, TimerProvider timerProvider) {
    final prefsService = context.read<PreferencesService>();
    final taskProvider = context.read<TaskProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();

    // Save completion record
    final completionRecord = CompletionRecord(
      taskId: widget.task.id,
      taskTitle: widget.task.title,
      completedAt: DateTime.now(),
      completedOnTime: !timerProvider.isOvertime,
      overtimeMinutes: timerProvider.overtime.inMinutes,
      extensionsUsed: timerProvider.extensionsUsed,
    );
    prefsService.saveCompletionRecord(completionRecord);

    // Mark task as completed in task provider
    taskProvider.completeTask(widget.task.id);

    // Refresh analytics with new completion data
    analyticsProvider.refreshAnalytics();

    timerProvider.clearTimer();
    if (mounted) {
      // Show celebration animation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: CelebrationAnimation(
            onComplete: () {
              Navigator.of(context).pop(); // Close celebration
              Navigator.of(context).pop(); // Close timer screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    timerProvider.isOvertime
                        ? '✓ Task completed! (+${timerProvider.overtime.inMinutes}m overtime)'
                        : '✓ Task completed on time! Great work!',
                  ),
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  /// Handle task not completed - offer extension
  void _handleNotCompleted(BuildContext context, TimerProvider timerProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Need More Time?'),
        content: Text(
          'Would you like a 10-minute extension to complete "${widget.task.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              timerProvider.clearTimer();
              if (mounted) {
                Navigator.of(context).pop(); // Close timer screen
              }
            },
            child: const Text('Defer Task'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              timerProvider.startExtension();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('10-minute extension started'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
            },
            child: const Text('Start Extension'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
