# Requirements Document

## Introduction

The Solo Leveling Mobile App is a gamified self-improvement application inspired by the "Solo Leveling" manhwa/anime. The app transforms daily habits and activities into RPG-like progression with levels, stats, EXP, activity logging, and degradation mechanics for consistency. The goal is to create a polished, offline-first mobile app (iOS/Android) that feels like a high-quality indie product, initially for personal use but designed for scalability.

## Requirements

### Requirement 1: User Onboarding and Profile Setup

**User Story:** As a new user, I want to set up my initial profile and starting stats through a questionnaire, so that my progression begins from a realistic baseline rather than zero.

#### Acceptance Criteria

1. WHEN a user first opens the app THEN the system SHALL present an optional 8-question questionnaire with these specific questions:
   - On a scale of 1-10, what's your current physical strength/fitness level?
   - How many workout sessions do you do per week on average (0-7)?
   - On a scale of 1-10, how would you rate your agility/flexibility?
   - How many hours per week do you spend studying/learning seriously?
   - On a scale of 1-10, your mental focus/discipline?
   - How often do you successfully resist bad habits daily (0=never, 10=always)?
   - On a scale of 1-10, your social charisma/confidence?
   - Any recent achievements or baselines (optional text field)?
2. WHEN a user completes the questionnaire THEN the system SHALL map answers to base stat values between 1-5 for each attribute (Strength, Agility, Endurance, Intelligence, Focus, Charisma)
3. WHEN a user skips the questionnaire THEN the system SHALL default all stats to 1.0
4. WHEN the onboarding is complete THEN the system SHALL create a local profile with Level 1 and 0 EXP
5. IF the user completes onboarding THEN the system SHALL show a brief tutorial explaining core mechanics

### Requirement 2: Dashboard and Progress Display

**User Story:** As a user, I want to see my current level, EXP progress, and stat overview on the main dashboard, so that I can quickly understand my current progression state.

#### Acceptance Criteria

1. WHEN the user opens the app THEN the system SHALL display current Level and EXP progress bar with percentage and threshold
2. WHEN the dashboard loads THEN the system SHALL show a bar chart visualization of all 6 stats (Strength, Agility, Endurance, Intelligence, Focus, Charisma)
3. WHEN the user views the dashboard THEN the system SHALL display daily summary including streaks, recent logs, and pending degradation warnings
4. WHEN the user needs to log activity THEN the system SHALL provide a floating action button for quick access
5. WHEN stats or level change THEN the system SHALL update the dashboard display immediately

### Requirement 3: Activity Logging System

**User Story:** As a user, I want to log my daily activities with duration tracking, so that I can gain EXP and improve my stats based on my actual efforts.

#### Acceptance Criteria

1. WHEN a user wants to log an activity THEN the system SHALL present 10 fixed activity options: Workout - Weights, Workout - Cardio, Workout - Yoga/Flexibility, Study - Serious, Study - Casual, Meditation/Mindfulness, Socializing, Quit Bad Habit, Sleep Tracking, Diet/Healthy Eating
2. WHEN a user selects an activity THEN the system SHALL allow duration input in minutes with default of 60 minutes
3. WHEN a user logs "Quit Bad Habit" THEN the system SHALL treat it as a daily check-in with fixed 60 EXP value
4. WHEN an activity is logged THEN the system SHALL immediately show stat and EXP gains with visual feedback
5. WHEN multiple activities are logged per day THEN the system SHALL timestamp and store each entry separately
6. WHEN an activity is completed THEN the system SHALL save the log to local storage immediately

### Requirement 4: EXP and Leveling Mechanics

**User Story:** As a user, I want to gain EXP from activities and level up with clear thresholds, so that I feel progression and achievement from my efforts.

#### Acceptance Criteria

1. WHEN a user logs an activity THEN the system SHALL award 1 EXP per minute of duration
2. WHEN a user logs "Quit Bad Habit" THEN the system SHALL award fixed 60 EXP regardless of duration
3. WHEN EXP is gained THEN the system SHALL check against level threshold using formula: 1000 * (1.2^(level-1))
4. WHEN EXP exceeds the threshold THEN the system SHALL level up the user and rollover excess EXP to next level
5. WHEN a level up occurs THEN the system SHALL display celebration animation (confetti or character glow)
6. WHEN leveling up THEN the system SHALL NOT provide stat bonuses (stats only increase through activity)

