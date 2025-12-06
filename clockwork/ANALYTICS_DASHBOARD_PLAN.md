# Analytics Dashboard Implementation Plan

## Overview
A simple, informative dashboard showing task completion patterns and ADHD-relevant metrics. No AI—just pure data visualization of existing completion records.

---

## Dashboard Location
**Position:** New tab in bottom navigation (between Tasks and Settings)
- Home → Tasks → **Analytics** ← NEW → Settings
- Or replace current Tasks tab position if preferred

**Access:** Accessible anytime, updates in real-time as tasks complete

---

## Core Metrics (Simple & Informative)

### 1. Overall On-Time Percentage (Primary Metric)
**What it shows:** Percentage of tasks completed within estimated time
**Example:** "58% of your tasks completed on time"

**UI:**
```
┌─────────────────────────────────┐
│     On-Time Performance         │
│                                 │
│           58%                   │
│       ████████░ (filled circle) │
│                                 │
│  37 of 64 tasks on time         │
└─────────────────────────────────┘
```

**Data Source:** `prefsService.getOnTimeCompletionPercentage()`

**Why for ADHD:** Validates that "late is still completion"—shows realistic ADHD productivity

---

### 2. This Week's Metrics (7-day view)
**What it shows:** How many tasks completed this week + on-time count

**UI:**
```
┌─────────────────────────────────┐
│      This Week                  │
│                                 │
│  Total: 12 tasks                │
│  On-Time: 7 tasks (58%)         │
│  Late: 5 tasks (42%)            │
│                                 │
│  Avg Overtime: +8 min           │
└─────────────────────────────────┘
```

**Calculation:**
- Filter `completionHistory` by `completedAt` >= 7 days ago
- Count total, on-time, late
- Calculate average overtime minutes

**Why for ADHD:** Weekly progress is digestible; monthly is overwhelming

---

### 3. Completion Streak (Days with ≥1 task completed)
**What it shows:** How many days in a row user completed at least one task

**UI:**
```
┌─────────────────────────────────┐
│  Current Streak                 │
│                                 │
│      🔥 4 days                  │
│  (Last break: 2 days ago)       │
│                                 │
│  Best streak: 12 days           │
└─────────────────────────────────┘
```

**Calculation:**
- Group completion records by date (completedAt.date())
- Count consecutive days from today backwards
- Track best streak all-time

**Why for ADHD:** Dopamine reward for consistent effort (not perfection)

---

### 4. Total Completions (Lifetime & This Month)
**What it shows:** Absolute count of completed tasks

**UI:**
```
┌─────────────────────────────────┐
│    Total Tasks Completed        │
│                                 │
│  This Month: 47 tasks           │
│  All Time: 412 tasks            │
│                                 │
│  Avg per week: 11.8 tasks       │
└─────────────────────────────────┘
```

**Calculation:**
- `loadCompletionHistory().length` = all time
- Filter by `completedAt` >= 30 days ago = this month
- Divide by weeks for average

**Why for ADHD:** Shows quantity as validation of effort

---

### 5. Overtime Distribution (Simple Visualization)
**What it shows:** How much users typically overrun tasks

**UI:**
```
┌─────────────────────────────────┐
│    Typical Overtime             │
│                                 │
│  Avg: +12 min per task          │
│  Range: 0 to +45 min            │
│                                 │
│  On-time: 58%                   │
│  5-15 min over: 28%             │
│  15+ min over: 14%              │
└─────────────────────────────────┘
```

**Calculation:**
- Average `overtimeMinutes` across all completions
- Calculate percentiles (0 min, 5-15 min, 15+ min)
- Show distribution bars

**Why for ADHD:** Normalizes overrun as pattern, not failure

---

### 6. Most Common Task Completion Hours (Simple Peak Times)
**What it shows:** What time of day user tends to complete tasks

**UI:**
```
┌─────────────────────────────────┐
│   Peak Productivity Hours       │
│                                 │
│  10am-12pm: ████████ (14 tasks) │
│   2pm-4pm:  ██████ (10 tasks)   │
│   7pm-9pm:  ███ (5 tasks)       │
│                                 │
│  Most common: 10am-12pm         │
└─────────────────────────────────┘
```

