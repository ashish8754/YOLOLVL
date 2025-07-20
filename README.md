# YoLvL - Solo Leveling Inspired Mobile App

> *"Only I Level Up"* - Transform your daily habits into an RPG-like progression experience

## 🎮 Overview

YoLvL is a gamified self-improvement mobile application inspired by the popular "Solo Leveling" manhwa/anime series. The app transforms your daily activities and habits into an engaging RPG-style progression system with levels, stats, EXP tracking, and visual feedback.

Built with Flutter for cross-platform compatibility, YoLvL is designed as an **offline-first** application that helps you track personal development through:

- **6 Core Stats**: Strength, Agility, Endurance, Intelligence, Focus, and Charisma
- **Level Progression**: Earn EXP from activities and level up with celebration animations
- **10 Activity Types**: From workouts to studying, socializing to habit-breaking
- **Stat Degradation**: Gentle motivation system to maintain consistency
- **Visual Progress Tracking**: Charts, graphs, and dashboard analytics
- **Achievement System**: Unlock badges and milestones
- **Data Export/Import**: Backup and restore your progress

### 🎯 Core Philosophy

Unlike punitive habit trackers, YoLvL focuses on **positive reinforcement** and **gradual improvement**. The app encourages consistency without harsh penalties, making self-improvement feel like an adventure rather than a chore.

## 📱 Screenshots

<!-- Space reserved for UI screenshots -->
*[Screenshots of the dashboard, activity logging, stats progression, and achievements screens will be added here]*

---

## 🏗️ Architecture & Features

### Technical Stack
- **Frontend**: Flutter (Dart 3.8.1+)
- **State Management**: Provider pattern
- **Local Database**: Hive (NoSQL, offline-first)
- **Charts**: FL Chart for data visualization
- **Notifications**: Local push notifications
- **File Operations**: Backup/restore with JSON export

### Key Features
- ✅ **Complete Offline Functionality** - No internet required
- ✅ **RPG-Style Progression** - Level up system with EXP thresholds
- ✅ **6 Tracked Attributes** - Comprehensive personal development metrics
- ✅ **Smart Degradation System** - Gentle reminders for consistency
- ✅ **Visual Progress Tracking** - Beautiful charts and animations
- ✅ **Data Portability** - Export/import your progress
- ✅ **Achievement System** - Unlock badges and milestones
- ✅ **Dark/Light Themes** - Customizable visual experience
- ✅ **Accessibility Support** - Screen reader compatible

### Activity Types & Stat Mapping

| Activity | Primary Stat | Secondary Stat | EXP Rate |
|----------|-------------|----------------|----------|
| Workout - Weights | Strength (+0.06/hr) | Endurance (+0.04/hr) | 1 EXP/min |
| Workout - Cardio | Agility (+0.06/hr) | Endurance (+0.04/hr) | 1 EXP/min |
| Workout - Yoga/Flexibility | Agility (+0.05/hr) | Focus (+0.03/hr) | 1 EXP/min |
| Study - Serious | Intelligence (+0.06/hr) | Focus (+0.04/hr) | 1 EXP/min |
| Study - Casual | Intelligence (+0.04/hr) | Charisma (+0.03/hr) | 1 EXP/min |
| Meditation/Mindfulness | Focus (+0.05/hr) | - | 1 EXP/min |
| Socializing | Charisma (+0.05/hr) | Focus (+0.02/hr) | 1 EXP/min |
| Sleep Tracking | Endurance (+0.02/hr) | - | 1 EXP/min |
| Diet/Healthy Eating | Endurance (+0.03/hr) | - | 1 EXP/min |
| Quit Bad Habit | Focus (+0.03 fixed) | - | 60 EXP fixed |

### Level Progression Formula
```
EXP Threshold = 1000 × (1.2^(level-1))
```

---

## 🚀 Getting Started

### Prerequisites

Before building the project on your local Mac machine, ensure you have the following installed:

#### Required Software
- **macOS** (Monterey 12.0 or later recommended)
- **Xcode** 14.0+ (for iOS development)
- **Android Studio** (for Android development)
- **Flutter SDK** 3.19.0 or later
- **Git** for version control

#### Development Environment Setup

1. **Install Flutter**
   ```bash
   # Using Homebrew (recommended)
   brew install --cask flutter
   
   # Or download directly from https://flutter.dev/docs/get-started/install/macos
   ```

2. **Install Android Studio**
   - Download from: https://developer.android.com/studio
   - Install Android SDK and tools
   - Create an Android Virtual Device (AVD) for testing

3. **Install Xcode** (for iOS development)
   ```bash
   # From Mac App Store or developer.apple.com
   # After installation, install command line tools:
   xcode-select --install
   ```

4. **Install CocoaPods** (for iOS dependencies)
   ```bash
   sudo gem install cocoapods
   ```

### 🔧 Project Setup

#### 1. Clone the Repository
```bash
git clone [your-repository-url]
cd YOLOLVL/yolvl
```

#### 2. Verify Flutter Installation
```bash
flutter doctor
```
Resolve any issues shown by the doctor before proceeding.

#### 3. Install Dependencies
```bash
flutter pub get
```

#### 4. Generate Hive Models (Required for first build)
```bash
flutter pub run build_runner build
```

#### 5. Configure Platform-Specific Settings

**For Android:**
- The project is pre-configured with required NDK version and core library desugaring
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)