### Requirement 5: Stat Progression System

**User Story:** As a user, I want my stats to increase based on relevant activities I perform, so that I can see measurable improvement in different areas of my life.

#### Acceptance Criteria

1. WHEN a user logs "Workout - Weights" THEN the system SHALL increase Strength by 0.06/hour and Endurance by 0.04/hour
2. WHEN a user logs "Workout - Cardio" THEN the system SHALL increase Agility by 0.06/hour and Endurance by 0.04/hour
3. WHEN a user logs "Workout - Yoga/Flexibility" THEN the system SHALL increase Agility by 0.05/hour and Focus by 0.03/hour
4. WHEN a user logs "Study - Serious" THEN the system SHALL increase Intelligence by 0.06/hour and Focus by 0.04/hour
5. WHEN a user logs "Study - Casual" THEN the system SHALL increase Intelligence by 0.04/hour and Charisma by 0.03/hour
6. WHEN a user logs "Meditation/Mindfulness" THEN the system SHALL increase Focus by 0.05/hour
7. WHEN a user logs "Socializing" THEN the system SHALL increase Charisma by 0.05/hour and Focus by 0.02/hour
8. WHEN a user logs "Sleep Tracking" THEN the system SHALL increase Endurance by 0.02/hour
9. WHEN a user logs "Diet/Healthy Eating" THEN the system SHALL increase Endurance by 0.03/hour
10. WHEN a user logs "Quit Bad Habit" THEN the system SHALL increase Focus by 0.03 as a fixed amount (not per hour)
11. WHEN stat increases are calculated THEN the system SHALL compound them daily and display immediate feedback

### Requirement 6: Degradation System

**User Story:** As a user, I want my stats to degrade if I miss activities for too long, so that I'm motivated to maintain consistency without harsh punishment.

#### Acceptance Criteria

1. WHEN a user misses Workout category activities (affecting Strength, Agility, Endurance) or Study category activities (affecting Intelligence, Focus) THEN the system SHALL start degradation after 3 consecutive missed days
2. WHEN degradation applies THEN the system SHALL reduce relevant stats by -0.01 per 3-day missed period
3. WHEN degradation is calculated THEN the system SHALL cap maximum degradation at -0.05 per application
4. WHEN stats degrade THEN the system SHALL NOT allow stats to fall below 1.0 floor value
5. WHEN the app is opened THEN the system SHALL apply any pending degradation before displaying dashboard
6. WHEN degradation occurs THEN the system SHALL NOT reduce EXP, only stats
7. WHEN weekends occur THEN the system SHALL count them as regular days for degradation (strict mode default)
8. WHEN degradation is applied THEN the system SHALL NOT affect Charisma stat (only Workout and Study category stats degrade)

### Requirement 7: History and Progress Tracking

**User Story:** As a user, I want to view my activity history and detailed stat progression over time, so that I can analyze my patterns and celebrate long-term progress.

#### Acceptance Criteria

1. WHEN a user accesses history THEN the system SHALL display a scrollable list or calendar view of past logs
2. WHEN viewing history THEN the system SHALL allow filtering by activity type
3. WHEN a user views stat details THEN the system SHALL show line charts of each attribute's progression over time
4. WHEN displaying charts THEN the system SHALL use appropriate time ranges (daily, weekly, monthly views)
5. WHEN history is accessed THEN the system SHALL load data efficiently without performance lag

### Requirement 8: Achievements and Motivation

**User Story:** As a user, I want to unlock achievements and badges for reaching milestones, so that I feel rewarded for consistent effort and major accomplishments.

#### Acceptance Criteria

1. WHEN a user reaches specific milestones THEN the system SHALL unlock relevant badges (e.g., "10 Workouts Streak", "Level 5 Reached")
2. WHEN an achievement is unlocked THEN the system SHALL display a celebration notification
3. WHEN viewing achievements THEN the system SHALL show progress toward locked achievements
4. WHEN achievements are earned THEN the system SHALL store them permanently in local data
5. IF time allows in MVP THEN the system SHALL implement simple badges; otherwise defer to post-v1

