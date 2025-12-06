# Timer Feature Architecture Plan

## Overview
The timer feature transforms the single-task "Right Now" display into a focused work session with pomodoro-style dual timers (task total + microstep/break). Users can pause, see overtime tracking, and complete or extend tasks.

## High-Level Flow

```
Right Now Display (current)
    ↓
[NEW] Start Task Button
    ↓
Timer Screen (NEW PAGE - will be a full-screen overlay or new nav tab)
    ├── Dual Timers (task total + microstep)
    ├── Pause/Resume buttons
    ├── Overtime tracking (shows if task exceeds time)
    └── Progress visualization (pomodoro-style)
    ↓
Task Completion Dialog (after task timer expires)
    ├── "Task Completed" button → Save to history, remove from queue
    ├── "Task Not Completed" button → Show 10-min extension timer
    └── Extended task logic (repeat dialog until complete or user switches tasks)
    ↓
History/Completion Tracking (in PreferencesService)
    └── On-time completion percentage
```

## Required New Components

### 1. Timer Page (New File: `lib/screens/timer_screen.dart`)
**Purpose:** Full-featured pomodoro-style timer with dual timer display

**State:**
- `Task currentTask` - Task being worked on
- `List<MicroStep> microSteps` - Breakdown of current task (empty = single timer mode)
- `Timer _taskTimer` - Total task countdown timer
- `Timer _stepTimer` - Current step/break countdown timer (null if no microsteps)
- `Duration _totalTaskTime` - Total elapsed for task
- `Duration _currentStepTime` - Total elapsed for current step (0 if no microsteps)
- `Duration _overtimeAdded` - Extra time spent beyond estimate
- `bool _isPaused` - Whether timers are paused
- `int _currentStepIndex` - Which step/break user is on (0-indexed, unused if no microsteps)
- `bool _isBreakTime` - Whether user is in a break between steps (false if no microsteps)

**Single Timer Mode (no microsteps):**
- Only `_taskTimer` is used
- `_stepTimer` remains null
- UI shows single large timer instead of dual timers
- No "Skip Step" button
- Simpler layout for quick tasks

**Key Methods:**
- `_startTimers()` - Initialize task timer; init step timer only if microsteps exist
- `_pauseTimers()` - Stop timers, track pause point
- `_resumeTimers()` - Continue from pause point
- `_advanceToNextStep()` - Called when step timer completes (no-op if no microsteps)
- `_completeTask()` - Called when task timer expires or user marks complete
- `_startExtensionTimer(int minutes)` - 10-min extension after task expires
- `bool get _hasSteps => currentTask.microSteps.isNotEmpty` - Helper to check single vs dual timer mode

**UI Layout - With Microsteps:**
```
┌─────────────────────────────────┐
│  Task Title: [Task Name]        │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │  Task Total Time Dial   │   │
│  │      45:30 / 60:00      │   │
│  │   (yellow - overtime)   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │  Current Step/Break     │   │
│  │      10:45 / 15:00      │   │
│  │  Step 2: Code Review    │   │
│  └─────────────────────────┘   │
│                                 │
│  Overtime: +5 min               │
│  Progress: 2/3 steps            │
│                                 │
│  [Pause] [Skip Step]            │
└─────────────────────────────────┘
```

**UI Layout - Without Microsteps (Single Timer):**
```
┌─────────────────────────────────┐
│  Task Title: [Task Name]        │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │  Task Time              │   │
│  │      45:30 / 60:00      │   │
│  │   (yellow - overtime)   │   │
│  └─────────────────────────┘   │
│                                 │
│  Overtime: +5 min               │
│                                 │
│  [Pause]                        │
└─────────────────────────────────┘

Note: When task has no microsteps:
- Single timer shows task total time only
- No step/break timer shown
- "Skip Step" button not shown
- Simpler, cleaner UI for simple tasks
```

### 2. Task Completion Dialog (Extend `right_now_display.dart`)
**Purpose:** Handle completion/extension flow after timer expires

**Dialog States:**
1. **Task Completed?**
   - "Task Completed" → Save completion record
   - "Task Not Completed" → Show extension prompt

2. **Extension Prompt**
   - "Start 10-min Extension" → Launch extension timer
   - "Defer Task" → Return to task queue
   - "Mark Not Completed" → Save incomplete record

**Key Logic:**
- Track multiple extensions (can repeat until task complete or user defers)
- Only one task can be "focused" at a time (switching tasks clears timer state)

### 3. Timer Provider (New File: `lib/providers/timer_provider.dart`)
**Purpose:** Manage timer state separately from task provider

**State:**
- `Task? activeTask` - Currently focused task
- `int currentStepIndex` - Which step user is on
- `DateTime startTime` - When timer started
- `DateTime pauseTime?` - When timer was paused
- `Duration totalPausedTime` - Cumulative pause duration
- `List<TimerSession> sessions` - History of timer sessions for current task

**Methods:**
- `startTimer(Task task)` - Initialize timer for a task
- `pauseTimer()`
- `resumeTimer()`
- `skipStep()`
- `completeTask(bool onTime)`
- `startExtension(int minutes)`
- `clearTimer()` - Called when user switches to different task

