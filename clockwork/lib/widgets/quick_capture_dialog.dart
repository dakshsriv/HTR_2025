import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

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
  const QuickCaptureDialog({super.key});

  @override
  State<QuickCaptureDialog> createState() => _QuickCaptureDialogState();
}

class _QuickCaptureDialogState extends State<QuickCaptureDialog> {
  late TextEditingController _titleController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _focusNode = FocusNode();
    // Auto-focus the input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Submit the task - minimal validation.
  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return; // Silent ignore - ADHD users get frustrated by error messages
    }

    final taskProvider = context.read<TaskProvider>();
    await taskProvider.addTask(title: title);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Added'),
          duration: Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(20.0),
      content: SizedBox(
        width: 300,
        child: TextField(
          controller: _titleController,
          focusNode: _focusNode,
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
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitTask(),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitTask,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
