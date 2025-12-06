import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/quick_capture_dialog.dart';
import '../widgets/right_now_display.dart';
import '../widgets/task_list_view.dart';

/// Home screen - main entry point of the app.
///
/// Features:
/// - Quick Capture button (always visible)
/// - Right Now task display
/// - Task list view
/// - Navigation to settings/courses
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flow Anchor'),
        elevation: 0,
        centerTitle: true,
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
            icon: Icon(Icons.school),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      // Quick Capture button - always available
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickCaptureDialog,
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
        tooltip: 'Quickly capture a new task',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
        return const _CoursesTab();
      case 3:
        return const _SettingsTab();
      default:
        return const _HomeTab();
    }
  }

  /// Show the quick capture dialog.
  void _showQuickCaptureDialog() {
    showDialog(
      context: context,
      builder: (context) => const QuickCaptureDialog(),
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
                        ),
                      ),
                      subtitle: course != null
                          ? Chip(
                              label: Text(course.name),
                              backgroundColor: course.color.withOpacity(0.3),
                              labelStyle: TextStyle(color: course.color),
                            )
                          : null,
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

/// Courses tab - placeholder for course management.
class _CoursesTab extends StatelessWidget {
  const _CoursesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Course Management'),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}

/// Settings tab - placeholder for app settings.
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Settings'),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
