import 'package:flutter/material.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

/// Snooze Dialog - Granular time options for deferring tasks.
///
/// Provides quick snooze options from 15 seconds to tomorrow.
/// Designed for ADHD-I users who need instant relief without decision paralysis.
/// Larger buttons, clear labels, easy to tap quickly.
class SnoozeDialog extends StatelessWidget {
  final Task task;
  final TaskProvider taskProvider;

  const SnoozeDialog({
    required this.task,
    required this.taskProvider,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Snooze Task'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('When should this task reappear?'),
              const SizedBox(height: 16),
              // Simple vertical list of snooze options
              _SnoozeButton(
                label: '15 sec',
                duration: const Duration(seconds: 15),
                task: task,
                taskProvider: taskProvider,
                context: context,
              ),
              _SnoozeButton(
                label: '1 min',
                duration: const Duration(minutes: 1),
                task: task,
                taskProvider: taskProvider,
                context: context,
              ),
              _SnoozeButton(
                label: '5 min',
                duration: const Duration(minutes: 5),
                task: task,
                taskProvider: taskProvider,
                context: context,
              ),
              _SnoozeButton(
                label: '15 min',
                duration: const Duration(minutes: 15),
                task: task,
                taskProvider: taskProvider,
                context: context,
              ),
              _SnoozeButton(
                label: '30 min',
                duration: const Duration(minutes: 30),
                task: task,
                taskProvider: taskProvider,
                context: context,
              ),
              _SnoozeButton(
                label: '1 hour',
                duration: const Duration(hours: 1),
                task: task,
                taskProvider: taskProvider,
                context: context,
              ),
              _SnoozeButton(
                label: '3 hours',
                duration: const Duration(hours: 3),
                task: task,
                taskProvider: taskProvider,
                context: context,
              ),
              _SnoozeButton(
                label: 'Tomorrow',
                duration: const Duration(days: 1),
                task: task,
                taskProvider: taskProvider,
                context: context,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Individual snooze button.
class _SnoozeButton extends StatelessWidget {
  final String label;
  final Duration duration;
  final Task task;
  final TaskProvider taskProvider;
  final BuildContext context;

  const _SnoozeButton({
    required this.label,
    required this.duration,
    required this.task,
    required this.taskProvider,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _deferTask(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  /// Defer the task by the selected duration.
  /// Uses the context parameter passed in to avoid BuildContext issues.
  void _deferTask(BuildContext ctx) {
    final newDueDate = DateTime.now().add(duration);
    taskProvider.updateTask(task.copyWith(dueDate: newDueDate));

    // Pop the dialog first
    Navigator.of(ctx).pop();

    // Then show snackbar (use a microtask delay to ensure dialog is closed)
    Future.microtask(() {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Snoozed for $label'),
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }
}
