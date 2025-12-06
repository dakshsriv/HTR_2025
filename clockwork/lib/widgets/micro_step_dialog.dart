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
  int _selectedStepCount = 0; // No default selection
  bool _stepCountSelected = false;
  int? _lockedStepIndex; // Tracks which step slider is locked (for UI feedback)

  static const int _minSteps = 3;
  static const int _maxSteps = 5;
  static const int _breakTimeBetweenSteps = 2; // 2 minutes of break time between steps

  @override
  void initState() {
    super.initState();
    // Initialize with existing steps if editing
    if (widget.task.microSteps.isNotEmpty) {
      _stepCountSelected = true;
      _selectedStepCount = widget.task.microSteps.length;
      _stepTitleControllers = widget.task.microSteps
          .map((s) => TextEditingController(text: s.title))
          .toList();
      _stepTimeControllers = widget.task.microSteps
          .map((s) => TextEditingController(text: s.timeMinutes.toString()))
          .toList();
    } else {
      // Creating new steps - no controllers yet, will be created after step count selected
      _stepTitleControllers = [];
      _stepTimeControllers = [];
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

  /// Calculate available work time (total time minus breaks between steps)
  int _getAvailableWorkTime(int stepCount) {
    final taskTime = widget.task.estimatedMinutes;
    final breakTime = (stepCount - 1) * _breakTimeBetweenSteps;
    return taskTime - breakTime;
  }

  /// Select number of steps and initialize controllers
  void _selectStepCount(int count) {
    setState(() {
      _selectedStepCount = count;
      _stepCountSelected = true;
      // Initialize title controllers with empty text
      _stepTitleControllers = List.generate(count, (_) => TextEditingController());

      // Initialize time controllers with equal distribution of AVAILABLE work time
      final availableWorkTime = _getAvailableWorkTime(count);
      final timePerStep = availableWorkTime ~/ count;
      final remainderTime = availableWorkTime % count;

      _stepTimeControllers = List.generate(count, (index) {
        int timeForThisStep = timePerStep;
        if (index == count - 1) {
          timeForThisStep += remainderTime; // Add remainder to last step
        }
        return TextEditingController(text: timeForThisStep.toString());
      });
    });
  }

  /// Go back to step count selection
  void _resetStepCount() {
    setState(() {
      _stepCountSelected = false;
      for (var controller in _stepTitleControllers) {
        controller.dispose();
      }
      _stepTitleControllers = [];
    });
  }

  /// Submit the micro-steps and update the task.
  /// Uses user-adjusted times from sliders.
  /// Step names are optional.
  Future<void> _submitSteps() async {
    // Create micro-steps using slider values
    final steps = <MicroStep>[];

    for (int i = 0; i < _stepTitleControllers.length; i++) {
      final title = _stepTitleControllers[i].text.trim();
      final timeMinutes = int.tryParse(_stepTimeControllers[i].text.trim()) ?? 0;

      steps.add(MicroStep(
        id: i.toString(),
        title: title.isEmpty ? 'Step ${i + 1}' : title, // Use generic name if empty
        isCompleted: widget.task.microSteps.length > i
            ? widget.task.microSteps[i].isCompleted
            : false,
        orderIndex: i,
        timeMinutes: timeMinutes,
      ));
    }

    // Update task with micro-steps
    final updatedTask = widget.task.copyWith(microSteps: steps);
    await widget.taskProvider.updateTask(updatedTask);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Sub-steps created'),
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskTime = widget.task.estimatedMinutes;

    // STEP 1: Select number of steps
    if (!_stepCountSelected) {
      return AlertDialog(
        title: const Text('Break This Down'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                '"${widget.task.title}" is a ${taskTime}-minute task.\n\nHow many steps do you want?',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            // Step count buttons (3-5)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int count = _minSteps; count <= _maxSteps; count++)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: _selectedStepCount == count ? Colors.blue : Colors.grey.shade300,
                    ),
                    onPressed: () => _selectStepCount(count),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _selectedStepCount == count ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _stepCountSelected ? _submitSteps : null,
            child: const Text('Next'),
          ),
        ],
      );
    }

    // STEP 2: Optional step names with adjustable time sliders
    final availableWorkTime = _getAvailableWorkTime(_selectedStepCount);

    final totalAllocated = _stepTimeControllers.fold<int>(
      0,
      (sum, controller) => sum + (int.tryParse(controller.text.trim()) ?? 0),
    );
    final unallocatedTime = availableWorkTime - totalAllocated;
    final isTimeExceeded = totalAllocated > availableWorkTime;

    return AlertDialog(
      title: const Text('Name Your Steps & Adjust Time'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time budget status (shows work time and breaks)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTimeExceeded
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                border: Border.all(
                  color: isTimeExceeded ? Colors.red : Colors.green,
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
                        'Work Time Budget',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '$totalAllocated / $availableWorkTime min',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isTimeExceeded ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Includes ${(_selectedStepCount - 1) * _breakTimeBetweenSteps} min of breaks (${_breakTimeBetweenSteps} min between steps)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  if (unallocatedTime > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Unallocated: $unallocatedTime min',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step inputs with time sliders
            ..._stepTitleControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final titleController = entry.value;
              final timeController = _stepTimeControllers[index];

              // Safe value: ensure it's at least 1
              final timeValue = int.tryParse(timeController.text.trim()) ?? 1;
              final safeTimeValue = timeValue < 1 ? 1 : timeValue;

              // Fixed max for this step (independent, doesn't change when others move):
              // 2 * (total task time - break time) / # of subtasks
              final maxForThisStep = (2 * availableWorkTime ~/ _stepTitleControllers.length).clamp(1, availableWorkTime);

              // Check if slider is locked (at its maximum)
              final isLocked = safeTimeValue >= maxForThisStep;

              // Check if current total WOULD exceed budget if we increased this slider
              int currentTotal = 0;
              for (int i = 0; i < _stepTimeControllers.length; i++) {
                currentTotal += int.tryParse(_stepTimeControllers[i].text.trim()) ?? 0;
              }
              final wouldExceedBudget = (currentTotal - safeTimeValue + maxForThisStep) > availableWorkTime;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step name input
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Step ${index + 1} (optional)',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Time slider
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: safeTimeValue.toDouble(),
                                min: 1,
                                max: maxForThisStep.toDouble(),
                                divisions: maxForThisStep > 1 ? maxForThisStep - 1 : 1,
                                label: '$safeTimeValue min',
                                onChanged: (value) {
                                  setState(() {
                                    final capped = value.toInt().clamp(1, maxForThisStep);

                                    // Calculate what total would be if we set this to capped value
                                    int projectedTotal = currentTotal - safeTimeValue + capped;

                                    // If it would exceed budget, cap it and show lock message
                                    int finalValue = capped;
                                    if (projectedTotal > availableWorkTime) {
                                      finalValue = availableWorkTime - (currentTotal - safeTimeValue);
                                      finalValue = finalValue.clamp(1, maxForThisStep);
                                      _lockedStepIndex = index;
                                      // Clear the lock message after 2 seconds
                                      Future.delayed(const Duration(seconds: 2), () {
                                        if (mounted && _lockedStepIndex == index) {
                                          setState(() {
                                            _lockedStepIndex = null;
                                          });
                                        }
                                      });
                                    }

                                    timeController.text = finalValue.toString();
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

                        // Lock message (shows only when user tries to increase past budget)
                        if (_lockedStepIndex == index)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Can\'t increase further—need to reduce another step',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.red.shade600,
                                    fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resetStepCount,
          child: const Text('Back'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: !isTimeExceeded ? _submitSteps : null,
          child: const Text('Create Steps'),
        ),
      ],
    );
  }
}
