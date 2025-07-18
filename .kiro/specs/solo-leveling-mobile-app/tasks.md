# Implementation Plan

- [x] 1. Project Setup and Core Infrastructure
  - Initialize Flutter project with proper folder structure (lib/models, lib/services, lib/screens, lib/widgets)
  - Add required dependencies: provider, hive, hive_flutter, fl_chart, path_provider, local_notifications
  - Configure Hive for local storage and set up basic app structure
  - _Requirements: 10.1, 10.6, 12.2_

- [x] 2. Data Models and Hive Setup
  - [x] 2.1 Create core data model classes with Hive annotations
    - Implement User, ActivityLog, Settings models with @HiveType annotations
    - Define enums for ActivityType and StatType with proper Hive adapters
    - Write Hive adapter generation and registration code
    - _Requirements: 10.1, 10.2_

  - [x] 2.2 Implement data repositories with CRUD operations
    - Create UserRepository, ActivityRepository, SettingsRepository classes
    - Implement save, load, delete, and query methods for each repository
    - Add error handling and data validation for all repository operations
    - _Requirements: 10.1, 10.4, 10.5_

- [x] 3. Core Business Logic Services
  - [x] 3.1 Implement EXP and leveling calculation service
    - Create EXPService with calculateEXPThreshold method using formula: 1000 * (1.2^(level-1))
    - Implement level-up detection and EXP rollover logic
    - Write unit tests for EXP calculations and edge cases
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [x] 3.2 Create stat progression calculation service
    - Implement StatsService with calculateStatGains method for all 10 activity types with exact mappings:
      - Workout-Weights: Strength +0.06/hr, Endurance +0.04/hr
      - Workout-Cardio: Agility +0.06/hr, Endurance +0.04/hr
      - Workout-Yoga: Agility +0.05/hr, Focus +0.03/hr
      - Study-Serious: Intelligence +0.06/hr, Focus +0.04/hr
      - Study-Casual: Intelligence +0.04/hr, Charisma +0.03/hr
      - Meditation: Focus +0.05/hr
      - Socializing: Charisma +0.05/hr, Focus +0.02/hr
      - Sleep Tracking: Endurance +0.02/hr
      - Diet/Healthy Eating: Endurance +0.03/hr
      - Quit Bad Habit: Focus +0.03 (fixed amount, not per hour)
    - Write unit tests for each activity mapping and edge cases
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10, 5.11_

  - [x] 3.3 Implement degradation system service
    - Create DegradationService to check missed activity days for Workout/Study categories
    - Implement 3-day threshold logic with -0.01 per 3-day period, capped at -0.05
    - Add stat floor protection (minimum 1.0) and weekend counting logic
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_

- [x] 4. Activity Logging Core Functionality
  - [x] 4.1 Create activity logging service with validation
    - Implement ActivityService with logActivity method for all 10 activity types
    - Add duration validation and EXP calculation (1 EXP/minute, 60 fixed for Quit Bad Habit)
    - Create immediate stat/EXP gain calculation and storage logic
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [x] 4.2 Build activity history and querying functionality
    - Implement getActivityHistory with date range filtering
    - Add activity type filtering and efficient data retrieval
    - Create timestamp-based sorting and pagination for large datasets
    - _Requirements: 7.1, 7.2, 7.5_

- [x] 5. User Profile and Onboarding System
  - [x] 5.1 Create onboarding questionnaire logic
    - Implement 8-question form with the exact questions from requirements
    - Add answer-to-stat mapping logic (scale 1-10 responses to 1-5 base stats)
    - Create skip functionality with default 1.0 stats fallback
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 5.2 Implement user profile management
    - Create UserService for profile creation, updates, and level progression
    - Add profile persistence and loading from local storage
    - Implement tutorial completion tracking and app initialization flow
    - _Requirements: 1.4, 1.5_

- [x] 6. State Management and Providers
  - [x] 6.1 Create Provider classes for state management
    - Implement UserProvider with ChangeNotifier for level, EXP, and stats
    - Create ActivityProvider for logging state and history management
    - Add SettingsProvider for app configuration and theme management
    - _Requirements: 9.1, 9.2, 9.6_

  - [x] 6.2 Implement app lifecycle and degradation checking
    - Add app resume detection to trigger degradation checks
    - Create background processing for pending stat reductions
    - Implement state synchronization between services and UI providers
    - _Requirements: 6.5, 10.1_

- [x] 7. Dashboard and Main UI Components
  - [x] 7.1 Build dashboard screen with level and EXP display
    - Create level display widget with current level and EXP progress bar
    - Implement EXP threshold calculation and percentage display
    - Add visual styling with dark fantasy theme colors
    - _Requirements: 2.1, 11.2_

  - [x] 7.2 Create stats overview chart widget
    - Implement bar chart using fl_chart library for 6 stats display
    - Add proper scaling, colors, and labels for each stat type
    - Create responsive layout that works on different screen sizes
    - _Requirements: 2.2, 11.4_

  - [x] 7.3 Add daily summary and streak tracking
    - Implement streak calculation logic for consecutive activity days
    - Create degradation warning display for missed activities
    - Add recent activity summary with count and types
    - _Requirements: 2.3_

