# Design Document

## Overview

The Solo Leveling Mobile App is a Flutter-based, offline-first mobile application that gamifies self-improvement through RPG-style progression mechanics. The app transforms daily habits into an engaging experience with levels, stats, EXP tracking, and visual feedback inspired by the Solo Leveling manhwa/anime aesthetic.

The design prioritizes smooth performance, intuitive UX, and premium visual polish while maintaining complete offline functionality. The architecture supports future expansions like cloud sync, quests, and social features without requiring major rewrites.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │  Dashboard  │ │   Logging   │ │  Settings   │           │
│  │   Screen    │ │   Screen    │ │   Screen    │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   History   │ │ Onboarding  │ │Achievements │           │
│  │   Screen    │ │   Screen    │ │   Screen    │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                     │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │    User     │ │  Activity   │ │Degradation  │           │
│  │  Service    │ │  Service    │ │  Service    │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │    Stats    │ │    EXP      │ │Achievement  │           │
│  │  Service    │ │  Service    │ │  Service    │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │    User     │ │  Activity   │ │   Stats     │           │
│  │ Repository  │ │ Repository  │ │ Repository  │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │   Local     │ │   Backup    │ │Notification │           │
│  │  Storage    │ │  Service    │ │  Service    │           │
│  │   (Hive)    │ │             │ │             │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

### State Management

Using **Provider** pattern with **ChangeNotifier** for simplicity and performance:

- `UserProvider`: Manages user profile, level, EXP, and stats
- `ActivityProvider`: Handles activity logging and history
- `SettingsProvider`: Manages app configuration and preferences
- `ThemeProvider`: Controls dark/light mode and visual themes

### Data Flow

1. **App Launch**: Load user data → Apply pending degradation → Update UI
2. **Activity Logging**: Validate input → Calculate stat/EXP gains → Update state → Save to storage → Refresh UI
3. **Background Processing**: Check degradation on app resume → Apply changes → Notify user if needed

## Components and Interfaces

### Core Data Models

```dart
class User {
  String id;
  String name;
  String? avatarPath;
  int level;
  double currentEXP;
  Map<StatType, double> stats;
  DateTime createdAt;
  DateTime lastActive;
  bool hasCompletedOnboarding;
}

class ActivityLog {
  String id;
  ActivityType type;
  int durationMinutes;
  DateTime timestamp;
  Map<StatType, double> statGains;
  double expGained;
}

class Stats {
  double strength;
  double agility;
  double endurance;
  double intelligence;
  double focus;
  double charisma;
}

enum ActivityType {
  workoutWeights,
  workoutCardio,
  workoutYoga,
  studySerious,
  studyCasual,
  meditation,
  socializing,
  quitBadHabit,
  sleepTracking,
  dietHealthy
}
```

### Service Interfaces

```dart
abstract class UserService {
  Future<User> getCurrentUser();
  Future<void> updateUser(User user);
  Future<void> levelUp(User user);
  double calculateEXPThreshold(int level);
}

abstract class ActivityService {
  Future<void> logActivity(ActivityType type, int duration);
  Future<List<ActivityLog>> getActivityHistory({DateTime? startDate, DateTime? endDate});
  Map<StatType, double> calculateStatGains(ActivityType type, int duration);
  double calculateEXPGain(ActivityType type, int duration);
}

abstract class DegradationService {
  Future<void> checkAndApplyDegradation();
  bool shouldApplyDegradation(ActivityType type, DateTime lastActivity);
  Map<StatType, double> calculateDegradation(Map<StatType, DateTime> lastActivities);
}
```

### Repository Pattern

```dart
abstract class Repository<T> {
  Future<T?> findById(String id);
  Future<List<T>> findAll();
  Future<void> save(T entity);
  Future<void> delete(String id);
}

class UserRepository extends Repository<User> {
  // Hive box operations for user data
}

class ActivityRepository extends Repository<ActivityLog> {
  // Hive box operations for activity logs
  Future<List<ActivityLog>> findByDateRange(DateTime start, DateTime end);
  Future<List<ActivityLog>> findByType(ActivityType type);
}
```

## Data Models

### Local Storage Schema (Hive)

**Note:** Generate Hive adapters using `flutter pub run build_runner build` for all HiveType classes to enable serialization.

```dart
// User Box
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String? avatarPath;
  @HiveField(3) int level;
  @HiveField(4) double currentEXP;
  @HiveField(5) Map<String, double> stats; // StatType.name -> value
  @HiveField(6) DateTime createdAt;
  @HiveField(7) DateTime lastActive;
  @HiveField(8) bool hasCompletedOnboarding;
}

// Activity Log Box
@HiveType(typeId: 1)
class ActivityLogModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String activityType; // ActivityType.name
  @HiveField(2) int durationMinutes;
  @HiveField(3) DateTime timestamp;
  @HiveField(4) Map<String, double> statGains;
  @HiveField(5) double expGained;
}

// Settings Box
@HiveType(typeId: 2)
class SettingsModel extends HiveObject {
  @HiveField(0) bool isDarkMode;
  @HiveField(1) bool notificationsEnabled;
  @HiveField(2) List<String> enabledActivities;
  @HiveField(3) Map<String, double> customStatIncrements;
  @HiveField(4) bool relaxedWeekendMode;
  @HiveField(5) DateTime lastBackupDate;
}
```

