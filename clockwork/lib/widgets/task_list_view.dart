import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

/// Task List View - Displays all tasks with completion and deletion.
///
/// Features:
/// - Display all incomplete tasks
/// - Check off completed tasks
/// - Delete tasks
/// - Visual feedback on aging tasks (faded appearance)
class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final tasks = taskProvider.incompleteTasks;

        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tasks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use "Quick Add" to create your first task',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final course = taskProvider.getCourse(task.courseId);
            final isAging = task.isAging();
            final opacity = task.getAgingOpacity();

            final isOverdue = task.dueDate != null &&
                DateTime.now().isAfter(task.dueDate!) &&
                !task.isCompleted;

            return Opacity(
              opacity: opacity,
              child: Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                color: isOverdue
                    ? Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.shade900
                        : Colors.red.shade50
                    : null,
                child: ListTile(
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) {
                      if (value == true) {
                        taskProvider.completeTask(task.id);
                      }
                    },
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isAging ? Colors.grey : null,
                      fontWeight: isOverdue ? FontWeight.w600 : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isAging ? Colors.grey.shade400 : null,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Course badge
                          if (course != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(
                                  course.name,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: course.color.withOpacity(0.3),
                                labelStyle: TextStyle(color: course.color),
                                side: BorderSide(color: course.color),
                              ),
                            ),
                          // Due date with overdue indicator
                          if (task.dueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                isOverdue
                                    ? 'OVERDUE'
                                    : 'Due: ${task.dueDate.toString().split(' ')[0]}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue
                                      ? Colors.red
                                      : Colors.grey.shade600,
                                  fontWeight: isOverdue
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Re-Roll button for overdue tasks
                      if (isOverdue)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Need a Re-Roll?'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            onPressed: () {
                              taskProvider.rerollTask(task.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Rescheduled for tomorrow'),
                                  duration: Duration(milliseconds: 1200),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () {
                          _showDeleteConfirmation(context, task.id, taskProvider);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show delete confirmation dialog.
  void _showDeleteConfirmation(
    BuildContext context,
    String taskId,
    TaskProvider taskProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              taskProvider.deleteTask(taskId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task deleted'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
