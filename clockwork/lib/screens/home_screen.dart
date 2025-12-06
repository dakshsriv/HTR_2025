import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/quick_capture_dialog.dart';
import '../widgets/right_now_display.dart';
import '../widgets/task_list_view.dart';
import '../widgets/due_date_progress_bar.dart';
import 'analytics_screen.dart';

/// Home screen - main entry point of the app.
///
/// Features:
/// - Quick Capture button (always visible)
/// - Right Now task display
/// - Task list view
/// - Navigation to settings/courses
/// - Theme toggle
class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final Function(double) onTextScaleChange;
  final double textScale;

  const HomeScreen({
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.onTextScaleChange,
    required this.textScale,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clockwork: Stop Planning, Start Doing'),
        elevation: 0,
        centerTitle: true,
        actions: [
          // Theme toggle button
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: widget.onThemeToggle,
              tooltip: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      // Quick Capture button - positioned above bottom nav
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickCaptureDialog,
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
        tooltip: 'Quickly capture a new task',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Build the appropriate page based on navigation index.
  Widget _buildBody() {
    switch (_selectedNavIndex) {
      case 0:
        return const _HomeTab();
      case 1:
        return const TaskListView();
      case 2:
        return const AnalyticsScreen();
      case 3:
        return _SettingsTab(
          onThemeToggle: widget.onThemeToggle,
          isDarkMode: widget.isDarkMode,
          onTextScaleChange: widget.onTextScaleChange,
          textScale: widget.textScale,
        );
      default:
        return const _HomeTab();
    }
  }

  /// Show the quick capture dialog.
  void _showQuickCaptureDialog() {
    showDialog(
      context: context,
      builder: (context) => QuickCaptureDialog(
        onTaskAdded: () {
          // Automatically switch to Home tab after adding a task
          setState(() {
            _selectedNavIndex = 0;
          });
        },
      ),
    );
  }
}

/// Home tab - displays Right Now task and quick overview.
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What should you do right now?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const RightNowDisplay(),
          const SizedBox(height: 32),
          Text(
            'Upcoming Tasks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Consumer<TaskProvider>(
            builder: (context, taskProvider, _) {
              final upcomingTasks = taskProvider.incompleteTasks.take(5).toList();
              if (upcomingTasks.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No tasks yet. Tap "Quick Add" to get started!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingTasks.length,
                itemBuilder: (context, index) {
                  final task = upcomingTasks[index];
                  final course = taskProvider.getCourse(task.courseId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
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
                              ),
                            ),
                            subtitle: course != null
                                ? Chip(
                                    label: Text(course.name),
                                    backgroundColor: course.color.withOpacity(0.3),
                                    labelStyle: TextStyle(color: course.color),
                                  )
                                : null,
                            trailing: ElevatedButton(
                              onPressed: () {
                                context.read<TimerProvider>().switchTask(task);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Now working on: ${task.title}'),
                                    duration: const Duration(milliseconds: 1200),
                                  ),
                                );
                              },
                              child: const Text('Do this'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: DueDateProgressBar(
                              createdAt: task.createdAt,
                              dueDate: task.dueDate,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Settings tab - Manage app theme and text size.
class _SettingsTab extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  final Function(double) onTextScaleChange;
  final double textScale;

  const _SettingsTab({
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.onTextScaleChange,
    required this.textScale,
  });

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late double _tempTextScale;

  @override
  void initState() {
    super.initState();
    _tempTextScale = widget.textScale;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appearance section
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Theme toggle
          Card(
            child: ListTile(
              leading: Icon(
                widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(
                widget.isDarkMode ? 'Enabled' : 'Disabled',
              ),
              trailing: Switch(
                value: widget.isDarkMode,
                onChanged: (_) => widget.onThemeToggle(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Text Size section
          Text(
            'Text Size',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Text size slider with preview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview text with temporary scale
                  Text(
                    'Preview: This is how your text will look',
                    textScaleFactor: _tempTextScale,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Slider - only updates preview, not global
                  Row(
                    children: [
                      const Icon(Icons.text_decrease),
                      Expanded(
                        child: Slider(
                          value: _tempTextScale,
                          min: 0.8,
                          max: 1.5,
                          divisions: 7,
                          label: '${(_tempTextScale * 100).toStringAsFixed(0)}%',
                          onChanged: (value) {
                            setState(() {
                              _tempTextScale = value;
                            });
                          },
                        ),
                      ),
                      const Icon(Icons.text_increase),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Show current setting and temp setting
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current: ${(widget.textScale * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Preview: ${(_tempTextScale * 100).toStringAsFixed(0)}% (${_getTempTextSizeLabel()})',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // Save button
                      if (_tempTextScale != widget.textScale)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Save'),
                          onPressed: () {
                            widget.onTextScaleChange(_tempTextScale);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Text size updated'),
                                duration: Duration(milliseconds: 1200),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // App info section
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clockwork: Stop Planning, Start Doing',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A task management app designed for ADHD-I students.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get human-readable text size label for current global setting.
  String _getTextSizeLabel() {
    if (widget.textScale < 0.9) return 'Small';
    if (widget.textScale < 1.1) return 'Normal';
    if (widget.textScale < 1.3) return 'Large';
    return 'Extra Large';
  }

  /// Get human-readable text size label for temporary preview setting.
  String _getTempTextSizeLabel() {
    if (_tempTextScale < 0.9) return 'Small';
    if (_tempTextScale < 1.1) return 'Normal';
    if (_tempTextScale < 1.3) return 'Large';
    return 'Extra Large';
  }
}