### Requirement 9: Settings and Customization

**User Story:** As a user, I want to customize the app behavior and manage my data, so that the app fits my personal preferences and usage patterns.

#### Acceptance Criteria

1. WHEN a user accesses settings THEN the system SHALL allow enabling/disabling individual activities
2. WHEN in settings THEN the system SHALL provide options to adjust stat increment/decrement values
3. WHEN data management is needed THEN the system SHALL provide backup/export functionality to JSON format
4. WHEN importing data THEN the system SHALL allow restore from previously exported JSON files
5. WHEN notifications are configured THEN the system SHALL send local push reminders for daily logging
6. WHEN theme preferences are set THEN the system SHALL support dark/light mode switching
7. WHEN relaxed mode is enabled THEN the system SHALL exclude weekends from degradation calculations

### Requirement 10: Data Persistence and Reliability

**User Story:** As a user, I want my progress data to be safely stored and preserved, so that I never lose my hard-earned progression due to technical issues.

#### Acceptance Criteria

1. WHEN any activity is logged THEN the system SHALL immediately save data to local storage
2. WHEN the app is closed THEN the system SHALL automatically backup data to device storage
3. WHEN the app is uninstalled THEN the system SHALL preserve backup files in accessible device location
4. WHEN the app crashes THEN the system SHALL recover all data without loss upon restart
5. WHEN data corruption is detected THEN the system SHALL attempt recovery from most recent backup
6. WHEN operating offline THEN the system SHALL maintain full functionality without internet connection
7. WHEN no internet is available THEN the system SHALL maintain all core functions without degradation

### Requirement 11: User Interface and Experience

**User Story:** As a user, I want an intuitive, visually appealing interface with smooth animations, so that using the app feels engaging and premium.

#### Acceptance Criteria

1. WHEN the app loads THEN the system SHALL display content within 2 seconds
2. WHEN visual elements are displayed THEN the system SHALL use dark fantasy color scheme with blues/greens for stats and red for warnings
3. WHEN animations play THEN the system SHALL provide smooth transitions and feedback without performance lag
4. WHEN charts are displayed THEN the system SHALL use clear, readable visualizations with appropriate scaling
5. WHEN the interface is used THEN the system SHALL support gesture-based interactions (swipe, tap)
6. WHEN accessibility is needed THEN the system SHALL provide high contrast options and screen reader support

### Requirement 12: Performance and Technical Requirements

**User Story:** As a user, I want the app to run smoothly and handle large amounts of data efficiently, so that my experience remains fast and reliable over long-term use.

#### Acceptance Criteria

1. WHEN the app handles data THEN the system SHALL support at least 1 year of daily logs without performance degradation
2. WHEN the app is installed THEN the system SHALL require no more than 50MB of device storage
3. WHEN processing occurs THEN the system SHALL maintain responsive UI with no blocking operations
4. WHEN data grows large THEN the system SHALL implement efficient data structures and queries
5. WHEN memory is managed THEN the system SHALL prevent memory leaks and optimize resource usage

### Requirement 13: Future Features Placeholder

**User Story:** As a user, I want the app designed modularly for expansions like quests, cloud sync, and LLM integrations, so that new features can be added seamlessly without major rewrites.

#### Acceptance Criteria

1. WHEN the system is architected THEN it SHALL use modular design patterns for easy feature additions
2. WHEN quests are implemented in future THEN the system SHALL support daily/weekly challenges with bonus EXP rewards
3. WHEN cloud sync is added THEN the system SHALL integrate with Google Drive/iCloud for backup synchronization
4. WHEN LLM integrations are added THEN the system SHALL support AI-generated insights and recommendations
5. WHEN evolving avatars are implemented THEN the system SHALL support character progression based on user level
6. WHEN v1 is developed THEN the system SHALL document extension hooks in code for future development
7. WHEN new features are planned THEN the system SHALL NOT require implementation in v1, only architectural preparation