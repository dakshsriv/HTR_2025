import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

/// Micro-Step Dialog - Forces task breakdown for large tasks.
///
/// When a task is estimated >45 minutes, this dialog blocks completion
/// until the user breaks it into 3-5 micro-steps.
///
/// Design principle: Transform overwhelming tasks into digestible actions.
/// ADHD-I users struggle with task initiation on big projects. Breaking it down
/// removes the barrier to starting.
class MicroStepDialog extends StatefulWidget {
  final Task task;
  final TaskProvider taskProvider;

  const MicroStepDialog({
    required this.task,
    required this.taskProvider,
    super.key,
  });

  @override
  State<MicroStepDialog> createState() => _MicroStepDialogState();
}

class _MicroStepDialogState extends State<MicroStepDialog> {
  late List<TextEditingController> _stepTitleControllers;
  late List<TextEditingController> _stepTimeControllers;
  static const int _minSteps = 3;
  static const int _maxSteps = 5;

  @override
  void initState() {
    super.initState();
    // Initialize with existing steps if editing, or 3 empty ones if creating
    if (widget.task.microSteps.isNotEmpty) {
      // Editing existing steps
      _stepTitleControllers = widget.task.microSteps
          .map((s) => TextEditingController(text: s.title))
          .toList();
      _stepTimeControllers = widget.task.microSteps
          .map((s) => TextEditingController(text: s.timeMinutes.toString()))
          .toList();
    } else {
      // Creating new steps - initialize with 3 empty controllers
      _stepTitleControllers = List.generate(_minSteps, (_) => TextEditingController());
      _stepTimeControllers = List.generate(_minSteps, (_) => TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _stepTitleControllers) {
      controller.dispose();
    }
    for (var controller in _stepTimeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Add another step input field (up to max 5).
  void _addStep() {
    if (_stepTitleControllers.length < _maxSteps) {
      setState(() {
        _stepTitleControllers.add(TextEditingController());
        _stepTimeControllers.add(TextEditingController());
      });
    }
  }

  /// Remove the last step (down to min 3).
  void _removeStep() {
    if (_stepTitleControllers.length > _minSteps) {
      setState(() {
        _stepTitleControllers.removeLast();
        _stepTimeControllers.removeLast();
      });
    }
  }

  /// Get total allocated time from all steps
  int _getTotalAllocatedTime() {
    int total = 0;
    for (var controller in _stepTimeControllers) {
      total += int.tryParse(controller.text.trim()) ?? 0;
    }
    return total;
  }

  /// Submit the micro-steps and update the task.
  Future<void> _submitSteps() async {
    // Collect non-empty steps with validation
    final steps = <MicroStep>[];

    for (int i = 0; i < _stepTitleControllers.length; i++) {
      final title = _stepTitleControllers[i].text.trim();
      final timeText = _stepTimeControllers[i].text.trim();

      if (title.isEmpty) continue; // Skip empty steps

      final timeMinutes = int.tryParse(timeText);
      if (timeMinutes == null || timeMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Step ${i + 1} needs a time estimate (in minutes)'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      steps.add(MicroStep(
        id: i.toString(),
        title: title,
        isCompleted: widget.task.microSteps.length > i
          ? widget.task.microSteps[i].isCompleted
          : false,
        orderIndex: i,
        timeMinutes: timeMinutes,
      ));
    }

    // Need at least 3 steps
    if (steps.length < _minSteps) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 3 steps'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate total time matches task estimate
    final totalTime = _getTotalAllocatedTime();
    final taskTime = widget.task.estimatedMinutes;

    if (totalTime != taskTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Step times add up to $totalTime min, but task is $taskTime min. Adjust to match!',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(milliseconds: 2000),
        ),
      );
      return;
    }

    // Update task with micro-steps
    final updatedTask = widget.task.copyWith(microSteps: steps);
    await widget.taskProvider.updateTask(updatedTask);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Task broken down with time budget'),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filledSteps =
        _stepTitleControllers.where((c) => c.text.trim().isNotEmpty).length;
    final totalAllocated = _getTotalAllocatedTime();
    final taskTime = widget.task.estimatedMinutes;
    final timeRemaining = taskTime - totalAllocated;
    final isTimeBalanced = totalAllocated == taskTime;

    return AlertDialog(
      title: const Text('Break This Down'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                '"${widget.task.title}" is a ${taskTime}-minute task.\n\nLet\'s break it into smaller steps. Budget your time!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),

            // Time budget status bar
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isTimeBalanced ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                border: Border.all(
                  color: isTimeBalanced ? Colors.green : Colors.orange,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time Budget',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '$totalAllocated / $taskTime min',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isTimeBalanced ? Colors.green : Colors.orange,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: taskTime > 0 ? (totalAllocated / taskTime).clamp(0.0, 1.0) : 0,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation(
                        isTimeBalanced ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  if (timeRemaining != 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        timeRemaining > 0
                            ? '$timeRemaining min remaining'
                            : '${timeRemaining.abs()} min over budget',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: timeRemaining > 0 ? Colors.orange : Colors.red,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Micro-step input fields with time sliders
            ..._stepTitleControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final titleController = entry.value;
              final timeController = _stepTimeControllers[index];
              final timeValue = int.tryParse(timeController.text.trim()) ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step title input
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Step ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            prefixIcon: const Icon(Icons.check_circle_outline),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Time slider
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Time:',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$timeValue min',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: timeValue.toDouble(),
                              min: 1,
                              max: taskTime.toDouble(),
                              divisions: taskTime - 1 > 0 ? taskTime - 1 : 1,
                              label: '$timeValue min',
                              onChanged: (value) {
                                setState(() {
                                  timeController.text = value.toInt().toString();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Add/Remove step buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_stepTitleControllers.length > _minSteps)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.remove),
                    label: const Text('Remove'),
                    onPressed: _removeStep,
                  ),
                if (_stepTitleControllers.length < _maxSteps)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    onPressed: _addStep,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress indicator
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$filledSteps / $_minSteps steps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: filledSteps >= _minSteps ? Colors.green : Colors.orange,
                    ),
                  ),
                  if (!isTimeBalanced)
                    Text(
                      isTimeBalanced ? '✓ Time balanced' : '⚠ Adjust time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isTimeBalanced ? Colors.green : Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (filledSteps >= _minSteps && isTimeBalanced) ? _submitSteps : null,
          child: const Text('Done'),
        ),
      ],
    );
  }
}