### Backup Data Format

```json
{
  "version": "1.0",
  "exportDate": "2025-01-18T10:30:00Z",
  "user": {
    "id": "user_123",
    "name": "Player",
    "level": 5,
    "currentEXP": 1250.5,
    "stats": {
      "strength": 2.4,
      "agility": 1.8,
      "endurance": 2.1,
      "intelligence": 3.2,
      "focus": 2.7,
      "charisma": 1.9
    },
    "createdAt": "2025-01-01T00:00:00Z",
    "lastActive": "2025-01-18T09:45:00Z"
  },
  "activities": [
    {
      "id": "log_456",
      "type": "workoutWeights",
      "duration": 60,
      "timestamp": "2025-01-18T08:00:00Z",
      "statGains": {"strength": 0.06, "endurance": 0.04},
      "expGained": 60
    }
  ],
  "settings": {
    "isDarkMode": true,
    "notificationsEnabled": true,
    "enabledActivities": ["workoutWeights", "studySerious"],
    "relaxedWeekendMode": false
  }
}
```

## Error Handling

### Error Categories and Strategies

1. **Data Persistence Errors**
   - Strategy: Retry with exponential backoff, fallback to in-memory storage
   - User Experience: Show subtle warning, continue functionality
   - Recovery: Auto-retry on next app launch

2. **Calculation Errors**
   - Strategy: Validate inputs, use safe math operations, log errors
   - User Experience: Show error message, allow manual retry
   - Recovery: Reset to last known good state

3. **UI/Animation Errors**
   - Strategy: Graceful degradation, disable problematic animations
   - User Experience: Continue with basic UI, no app crash
   - Recovery: Restart animations on next screen navigation

4. **Backup/Export Errors**
   - Strategy: Multiple backup locations, validate data integrity
   - User Experience: Clear error messages with retry options
   - Recovery: Manual backup triggers, alternative export formats

### Error Handling Implementation

```dart
class AppError {
  final String code;
  final String message;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
}

enum ErrorSeverity { low, medium, high, critical }

class ErrorHandler {
  static void handleError(AppError error) {
    // Log error
    _logError(error);
    
    // Show user notification based on severity
    if (error.severity.index >= ErrorSeverity.medium.index) {
      _showUserNotification(error);
    }
    
    // Attempt recovery
    _attemptRecovery(error);
  }
}
```

## Testing Strategy

### Unit Testing (Target: 80% Coverage)

**Core Logic Tests:**
- EXP calculation and leveling mechanics
- Stat increment calculations for each activity type
- Degradation logic with various scenarios
- Data validation and sanitization
- Backup/restore functionality

**Service Layer Tests:**
- UserService: Profile management, level progression
- ActivityService: Logging, history retrieval, stat calculations
- DegradationService: Timing logic, stat reduction calculations

### Widget Testing

**Screen Tests:**
- Dashboard: Stat display, EXP bar, navigation
- Activity Logging: Input validation, immediate feedback
- Onboarding: Questionnaire flow, stat initialization
- Settings: Configuration changes, data export

**Component Tests:**
- Custom charts and progress bars
- Animation sequences (level up, stat gains)
- Form inputs and validation

### Integration Testing

**Data Flow Tests:**
- Complete activity logging flow: Input → Calculation → Storage → UI Update
- App lifecycle: Launch → Degradation Check → Dashboard Display
- Backup/Restore: Export → Import → Data Integrity Verification

**Performance Tests:**
- Large dataset handling (1 year of daily logs)
- Memory usage during extended sessions
- Animation performance on lower-end devices

**Offline Scenario Tests:**
- Test offline scenarios explicitly, e.g., simulate no internet and verify full core functionality

### Testing Tools and Framework

```dart
// Unit Testing
dependencies:
  flutter_test: ^1.0.0
  mockito: ^5.4.0
  hive_test: ^1.0.0

// Widget Testing
testWidgets('Dashboard displays current stats correctly', (tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('Level 1'), findsOneWidget);
  expect(find.byType(StatChart), findsOneWidget);
});

// Integration Testing
dependencies:
  integration_test: ^1.0.0
  
// Performance Testing
void main() {
  testWidgets('Activity logging performance test', (tester) async {
    await tester.runAsync(() async {
      // Simulate logging 100 activities
      for (int i = 0; i < 100; i++) {
        await activityService.logActivity(ActivityType.workoutWeights, 60);
      }
    });
    
    // Verify UI remains responsive
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
```

### Test Data Management

