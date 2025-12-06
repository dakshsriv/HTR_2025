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

  /// Submit the task - requires title and estimated time.
  /// If task is >45 min and has micro-steps, validates time budget matches.
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

    // If task is >45 min, require micro-steps
    if (estimatedMinutes > 45) {
      // Collect filled micro-steps with validation
      final microSteps = <MicroStep>[];

      for (int i = 0; i < _stepTitleControllers.length; i++) {
        final stepTitle = _stepTitleControllers[i].text.trim();
        final stepTimeText = _stepTimeControllers[i].text.trim();

        if (stepTitle.isEmpty) continue; // Skip empty steps

        final stepTime = int.tryParse(stepTimeText);
        if (stepTime == null || stepTime <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Step ${i + 1} needs a time estimate'),
              backgroundColor: Colors.orange,
              duration: const Duration(milliseconds: 1200),
            ),
          );
          return;
        }

        microSteps.add(MicroStep(
          id: i.toString(),
          title: stepTitle,
          orderIndex: i,
          timeMinutes: stepTime,
        ));
      }

      // Must have at least 3 steps
      if (microSteps.length < _minSteps) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tasks over 45 min need at least 3 steps'),
            backgroundColor: Colors.orange,
            duration: Duration(milliseconds: 1200),
          ),
        );
        return;
      }

      // Total time must match task estimate
      final totalMicroTime = _getTotalMicroStepTime();
      if (totalMicroTime != estimatedMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Steps total $totalMicroTime min, but task is $estimatedMinutes min',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(milliseconds: 1500),
          ),
        );
        return;
      }
    }

    final taskProvider = context.read<TaskProvider>();
    // Set due date to 8 hours from now so task appears immediately in "Right Now"
    final now = DateTime.now();
    final dueDate = now.add(const Duration(hours: 8));

    // Create task with micro-steps if they exist
    final microSteps = <MicroStep>[];
    for (int i = 0; i < _stepTitleControllers.length; i++) {
      final stepTitle = _stepTitleControllers[i].text.trim();
      final stepTimeText = _stepTimeControllers[i].text.trim();

      if (stepTitle.isNotEmpty) {
        final stepTime = int.tryParse(stepTimeText) ?? 0;
        if (stepTime > 0) {
          microSteps.add(MicroStep(
            id: i.toString(),
            title: stepTitle,
            orderIndex: i,
            timeMinutes: stepTime,
          ));
        }
      }
    }

    final newTask = await taskProvider.addTask(
      title: title,
      dueDate: dueDate,
      estimatedMinutes: estimatedMinutes,
    );

    // If micro-steps were added, update the task
    if (microSteps.isNotEmpty) {
      final updatedTask = newTask.copyWith(microSteps: microSteps);
      await taskProvider.updateTask(updatedTask);
    }

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
    final microStepsFilledCount = _stepTitleControllers.where((c) => c.text.trim().isNotEmpty).length;
    final microStepTimesTotal = _getTotalMicroStepTime();

    return AlertDialog(
      contentPadding: const EdgeInsets.all(20.0),
      title: const Text('Quick Add Task'),
      content: SizedBox(
        width: 400,
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
                onChanged: (_) => setState(() {}), // Refresh UI when time changes
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Info message for large tasks
              if (needsMicroSteps && _stepTitleControllers.isEmpty)
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
                              'Add 3+ steps below to make it less overwhelming',
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
              else if (!needsMicroSteps && _stepTitleControllers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'No steps needed for tasks under 45 min — you can remove them if you like',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                  ),
                )
              else if (!needsMicroSteps)
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
                          'Tasks under 45 min don\'t need steps',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.blue.shade700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Micro-steps section (only show if task > 45 min)
              if (needsMicroSteps) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    border: Border.all(
                      color: microStepsFilledCount >= _minSteps && microStepTimesTotal == estimatedMinutes
                          ? Colors.green
                          : Colors.orange,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time budget status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Break into steps',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '$microStepTimesTotal / $estimatedMinutes min',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: microStepTimesTotal == estimatedMinutes && microStepsFilledCount >= _minSteps
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Micro-step input cards
                      ..._stepTitleControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final titleController = entry.value;
                        final timeController = _stepTimeControllers[index];
                        // Ensure timeValue is at least 1 to avoid slider errors
                        final timeValue = int.tryParse(timeController.text.trim()) ?? 1;
                        final safeTimeValue = timeValue < 1 ? 1 : timeValue;

                        // Calculate remaining budget after other steps
                        int otherStepsTime = 0;
                        for (int i = 0; i < _stepTimeControllers.length; i++) {
                          if (i != index) {
                            otherStepsTime += int.tryParse(_stepTimeControllers[i].text.trim()) ?? 0;
                          }
                        }
                        final remainingBudget = estimatedMinutes - otherStepsTime;
                        final maxForThisStep = remainingBudget > 0 ? remainingBudget : 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.08),
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Step title
                                TextField(
                                  controller: titleController,
                                  decoration: InputDecoration(
                                    hintText: 'Step ${index + 1}',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),

                                // Time slider with remaining budget capping
                                Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: safeTimeValue.toDouble(),
                                        min: 1,
                                        max: maxForThisStep.toDouble(),
                                        divisions: maxForThisStep - 1 > 0 ? maxForThisStep - 1 : 1,
                                        label: '$safeTimeValue min',
                                        onChanged: (value) {
                                          setState(() {
                                            // Cap at remaining budget
                                            final capped = value.toInt().clamp(1, maxForThisStep);
                                            timeController.text = capped.toString();
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$safeTimeValue min',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      // Add/Remove buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_stepTitleControllers.isNotEmpty)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.remove),
                              label: const Text('Remove'),
                              onPressed: _removeMicroStep,
                            ),
                          if (_stepTitleControllers.length < _maxSteps)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Step'),
                              onPressed: _addMicroStep,
                            ),
                        ],
                      ),

                      // Progress indicator
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$microStepsFilledCount / $_minSteps steps',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: microStepsFilledCount >= _minSteps ? Colors.green : Colors.orange,
                            ),
                          ),
                          if (microStepTimesTotal == estimatedMinutes && microStepsFilledCount >= _minSteps)
                            const Row(
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Ready!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