- [x] 8. Activity Logging UI and User Interaction
  - [x] 8.1 Create activity logging modal/screen
    - Build dropdown/picker for 10 fixed activity types
    - Implement duration input with default 60 minutes and validation
    - Add expected gains preview (stat increments and EXP)
    - _Requirements: 3.1, 3.2_

  - [x] 8.2 Add immediate feedback and animations
    - Create floating "+0.06" stat gain animations with fade-out
    - Implement level-up celebration animation with confetti/glow effects
    - Add haptic feedback and visual confirmation for successful logging
    - _Requirements: 3.4, 4.5_

- [-] 9. History and Progress Visualization
  - [ ] 9.1 Build activity history screen with filtering
    - Create scrollable list/calendar view of past activity logs
    - Implement activity type filtering and date range selection
    - Add efficient loading and pagination for large datasets
    - _Requirements: 7.1, 7.2_

  - [ ] 9.2 Create detailed stats progression charts
    - Implement line charts using fl_chart for each stat over time
    - Add time range selection (daily, weekly, monthly views)
    - Create interactive chart features with data point details
    - _Requirements: 7.3, 7.4_

- [ ] 10. Settings and Data Management
  - [ ] 10.1 Implement settings screen with customization options
    - Create activity enable/disable toggles for individual activities
    - Add custom stat increment adjustment sliders/inputs
    - Implement dark/light theme switching and relaxed weekend mode
    - _Requirements: 9.1, 9.2, 9.6, 9.7_

  - [ ] 10.2 Build backup and data export functionality
    - Create JSON export functionality with complete user data
    - Implement import/restore from backup files with validation
    - Add automatic backup to device storage on app close
    - _Requirements: 9.3, 9.4, 10.2, 10.3_

- [ ] 11. Notifications and Background Processing
  - [ ] 11.1 Implement local push notifications
    - Set up local_notifications plugin for daily reminders
    - Create customizable notification scheduling for activity logging
    - Add degradation warning notifications for missed activities
    - _Requirements: 9.5_

  - [ ] 11.2 Add app lifecycle management
    - Implement proper app pause/resume handling
    - Create background task scheduling for degradation checks
    - Add crash recovery and data integrity validation on startup
    - _Requirements: 10.4, 10.5_

- [ ] 12. Achievements and Motivation Features
  - [ ] 12.1 Create basic achievement system
    - Implement simple badges for milestones (7-day streak, Level 5 reached)
    - Add achievement unlock detection and celebration animations
    - Create achievement display screen with progress tracking
    - Note: Implement only if time allows in MVP; prioritize core features first
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 13. UI Polish and Animations
  - [ ] 13.1 Implement smooth animations and transitions
    - Add progress bar fill animations with easing curves
    - Create smooth screen transitions and navigation animations
    - Implement gesture-based interactions and swipe actions
    - _Requirements: 11.1, 11.5_

  - [ ] 13.2 Add accessibility features and responsive design
    - Implement screen reader support with semantic labels
    - Add high contrast mode and scalable font size support
    - Create large touch targets and motor accessibility features
    - _Requirements: 11.6_

- [ ] 14. Testing and Quality Assurance
  - [ ] 14.1 Write comprehensive unit tests
    - Create unit tests for all service classes (EXP, Stats, Degradation)
    - Test edge cases for calculations, data validation, and error handling
    - Achieve 80% code coverage for core business logic
    - _Requirements: All calculation requirements_

  - [ ] 14.2 Implement widget and integration tests
    - Create widget tests for all major screens and components
    - Test complete user flows: onboarding, logging, viewing progress
    - Add performance tests for large datasets and offline scenarios
    - Test accessibility features like screen reader support and high contrast mode
    - _Requirements: 12.1, 12.4, 11.6_

- [ ] 15. Final Integration and Deployment Preparation
  - [ ] 15.1 Integrate all components and test complete app flow
    - Connect all screens with proper navigation and state management
    - Test complete user journey from onboarding to advanced usage
    - Verify offline functionality and data persistence across app restarts
    - Document extension hooks in code for future features like quests, cloud sync, and LLM integrations
    - _Requirements: 10.6, 12.1, 13.5_

  - [ ] 15.2 Optimize performance and prepare for deployment
    - Optimize app size and memory usage for target 50MB limit
    - Test on multiple device types and screen sizes
    - Create APK/IPA builds for sideloading and personal use
    - _Requirements: 12.2, 12.3, 12.5_