```dart
class TestDataFactory {
  static User createTestUser({int level = 1, double exp = 0}) {
    return User(
      id: 'test_user',
      name: 'Test Player',
      level: level,
      currentEXP: exp,
      stats: {
        StatType.strength: 1.0,
        StatType.agility: 1.0,
        StatType.endurance: 1.0,
        StatType.intelligence: 1.0,
        StatType.focus: 1.0,
        StatType.charisma: 1.0,
      },
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      hasCompletedOnboarding: true,
    );
  }
  
  static List<ActivityLog> createActivityHistory(int count) {
    return List.generate(count, (index) => ActivityLog(
      id: 'log_$index',
      type: ActivityType.workoutWeights,
      durationMinutes: 60,
      timestamp: DateTime.now().subtract(Duration(days: index)),
      statGains: {StatType.strength: 0.06, StatType.endurance: 0.04},
      expGained: 60,
    ));
  }
}
```

## UI/UX Design Specifications

### Visual Theme and Color Palette

**Dark Fantasy Theme (Primary):**
- Background: `#0D1117` (Deep dark blue-black)
- Surface: `#161B22` (Slightly lighter dark)
- Primary: `#238636` (Hunter green for stats/progress)
- Secondary: `#1F6FEB` (Electric blue for EXP/level)
- Accent: `#F85149` (Warning red for degradation)
- Text Primary: `#F0F6FC` (Near white)
- Text Secondary: `#8B949E` (Muted gray)

**Charts and Visualizations:**
Use fl_chart library for all bar/line charts to ensure smooth rendering and customization.

**Light Mode (Optional):**
- Background: `#FFFFFF`
- Surface: `#F6F8FA`
- Primary: `#2DA44E` (Green)
- Secondary: `#0969DA` (Blue)
- Accent: `#CF222E` (Red)

### Typography Scale

```dart
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
```

### Screen Layouts and Navigation

#### Bottom Navigation Structure
```
┌─────────────────────────────────────────────────────────────┐
│                        App Bar                              │
│                    "Solo Leveling"                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    Screen Content                           │
│                                                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [Home]    [History]   [+]    [Stats]   [Settings]        │
└─────────────────────────────────────────────────────────────┘
```

#### Dashboard Screen Layout
```
┌─────────────────────────────────────────────────────────────┐
│  Level 5                                    [Profile Icon]  │
│  ████████████████░░░░ 1,250 / 1,728 EXP                   │
├─────────────────────────────────────────────────────────────┤
│                   Stats Overview                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Strength    ████████░░ 2.4                         │   │
│  │ Agility     ██████░░░░ 1.8                         │   │
│  │ Endurance   ███████░░░ 2.1                         │   │
│  │ Intelligence ████████████ 3.2                      │   │
│  │ Focus       ██████████░░ 2.7                       │   │
│  │ Charisma    █████░░░░░ 1.9                         │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                  Daily Summary                              │
│  🔥 5-day streak    📊 3 activities today                  │
│  ⚠️  Study: 2 days without activity                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                    [+] FAB  │
└─────────────────────────────────────────────────────────────┘
```

#### Activity Logging Modal
```
┌─────────────────────────────────────────────────────────────┐
│                    Log Activity                             │
├─────────────────────────────────────────────────────────────┤
│  Activity Type                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Workout - Weights                            ▼      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Duration (minutes)                                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 60                                                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Expected Gains:                                            │
│  💪 Strength +0.06  🏃 Endurance +0.04  ⭐ +60 EXP        │
│                                                             │
│  ┌─────────────┐                           ┌─────────────┐ │
│  │   Cancel    │                           │     Log     │ │
│  └─────────────┘                           └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Animation Specifications

**Level Up Animation:**
- Duration: 2 seconds
- Effects: Confetti particles, screen flash, stat bar glow
- Sound: Optional celebration sound effect
- Trigger: When EXP exceeds threshold

**Stat Gain Feedback:**
- Duration: 1 second
- Effects: Floating "+0.06" text with fade-out
- Color: Matches stat type (green for strength, blue for intelligence)
- Trigger: Immediately after activity logging

**Progress Bar Animations:**
- Duration: 800ms
- Effects: Smooth fill animation with easing
- Trigger: On screen load and data updates

### Accessibility Features

**Screen Reader Support:**
- Semantic labels for all interactive elements
- Progress announcements for stat changes
- Navigation hints for complex gestures

**Visual Accessibility:**
- High contrast mode option
- Scalable font sizes (respect system settings)
- Color-blind friendly palette alternatives

**Motor Accessibility:**
- Large touch targets (minimum 44px)
- Gesture alternatives for all actions
- Voice input support for activity logging

### Responsive Design

**Phone Layouts (Primary):**
- Portrait: Single column, bottom navigation
- Landscape: Adapted layouts with horizontal stat bars

**Tablet Support (Future):**
- Side navigation panel
- Multi-column layouts for dashboard
- Larger chart visualizations

This design provides a solid foundation for building a polished, performant Solo Leveling mobile app that meets all the requirements while maintaining excellent user experience and technical quality.