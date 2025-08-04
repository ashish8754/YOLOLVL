# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

YoLvL is a Flutter-based mobile app inspired by Solo Leveling that gamifies self-improvement. The app tracks daily activities and habits with an RPG-style progression system featuring levels, stats, EXP tracking, achievements, and visual feedback. It's designed as an offline-first application using Hive for local storage.

## Development Commands

### Essential Flutter Commands
```bash
# Navigate to the Flutter project directory
cd yolvl

# Install dependencies
flutter pub get

# Generate Hive models (required after model changes)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app in development mode
flutter run

# Build release APK
flutter build apk --release

# Build release app bundle for Play Store
flutter build appbundle --release

# Format code
flutter format .

# Analyze code for issues
flutter analyze

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Platform-Specific Setup
```bash
# iOS dependencies (macOS only)
cd yolvl/ios && pod install && cd ..

# Check Flutter installation
flutter doctor
```

## Code Architecture

### High-Level Structure
The app follows a layered architecture with clear separation of concerns:

- **Models**: Hive entities for data persistence (`User`, `ActivityLog`, `Achievement`, `Settings`)
- **Services**: Business logic layer handling EXP calculations, stats management, degradation, notifications
- **Providers**: State management using Provider pattern for reactive UI updates
- **Repositories**: Data access layer abstracting Hive operations
- **Screens**: UI screens with navigation handled by MaterialApp
- **Widgets**: Reusable UI components and custom widgets

### Key Components

**User Progression System:**
- Infinite stats system (no ceiling limits, 1.0 minimum floor)
- EXP formula: `1000 * (1.2^(level-1))` for exponential growth
- 6 core stats: Strength, Agility, Endurance, Intelligence, Focus, Charisma
- Level-up detection with excess EXP handling and potential multi-level advancement

**Activity System:**
- 10 activity types with specific stat mappings and EXP rates
- Activity categories for degradation logic (workout, study, other)
- Stat reversal support for activity deletion with migration for legacy data
- Duration-based stat gains (typically 0.02-0.06 per hour)

**Data Management:**
- Hive for offline-first local storage with type adapters
- JSON serialization for backup/export functionality
- Data migration services for handling schema changes
- Comprehensive data integrity validation

**State Management:**
- Provider pattern for reactive state management
- UserProvider, ActivityProvider, SettingsProvider, AchievementProvider
- Automatic state persistence and recovery

### Core Services

**EXPService**: Handles EXP calculations, leveling mechanics, and EXP reversal with level-down support
**StatsService**: Manages stat calculations, degradation system, and validation
**DegradationService**: Implements gentle motivation system for consistency
**NotificationService**: Local push notifications for reminders
**BackupService**: JSON export/import for data portability

## Important Development Notes

### Model Generation
Always run model generation after changing Hive models:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing Strategy
- Unit tests for all service classes in `test/services/`
- Widget tests for complex UI components in `test/widgets/`
- Integration tests for critical user flows in `test/integration/`
- Performance tests in `test/performance/`

### Data Migration
The app includes migration services for handling data schema changes. When modifying models, ensure backward compatibility and add migration logic if needed.

### Infinite Stats System
The app supports unlimited stat progression. Stats have a 1.0 minimum floor but no ceiling. This enables long-term progression without hitting artificial limits.

### Activity Deletion with Stat Reversal
Activities store exact stat gains for accurate reversal during deletion. Legacy activities without stored gains use fallback calculations. The system handles level-down scenarios gracefully.

## Code Style and Standards

- Follow Flutter/Dart style guidelines
- Use `flutter format .` before commits
- Comprehensive documentation for complex business logic
- Type-safe enum handling for ActivityType and StatType
- Null-safety throughout the codebase
- Material Design 3 with custom dark theme