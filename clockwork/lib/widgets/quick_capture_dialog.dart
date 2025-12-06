import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

/// Quick Capture Dialog - Ultra-minimal friction task input.
///
/// Design principle: ADHD-I users need the path of least resistance.
/// - Only one field: task title
/// - Submit with Enter key (no button needed)
/// - Auto-closes and shows success
/// - Zero decision paralysis
///
/// This is intentionally bare-bones. Complexity ruins the experience.
class QuickCaptureDialog extends StatefulWidget {
  final VoidCallback? onTaskAdded;

  const QuickCaptureDialog({
    this.onTaskAdded,
    super.key,
  });

  @override
  State<QuickCaptureDialog> createState() => _QuickCaptureDialogState();
}

class _QuickCaptureDialogState extends State<QuickCaptureDialog> {
  late TextEditingController _titleController;
  late TextEditingController _minutesController;
  late List<TextEditingController> _stepTitleControllers;
  late List<TextEditingController> _stepTimeControllers;
  late FocusNode _titleFocusNode;
  late FocusNode _timesFocusNode;
  late DateTime _selectedDueDate;

  static const int _minSteps = 3;
  static const int _maxSteps = 5;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _minutesController = TextEditingController();
    _titleFocusNode = FocusNode();
    _timesFocusNode = FocusNode();
    _stepTitleControllers = [];
    _stepTimeControllers = [];
    // Default due date: tomorrow at 11:59 AM
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDueDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 11, 59);
    // Auto-focus the title field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_titleFocusNode);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _minutesController.dispose();
    _titleFocusNode.dispose();
    _timesFocusNode.dispose();
    for (var controller in _stepTitleControllers) {
      controller.dispose();
    }
    for (var controller in _stepTimeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Add a micro-step field
  void _addMicroStep() {
    if (_stepTitleControllers.length < _maxSteps) {
      setState(() {
        _stepTitleControllers.add(TextEditingController());
        // Initialize time controller with a default value (not empty)
        final estimatedMinutes = int.tryParse(_minutesController.text.trim()) ?? 0;
        final defaultTime = estimatedMinutes > 0 ? (estimatedMinutes ~/ (_maxSteps)).toString() : '15';
        _stepTimeControllers.add(TextEditingController(text: defaultTime));
      });
    }
  }

  /// Remove a micro-step field
  void _removeMicroStep() {
    if (_stepTitleControllers.length > 0) {
      setState(() {
        _stepTitleControllers.removeLast().dispose();
        _stepTimeControllers.removeLast().dispose();
      });
    }
  }

  /// Get total time allocated to micro-steps
  int _getTotalMicroStepTime() {
    int total = 0;
    for (var controller in _stepTimeControllers) {
      total += int.tryParse(controller.text.trim()) ?? 0;
    }
    return total;
  }

  /// Format date and time for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final tomorrowOnly = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    String dateStr;
    if (dateOnly == DateTime(now.year, now.month, now.day)) {
      dateStr = 'Today';
    } else if (dateOnly == tomorrowOnly) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${date.month}/${date.day}/${date.year}';
    }

    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  /// Submit the task - requires title and estimated time only.
  /// Micro-steps will be set up in a separate dialog if needed.
  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    final minutesText = _minutesController.text.trim();

    if (title.isEmpty) {
      return; // Silent ignore - ADHD users get frustrated by error messages
    }

    // Require estimated time
    final estimatedMinutes = int.tryParse(minutesText);
    if (estimatedMinutes == null || estimatedMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('How many minutes will this take?'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final taskProvider = context.read<TaskProvider>();

    await taskProvider.addTask(
      title: title,
      dueDate: _selectedDueDate,
      estimatedMinutes: estimatedMinutes,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Task created'),
          duration: Duration(milliseconds: 800),
        ),
      );
      // Notify parent that task was added
      widget.onTaskAdded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimatedMinutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final needsMicroSteps = estimatedMinutes > 45;

    return AlertDialog(
      contentPadding: const EdgeInsets.all(20.0),
      title: const Text('Quick Add Task'),
      content: SizedBox(
        width: 350,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task title input
              Text(
                'Task',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: InputDecoration(
                  hintText: 'What do you need to do?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
                maxLines: null,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _timesFocusNode.requestFocus(),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Estimated time input (REQUIRED)
              Text(
                'How long will it take? (required)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _minutesController,
                focusNode: _timesFocusNode,
                decoration: InputDecoration(
                  hintText: '30',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  suffixText: 'minutes',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Due date picker
              Text(
                'When is it due? (required)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    // Now pick the time
                    if (mounted) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_selectedDueDate),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _selectedDueDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _formatDate(_selectedDueDate),
                ),
              ),
              const SizedBox(height: 12),

              // Info message
              if (needsMicroSteps)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 20, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Break it down!',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add sub-steps after creating the task',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tasks under 45 min don\'t need sub-steps',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.blue.shade700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitTask,
          child: const Text('Create Task'),
        ),
      ],
    );
  }
}