**For iOS:**
- Minimum iOS version: 12.0
- Install iOS dependencies:
```bash
cd ios
pod install
cd ..
```

### 📱 Building the App

#### Android APK (Release)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Android App Bundle (for Google Play)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

#### iOS (Requires Mac)
```bash
flutter build ios --release
```
Then open `ios/Runner.xcworkspace` in Xcode to archive and export.

### 🧪 Running the App

#### Development Mode
```bash
# Run on connected device or emulator
flutter run

# Run with hot reload enabled
flutter run --hot
```

#### Debug Mode with Specific Device
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d [device-id]
```

### 🧪 Testing

#### Run All Tests
```bash
flutter test
```

#### Run Specific Test Categories
```bash
# Unit tests only
flutter test test/services/
flutter test test/providers/

# Widget tests only
flutter test test/widgets/
flutter test test/screens/

# Integration tests
flutter test integration_test/
```

#### Test Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 🔧 Development Commands

#### Code Generation (after model changes)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Dependency Updates
```bash
# Check for outdated packages
flutter pub outdated

# Update all dependencies
flutter pub upgrade

# Update major versions
flutter pub upgrade --major-versions
```

#### Formatting and Analysis
```bash
# Format code
flutter format .

# Analyze code
flutter analyze

# Run lints
flutter pub run flutter_lints
```

---

## 📊 Project Structure

```
yolvl/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models (Hive entities)
│   │   ├── user.dart
│   │   ├── activity_log.dart
│   │   ├── achievement.dart
│   │   └── settings.dart
│   ├── providers/                # State management (Provider)
│   │   ├── user_provider.dart
│   │   ├── activity_provider.dart
│   │   └── settings_provider.dart
│   ├── repositories/             # Data access layer
│   │   ├── user_repository.dart
│   │   └── activity_repository.dart
│   ├── services/                 # Business logic
│   │   ├── exp_service.dart
│   │   ├── stats_service.dart
│   │   ├── degradation_service.dart
│   │   └── notification_service.dart
│   ├── screens/                  # UI screens
│   │   ├── dashboard_screen.dart
│   │   ├── activity_logging_screen.dart
│   │   ├── stats_progression_screen.dart
│   │   └── settings_screen.dart
│   ├── widgets/                  # Reusable UI components
│   │   ├── level_exp_display.dart
│   │   ├── stats_overview_chart.dart
│   │   └── achievement_card.dart
│   └── utils/                    # Utilities and helpers
│       ├── hive_config.dart
│       └── accessibility_helper.dart
├── test/                         # Test files
│   ├── unit/
│   ├── widget/
│   └── integration/
├── android/                      # Android-specific files
├── ios/                          # iOS-specific files
└── .kiro/                        # Project specifications
    └── specs/
        ├── requirements.md
        ├── design.md
        └── tasks.md
```

---

## 🎨 Design System

### Color Palette (Dark Theme)
- **Background**: #0D1117 (Deep dark blue-black)
- **Surface**: #161B22 (Slightly lighter dark)
- **Primary**: #238636 (Hunter green for stats/progress)
- **Secondary**: #1F6FEB (Electric blue for EXP/level)
- **Accent**: #F85149 (Warning red for degradation)
- **Text Primary**: #F0F6FC (Near white)
- **Text Secondary**: #8B949E (Muted gray)

### Typography
- **Headlines**: Bold, prominent for levels and sections
- **Body**: Medium weight for readable content
- **Captions**: Light weight for secondary information

---

## 🤝 Contributing

### Development Guidelines
1. Follow Flutter/Dart style guidelines
2. Write comprehensive tests for new features
3. Update documentation for API changes
4. Use semantic commit messages
5. Test on both Android and iOS before submitting

### Code Style
```bash
# Auto-format code
flutter format .

# Check for linting issues
flutter analyze
```

### Testing Requirements
- Unit tests for all service classes
- Widget tests for complex UI components
- Integration tests for critical user flows
- Maintain 80%+ code coverage

---

## 📋 Roadmap

### Phase 1 (Current - MVP)
- ✅ Core stat tracking and level progression
- ✅ Activity logging with 10 activity types
- ✅ Degradation system for consistency
- ✅ Dashboard with visual progress
- ✅ Data backup/restore functionality

### Phase 2 (Future Features)
- 🔄 Achievement system expansion
- 🔄 Quest system with daily/weekly challenges
- 🔄 Social features and leaderboards
- 🔄 Cloud sync (Google Drive/iCloud)
- 🔄 AI-generated insights and recommendations

### Phase 3 (Long-term Vision)
- 🔄 Avatar system with visual progression
- 🔄 Team/guild functionality
- 🔄 Advanced analytics and reporting
- 🔄 Integration with fitness wearables
- 🔄 Community marketplace for achievements

---

## 📄 License

This project is developed for personal use and learning purposes. All rights reserved.

---

## 📞 Support

For issues, questions, or feature requests:

1. Check the [existing issues](link-to-issues) in the repository
2. Create a new issue with detailed description
3. Follow the issue template for bug reports

---

## 🙏 Acknowledgments

- **Solo Leveling** manhwa/anime by Chugong for inspiration
- **Flutter Team** for the excellent cross-platform framework
- **Hive** for efficient local database solution
- **FL Chart** for beautiful chart visualizations

---

*"The weak have no rights or choices. Their only fate is to be relentlessly crushed by the strong. But I... I refuse to remain weak."* - Sung Jin-Woo

**Level up your life with YoLvL! 🚀**