**Calculation:**
- Extract hour from `completedAt` for each record
- Group by 2-hour buckets
- Find which bucket has most completions

**Why for ADHD:** Shows when user's brain works best (chronotype awareness)

---

### 7. Average Task Duration (Estimated vs Actual)
**What it shows:** How accurate user's time estimates are

**UI:**
```
┌─────────────────────────────────┐
│   Estimation Accuracy           │
│                                 │
│  Estimated: 30 min (avg)        │
│  Actual: 42 min (avg)           │
│  Ratio: 1.4x longer             │
│                                 │
│  Your Pattern: +12 min overhead │
└─────────────────────────────────┘
```

**Calculation:**
- Average `task.estimatedMinutes` for completed tasks
- Average actual time = `(totalTaskDuration.inMinutes - totalPausedTime.inMinutes)`
- Calculate ratio and avg difference

**Why for ADHD:** Shows realistic time perception gap (useful for future estimates)

---

## Data Models Needed

### Extension to CompletionRecord (Already Exists)
```dart
class CompletionRecord {
  String taskId;
  String taskTitle;
  DateTime completedAt;          // ← Already have
  bool completedOnTime;          // ← Already have
  int overtimeMinutes;           // ← Already have
  int extensionsUsed;            // ← Already have
  // Could add: actualTimeMinutes, taskCategory, timeOfDay
}
```

### New: AnalyticsData (Computed, not stored)
```dart
class AnalyticsData {
  double onTimePercentage;
  int thisWeekTotal;
  int thisWeekOnTime;
  int thisWeekLate;
  int currentStreak;
  int bestStreak;
  int thisMonthTotal;
  int allTimeTotal;
  int avgOvertimeMinutes;
  int estimatedAvgMinutes;
  int actualAvgMinutes;
  Map<String, int> hourlyDistribution;  // "10-12" → 14 tasks
}
```

---

## UI Structure

