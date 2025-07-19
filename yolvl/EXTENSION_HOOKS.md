# Extension Hooks Documentation

This document outlines the extension hooks and architectural patterns implemented in the Solo Leveling mobile app to support future feature additions without major rewrites.

## Architecture Overview

The app follows a modular architecture with clear separation of concerns:

- **Presentation Layer**: Screens and widgets
- **Business Logic Layer**: Services and providers
- **Data Layer**: Repositories and local storage

## Extension Hooks for Future Features

### 1. Quest System Integration

**Hook Location**: `lib/services/quest_service.dart` (to be created)

**Integration Points**:
- `ActivityService.logActivity()` - Add quest progress tracking
- `UserProvider.addEXP()` - Add quest completion bonuses
- `AchievementService` - Link quest completion to achievements

**Database Schema Extension**:
```dart
// Add to models/quest.dart
@HiveType(typeId: 5)
class Quest extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) String description;
  @HiveField(3) QuestType type;
  @HiveField(4) Map<String, dynamic> requirements;
  @HiveField(5) Map<String, dynamic> rewards;
  @HiveField(6) DateTime? completedAt;
  @HiveField(7) bool isActive;
}
```

**Provider Integration**:
```dart
// Add to providers/quest_provider.dart
class QuestProvider extends ChangeNotifier {
  // Quest state management
  // Integration with existing providers
}
```

### 2. Cloud Sync Integration

**Hook Location**: `lib/services/cloud_sync_service.dart` (to be created)

**Integration Points**:
- `BackupService` - Extend to support cloud storage
- `DataIntegrityService` - Add cloud data validation
- `SettingsProvider` - Add sync preferences

**Sync Strategy**:
```dart
abstract class CloudSyncService {
  Future<void> syncToCloud();
  Future<void> syncFromCloud();
  Future<bool> resolveConflicts(ConflictData conflicts);
  Stream<SyncStatus> get syncStatusStream;
}
```

**Storage Providers**:
- Google Drive integration
- iCloud integration
- Custom backend support

### 3. LLM Integration Hooks

**Hook Location**: `lib/services/ai_service.dart` (to be created)

**Integration Points**:
- `ActivityService` - AI-powered activity suggestions
- `StatsService` - Personalized stat optimization recommendations
- `AchievementService` - Dynamic achievement generation

**AI Features**:
```dart
abstract class AIService {
  Future<List<ActivitySuggestion>> getActivitySuggestions(UserContext context);
  Future<String> generateMotivationalMessage(UserProgress progress);
  Future<List<Achievement>> generatePersonalizedAchievements(User user);
  Future<ProgressInsights> analyzeUserProgress(List<ActivityLog> activities);
}
```

### 4. Social Features Integration

**Hook Location**: `lib/services/social_service.dart` (to be created)

**Integration Points**:
- `UserService` - Add friend system
- `AchievementService` - Add social achievements
- `ActivityService` - Add activity sharing

**Social Components**:
```dart
// Friend system
class FriendService {
  Future<void> addFriend(String userId);
  Future<List<User>> getFriends();
  Future<void> shareProgress(ProgressShare share);
}

// Leaderboards
class LeaderboardService {
  Future<List<LeaderboardEntry>> getLeaderboard(LeaderboardType type);
  Future<void> updateUserRanking(String userId, int score);
}
```

### 5. Avatar Evolution System

**Hook Location**: `lib/services/avatar_service.dart` (to be created)

**Integration Points**:
- `UserProvider.level` - Trigger avatar evolution
- `StatsService` - Avatar appearance based on dominant stats
- Asset management for avatar graphics

**Avatar System**:
```dart
class AvatarService {
  Future<AvatarData> getAvatarForLevel(int level);
  Future<AvatarData> getAvatarForStats(Map<StatType, double> stats);
  Future<List<AvatarCustomization>> getUnlockedCustomizations(User user);
}
```

## Provider Extension Pattern

All new features should follow the existing provider pattern:

