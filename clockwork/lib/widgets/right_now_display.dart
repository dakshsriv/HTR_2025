import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'snooze_dialog.dart';
import 'time_remaining_dial.dart';
import 'micro_step_dialog.dart';

/// Right Now Display - Shows the single most important task.
///
/// Design principle: Reduce cognitive load by showing ONE task at a time.
/// The user sees exactly what they should be doing right now, nothing else.
///
/// This widget displays:
/// - The oldest incomplete task (or next action if task is large)
/// - Course color coding
/// - Quick complete/defer actions
/// - Non-judgmental messaging
class RightNowDisplay extends StatelessWidget {
  const RightNowDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final nextTask = taskProvider.nextActiveTask;

        if (nextTask == null) {
          return _buildEmptyState(context);
        }

        final course = taskProvider.getCourse(nextTask.courseId);

        return GestureDetector(
          onTap: () => _showTaskDetail(context, nextTask, taskProvider),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: course?.color ?? Colors.grey,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
              color: (course?.color ?? Colors.grey).withOpacity(0.08),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course badge (if assigned)
                if (course != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: course.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Main task title
                Text(
                  nextTask.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 16),

                // Task description (if available)
                if (nextTask.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      nextTask.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                // Time remaining visual dial (if task has a due date)
                if (nextTask.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TimeRemainingDial(
                      task: nextTask,
                      courseColor: course?.color ?? Colors.grey,
                    ),
                  ),

                // Micro-steps section (if task has them)
                if (nextTask.microSteps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Steps to complete:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${nextTask.microSteps.where((s) => s.isCompleted).length}/${nextTask.microSteps.length}',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => MicroStepDialog(
                                        task: nextTask,
                                        taskProvider: taskProvider,
                                      ),
                                    );
                                  },
                                  tooltip: 'Edit micro-steps',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...nextTask.microSteps.map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: step.isCompleted
                                  ? Colors.green.withOpacity(0.05)
                                  : Colors.grey.withOpacity(0.05),
                              border: Border.all(
                                color: step.isCompleted
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: step.isCompleted,
                                  onChanged: (value) {
                                    taskProvider.toggleMicroStepComplete(
                                      nextTask.id,
                                      step.id,
                                    );
                                  },
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.title,
                                        style: TextStyle(
                                          decoration: step.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (step.timeMinutes > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            '${step.timeMinutes} min',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),

                // Warning if task needs micro-steps but doesn't have them
                if (nextTask.estimatedMinutes > 45 && nextTask.microSteps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        border: Border.all(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Big task? Break it down first!',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Smaller steps = easier to start',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: Colors.orange.shade700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => MicroStepDialog(
                                    task: nextTask,
                                    taskProvider: taskProvider,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.playlist_add),
                              label: const Text('Add micro-steps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Action buttons
                Row(
                  children: [
                    // Complete button (or prompt for micro-steps)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        onPressed: () {
                          // If task needs micro-steps, show dialog instead
                          if (nextTask.estimatedMinutes > 45 &&
                              nextTask.microSteps.isEmpty) {
                            showDialog(
                              context: context,
                              builder: (context) => MicroStepDialog(
                                task: nextTask,
                                taskProvider: taskProvider,
                              ),
                            );
                          } else {
                            taskProvider.completeTask(nextTask.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Great work!'),
                                duration: Duration(milliseconds: 1200),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Defer button
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.schedule),
                        label: const Text('Later'),
                        onPressed: () {
                          _showDeferOptions(context, nextTask, taskProvider);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build empty state when no tasks exist.
  Widget _buildEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'All clear!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tasks right now. Take a break or tap "Quick Add" to add one.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show snooze options for deferring a task.
  /// Provides granular snooze options from 15 seconds to tomorrow.
  /// Designed for ADHD-I users who need quick relief without big commitments.
  void _showDeferOptions(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => SnoozeDialog(
        task: task,
        taskProvider: taskProvider,
      ),
    );
  }

  /// Show detailed task view (placeholder for future expansion).
  void _showTaskDetail(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    // Placeholder - could show detailed task view in future
  }
}
