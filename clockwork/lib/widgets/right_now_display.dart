import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

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
          return _buildEmptyState();
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

                // Due date (if available)
                if (nextTask.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${nextTask.dueDate.toString().split(' ')[0]}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                // Action buttons
                Row(
                  children: [
                    // Complete button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        onPressed: () {
                          taskProvider.completeTask(nextTask.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Great work!'),
                              duration: Duration(milliseconds: 1200),
                            ),
                          );
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
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'All clear!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No tasks right now. Take a break or tap "Quick Add" to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show options for deferring a task.
  void _showDeferOptions(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Task'),
        content: const Text('When should this task reappear?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deferTask(context, task, taskProvider, Duration(hours: 1));
            },
            child: const Text('1 Hour'),
          ),
          TextButton(
            onPressed: () {
              _deferTask(context, task, taskProvider, Duration(hours: 3));
            },
            child: const Text('3 Hours'),
          ),
          TextButton(
            onPressed: () {
              _deferTask(context, task, taskProvider, Duration(days: 1));
            },
            child: const Text('Tomorrow'),
          ),
        ],
      ),
    );
  }

  /// Defer a task by updating its due date.
  void _deferTask(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
    Duration delay,
  ) {
    final newDueDate = DateTime.now().add(delay);
    taskProvider.updateTask(task.copyWith(dueDate: newDueDate));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task snoozed'),
        duration: Duration(milliseconds: 1200),
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