### 4. Update PreferencesService
**New Data Structure:**
```dart
class CompletionRecord {
  String taskId;
  DateTime completedAt;
  bool completedOnTime;
  int overtimeMinutes;
  int extensionsUsed;
}
```

**New Fields:**
- `List<CompletionRecord> _completionHistory`
- `double get onTimeCompletionPercentage` - Calculate completion rate

**Methods:**
- `saveCompletionRecord(CompletionRecord)`
- `getOnTimePercentage()` - Returns 0.0 to 1.0
- `getTaskCompletionStats(taskId?)` - Per-task or overall stats

### 5. Update Right Now Display
**New UI Element:**
- Replace "Done" button with "Start Task" when no timer is active
- Show timer button if timer is already active (allows return to timer)

```dart
// In right_now_display.dart
if (taskProvider.isTimerActive && taskProvider.activeTask?.id == nextTask.id) {
  // Return to timer button
  Expanded(
    child: ElevatedButton.icon(
      icon: const Icon(Icons.timer),
      label: const Text('Return to Timer'),
      onPressed: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => TimerScreen(task: nextTask),
      )),
    ),
  ),
} else {
  // Start task button
  Expanded(
    child: ElevatedButton.icon(
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start Task'),
      onPressed: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => TimerScreen(task: nextTask),
      )),
    ),
  ),
}
```

## Data Model Updates

### Task Model
No changes needed - already has `estimatedMinutes` and `microSteps`

### New: TimerSession
```dart
class TimerSession {
  final DateTime startTime;
  final DateTime? endTime;
  final bool completedOnTime;
  final int extensionsUsed;
  final Duration totalPausedTime;

  Duration get elapsedTime => (endTime ?? DateTime.now()).difference(startTime) - totalPausedTime;
}
```

## Navigation Flow

**Current Structure (home_screen.dart):**
- Tab 0: Home (Right Now display)
- Tab 1: Tasks list
- Tab 2: Settings

**Options for Timer Page:**
1. **Option A:** Overlay modal (full-screen dialog)
   - Pros: Doesn't clutter bottom nav, can return to Home
   - Cons: Visually stacked navigation

2. **Option B:** New tab (insert at Tab 1)
   - Pros: Clear separation, dedicated space
   - Cons: Changes bottom nav structure, could be confusing

3. **Option C:** Replace Home tab when timer active
   - Pros: No nav clutter, single-task focus
   - Cons: Can't easily see other tasks while timing

**Recommendation:** Option A (overlay modal via Navigator.push)
- Launch from "Start Task" button in Right Now display
- Pop returns to Right Now display
- Maintains clean nav structure

## Dashboard Placement (No Implementation Yet)

**User Request:** "The percentage of tasks that were completed on time should be shown in a dashboard somewhere. Brainstorm where the dashboard should be put, maybe as a page between the timer page and the settings."

**Options:**
1. **New Dashboard Tab** (after Tasks, before Settings)
   - Shows: On-time %, task history, trends
   - Pros: Dedicated space, visible in nav
   - Cons: Adds 4th nav item (UI crowding)

2. **Dashboard Card on Home**
   - Shows: This week's on-time %, quick stats
   - Pros: Visible by default, contextual
   - Cons: Competes for space with Right Now display

3. **Dashboard as Settings Sub-page**
   - Shows: Full history, charts, filters
   - Pros: Keeps nav clean, logical grouping
   - Cons: Hidden unless user navigates to Settings

4. **Dedicated Dashboard Screen (New Nav Tab)**
   - Position: Home → Timer/Dashboard → Tasks → Settings
   - Pros: Clear visibility, room for growth
   - Cons: More nav items (5 total)

**Recommended:** Option 2 (Dashboard Card on Home above/below Right Now)
- Keep nav clean
- Show completion stats automatically
- Users see progress without extra clicks
- Expandable card for detailed view

## Implementation Phases

### Phase 1: Timer Screen Foundation
- Create TimerScreen widget with dual timer UI
- Implement pause/resume logic
- Wire up to Right Now display "Start Task" button

### Phase 2: Task Completion Flow
- Task timer expiry dialog
- Completion/extension logic
- Extension timer (10 min repeat)

### Phase 3: Data Persistence
- Update PreferencesService with completion tracking
- Save completion records to local storage
- Calculate on-time percentage

### Phase 4: Dashboard (User will request separately)
- Create dashboard widget
- Display completion stats
- Add dashboard to Home screen

## Key Design Decisions

1. **Pause Time Tracking:** Track total paused time separately so it doesn't count against task completion
2. **Overtime Definition:** Time > estimated minutes, shows in red/orange on task timer
3. **Extension Limit:** No hard limit per user request, but track number of extensions used
4. **Step/Break Timing:** Each step timer includes its allocated time + next break (if not last step)
5. **Task Completion History:** Saved per-task, not per-session (multiple sessions per task during extensions)

## Files to Create/Modify

**Create:**
- `lib/screens/timer_screen.dart` (main timer UI)
- `lib/providers/timer_provider.dart` (timer state management)
- `lib/models/completion_record.dart` (data model)
- `lib/models/timer_session.dart` (data model)

**Modify:**
- `lib/services/preferences_service.dart` (add completion tracking)
- `lib/widgets/right_now_display.dart` (add "Start Task" button)
- `lib/screens/home_screen.dart` (eventual dashboard integration)