```dart
class NewFeatureProvider extends ChangeNotifier {
  final NewFeatureService _service;
  
  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Methods with error handling
  Future<void> performAction() async {
    _setLoading(true);
    try {
      await _service.performAction();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
}
```

## Database Extension Pattern

New data models should follow the Hive pattern:

```dart
@HiveType(typeId: X) // Use next available typeId
class NewModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) DateTime createdAt;
  // Additional fields...
  
  NewModel({
    required this.id,
    required this.createdAt,
  });
}

// Register adapter in HiveConfig
class HiveConfig {
  static void _registerAdapters() {
    // Existing adapters...
    Hive.registerAdapter(NewModelAdapter());
  }
}
```

## Service Integration Pattern

New services should integrate with existing services:

```dart
class NewFeatureService {
  final UserService _userService;
  final ActivityService _activityService;
  final NotificationService _notificationService;
  
  NewFeatureService({
    UserService? userService,
    ActivityService? activityService,
    NotificationService? notificationService,
  }) : _userService = userService ?? UserService(),
       _activityService = activityService ?? ActivityService(),
       _notificationService = notificationService ?? NotificationService();
  
  // Service methods that integrate with existing services
}
```

## UI Extension Points

### Navigation Integration

Add new screens to the bottom navigation:

```dart
// In main_navigation_screen.dart
final List<Widget> _screens = [
  // Existing screens...
  const NewFeatureScreen(),
];

final List<BottomNavigationBarItem> _navItems = [
  // Existing items...
  const BottomNavigationBarItem(
    icon: Icon(Icons.new_feature),
    label: 'New Feature',
  ),
];
```

### Dashboard Widgets

Add new dashboard components:

```dart
// In dashboard_screen.dart
Column(
  children: [
    const LevelExpDisplay(),
    const StatsOverviewChart(),
    const DailySummaryWidget(),
    const NewFeatureWidget(), // Add here
  ],
)
```

## Testing Extension Pattern

New features should include comprehensive tests:

```dart
// Unit tests
group('NewFeatureService Tests', () {
  late NewFeatureService service;
  
  setUp(() {
    service = NewFeatureService();
  });
  
  test('should perform expected behavior', () async {
    // Test implementation
  });
});

// Widget tests
group('NewFeatureWidget Tests', () {
  testWidgets('should display correctly', (tester) async {
    // Widget test implementation
  });
});

// Integration tests
group('NewFeature Integration Tests', () {
  testWidgets('should integrate with existing features', (tester) async {
    // Integration test implementation
  });
});
```

## Configuration Extension

Add new settings to the settings system:

```dart
// In models/settings.dart
@HiveField(X) bool newFeatureEnabled;
@HiveField(X+1) Map<String, dynamic> newFeatureConfig;

// In settings_provider.dart
bool get isNewFeatureEnabled => _settings?.newFeatureEnabled ?? false;

Future<void> setNewFeatureEnabled(bool enabled) async {
  if (_settings != null) {
    _settings!.newFeatureEnabled = enabled;
    await _settingsRepository.saveSettings(_settings!);
    notifyListeners();
  }
}
```

## Performance Considerations

When adding new features:

1. **Lazy Loading**: Load feature data only when needed
2. **Background Processing**: Use isolates for heavy computations
3. **Caching**: Implement appropriate caching strategies
4. **Memory Management**: Dispose of resources properly

## Security Considerations

For cloud sync and social features:

1. **Data Encryption**: Encrypt sensitive data before transmission
2. **Authentication**: Implement secure authentication flows
3. **Privacy**: Respect user privacy preferences
4. **Data Validation**: Validate all incoming data

## Migration Strategy

When adding new features that require database changes:

1. **Version Management**: Increment database version
2. **Migration Scripts**: Provide migration logic for existing users
3. **Backward Compatibility**: Ensure older versions can still function
4. **Rollback Strategy**: Plan for feature rollback if needed

This architecture ensures that new features can be added incrementally without disrupting existing functionality, maintaining the app's stability and performance.