### Main Analytics Screen (New Page)
```
┌─────────────────────────────────────┐
│  ANALYTICS                  ⟲ (refresh)|
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │  On-Time Performance: 58%   │   │  [Card 1]
│  │  ████████░                  │   │
│  │  37 of 64 tasks             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Current Streak: 🔥 4 days  │   │  [Card 2]
│  │  Best: 12 days              │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  This Week: 12 completed    │   │  [Card 3]
│  │  On-time: 7 | Late: 5       │   │
│  │  Avg overtime: +8 min       │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Total Completions          │   │  [Card 4]
│  │  This month: 47             │   │
│  │  All time: 412              │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Typical Overtime           │   │  [Card 5]
│  │  Avg: +12 min per task      │   │
│  │  Range: 0 to +45 min        │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Peak Productivity Hours    │   │  [Card 6]
│  │  10am-12pm: ████████ (14)   │   │
│  │  2pm-4pm: ██████ (10)       │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Time Estimation Accuracy   │   │  [Card 7]
│  │  Est: 30min | Actual: 42min │   │
│  │  Your pattern: +12 min      │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

**Scrollable:** Stack cards vertically if needed
**Responsive:** Each card scales with device width
**Color Coded:** Green (good), Orange (warning), Blue (info)

---

## Files to Create

### 1. `lib/models/analytics_data.dart`
- AnalyticsData class with all computed metrics
- Helper methods for calculations

### 2. `lib/providers/analytics_provider.dart`
- ChangeNotifierProvider
- Methods to compute analytics from completion history
- Cache results (recompute on new completion, not constantly)

### 3. `lib/screens/analytics_screen.dart`
- Main analytics page
- Displays all 7 metric cards
- Refresh button to update
- Scrollable layout

### 4. `lib/widgets/analytics_card.dart`
- Reusable card widget for each metric
- Title, content, optional progress bar
- Consistent styling

### 5. Update `lib/screens/home_screen.dart`
- Add new navigation tab for Analytics
- Route to analytics_screen.dart

---

## Implementation Steps

### Phase 1: Data Models & Provider
1. Create `analytics_data.dart` with AnalyticsData class
2. Create `analytics_provider.dart` with AnalyticsProvider
3. Implement calculation methods (7 metrics)
4. Add to MultiProvider in main.dart

### Phase 2: UI Components
1. Create `analytics_card.dart` (reusable card widget)
2. Create `analytics_screen.dart` (main page)
3. Implement all 7 card layouts
4. Add scroll/responsive handling

### Phase 3: Navigation Integration
1. Update `home_screen.dart` with new tab
2. Wire up navigation to analytics_screen
3. Add analytics icon to bottom nav
4. Update bottom nav items

### Phase 4: Polish
1. Add refresh button
2. Handle empty state (no completions yet)
3. Test responsiveness
4. Dark mode verification

---

## Calculation Details

### On-Time Percentage
```dart
double getOnTimePercentage() {
  final history = prefsService.loadCompletionHistory();
  if (history.isEmpty) return 0.0;
  final onTime = history.where((r) => r.completedOnTime).length;
  return (onTime / history.length) * 100;
}
```

### This Week Metrics
```dart
Map<String, int> getThisWeekMetrics() {
  final history = prefsService.loadCompletionHistory();
  final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
  final thisWeek = history.where((r) => r.completedAt.isAfter(sevenDaysAgo)).toList();

  return {
    'total': thisWeek.length,
    'onTime': thisWeek.where((r) => r.completedOnTime).length,
    'late': thisWeek.where((r) => !r.completedOnTime).length,
    'avgOvertime': thisWeek.isEmpty ? 0 :
      thisWeek.fold<int>(0, (sum, r) => sum + r.overtimeMinutes) ~/ thisWeek.length,
  };
}
```

### Current Streak
```dart
int getCurrentStreak() {
  final history = prefsService.loadCompletionHistory();
  final sortedByDate = history
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  final completionDates = sortedByDate
    .map((r) => r.completedAt.toDate())
    .toSet();

  int streak = 0;
  DateTime currentDate = DateTime.now();

  while (completionDates.contains(currentDate)) {
    streak++;
    currentDate = currentDate.subtract(Duration(days: 1));
  }

  return streak;
}
```

### Peak Hours
```dart
Map<String, int> getPeakHours() {
  final history = prefsService.loadCompletionHistory();
  final hourBuckets = <String, int>{};

  for (var record in history) {
    final hour = record.completedAt.hour;
    final bucket = '${hour}-${hour + 2}';
    hourBuckets[bucket] = (hourBuckets[bucket] ?? 0) + 1;
  }

  return hourBuckets;
}
```

---

## Design Principles for Dashboard

1. **Simple Over Comprehensive** - Show 7 metrics, not 70
2. **ADHD-Focused Framing** - "Late is still completion" messaging
3. **Dopamine-Positive** - Celebrate streaks, show progress
4. **No Shame** - Never show "failures" or red X marks
5. **Scrollable, Not Overwhelming** - Can scroll through at own pace
6. **Dark-Mode First** - Eye-friendly for long sessions
7. **Visual Feedback** - Progress bars, colors, not just numbers
8. **Real Data** - No projections or "you could be" messages
9. **Fast Load** - Pre-compute metrics, cache results
10. **Offline-Ready** - Works completely offline (local data only)

---

## Expected Visual Impact

This dashboard transforms Clockwork from "task timer" to **"ADHD-aware productivity tool with insight."**

Users can point to:
- "I've completed 412 tasks"
- "I'm on a 4-day streak"
- "My real pattern is +12 min overhead (not my fault, it's ADHD)"
- "I'm most productive 10am-12pm"
- "58% of my tasks are on-time (that's good for ADHD!)"

This is **eminently shareable** with therapists, coaches, and friends—making it a conversation starter about ADHD productivity.

---

## Success Criteria

✅ Dashboard displays all 7 metrics correctly
✅ Data updates in real-time when new task completes
✅ Calculations are accurate (verified against test data)
✅ UI is responsive and clean
✅ No performance issues (fast load/scroll)
✅ Dark mode looks good
✅ Empty state handled gracefully
✅ Refresh button works and updates all metrics

