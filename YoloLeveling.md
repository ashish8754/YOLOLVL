### Project Overview: Solo Leveling Mobile App

Thank you—I'm thrilled the web app is up and running smoothly on your system! It's a solid foundation, and transitioning to a full-fledged mobile app is a natural next step, especially since you mentioned potential for sharing if others like it. This app gamifies self-improvement inspired by "Solo Leveling," turning daily habits into RPG-like progression with levels, stats, EXP, activity logging, and degradation for consistency.

The goal is a polished, offline-first mobile app (iOS/Android) that's intuitive, visually engaging, and feels like a high-quality indie dev product—surprising users with its refinement. It should be personal-use focused initially but expandable for multi-user (e.g., accounts, sharing progress). Data persistence is key, with optional cloud sync later.

I'll provide a **detailed overview** below, structured as a blueprint you can hand directly to your intern or AI editor. They can use this to generate:
- **Requirements Document**: Expand into user stories, use cases, and specs.
- **Design Document**: Wireframes, UI mockups, architecture diagrams.
- **Task Plan**: Breakdown into sprints/phases with timelines, dependencies, and milestones.

This overview builds on our discussions: core features from the web app (levels, stats, logging, degradation), plus additions like quests, achievements, onboarding, and visualizations. I've kept it realistic for a small team/intern project—aim for MVP in 4-6 weeks, then iterate.

---

#### 1. Project Vision and Scope
- **App Name**: Solo Leveling Life (or similar—customizable).
- **Target Audience**: Initially you (personal tracking), but designed for scalability to self-improvers seeking gamified motivation. Age 18-40, tech-savvy users.
- **Platform**: Cross-platform mobile (iOS & Android) for broad access. Offline mode mandatory; data stored locally.
- **Key Differentiators**:
  - RPG-style progression: Start at Level 1, log activities to gain EXP/stats, level up with visual flair.
  - Realism: Small daily increments, degradation for missed habits to encourage consistency without harsh punishment.
  - Polish: Modern UI with charts, avatars, animations—feels premium, not basic.
- **MVP Scope**: Core tracking + basic visuals. Future: Social sharing, API integration (e.g., for xAI tools if relevant).
- **Out-of-Scope (for v1)**: Multi-user collaboration, monetization, advanced AI (e.g., auto-suggest quests).

#### 2. Functional Requirements
Break down into core modules. Prioritize based on our web app: Dashboard, Logging, Progress Views, Settings.

- **User Onboarding**:
  - Simple registration: Local profile (name, avatar) with optional questionnaire (8 questions as discussed) to set starting stats (e.g., scale answers to 1-5 base values).
  - Skip option: Default to Level 1, stats at 1.0.
  - Tutorial: Quick swipe-through explaining mechanics (e.g., "Log workouts to build Strength!").

- **Dashboard/Home Screen**:
  - Display current Level, EXP progress bar (with percentage and threshold).
  - Stat overview: Bar chart (using Chart.js or native equivalent) for 6 attributes (Strength, Agility, Endurance, Intelligence, Focus, Charisma).
  - Quick log button: Floating action button (FAB) to add activities.
  - Daily summary: Streaks, recent logs, pending degradation warnings.

- **Activity Logging**:
  - Select from 10 activities (as in web app: Workout subtypes, Study subtypes, Meditation, Socializing, Quit Bad Habit, Sleep, Diet).
  - Input: Duration in minutes (default 60; hidden/fixed for Quit Bad Habit as daily check-in).
  - Immediate feedback: Show stat/EXP gains, animations (e.g., +0.05 pop-up).
  - Categories for degradation: Workout (physical stats), Study (mental stats).
  - Multi-log per day; timestamped history view.

- **Progression Mechanics**:
  - **EXP & Leveling**: 1 EXP/minute (or fixed 60 for Quit). Thresholds: 1000 * (1.2^(level-1)); rollover excess EXP. No stat bonuses on level up (keep simple).
  - **Stat Increments**: Time-scaled (e.g., 0.05-0.06 per hour per activity mapping). Compound daily.
  - **Degradation**: Only for Workout/Study categories. Starts after 3 missed days; -0.01 per 3-day group, cap at -0.05. Applied on app open; stats floor at 1.0. No EXP loss.
  - Visuals: Level-up animation (confetti or character glow).

- **Views/Screens**:
  - History/Log List: Calendar or scrollable list of past logs, filterable by activity.
  - Stats Detail: Deep dive per attribute with line charts over time.
  - Achievements: Unlock badges (e.g., "10 Workouts Streak")—track milestones.
  - Quests: Daily/weekly challenges (e.g., "3 Studies this week for +100 EXP bonus")—auto-generated or manual.

- **Settings & Data Management**:
  - Customize: Add/remove activities, adjust increment/decrement values.
  - Backup/Export: JSON export/import for data migration.
  - Notifications: Local push for daily reminders (e.g., "Log or risk degradation!").
  - Theme: Dark/light mode.

- **Future Expansions** (Post-MVP):
  - Cloud Sync: Firebase/Google Drive for backups.
  - Social: Share progress screenshots or leaderboards.
  - Avatars: Evolving character based on level (pixel art integration).
  - Integrations: Health APIs (e.g., Google Fit for auto-log workouts).

#### 3. Non-Functional Requirements
- **Performance**: Offline-first; fast loads (<2s). Handle 1 year of daily logs without lag.
- **Usability**: Intuitive UX—gesture-based (swipe to log), accessible (high contrast, voice-over support).
- **Security**: Local data only; no cloud in v1, but encrypt sensitive logs if added.
- **Reliability**: Auto-save after every log; crash-resistant.
- **Scalability**: Modular code for easy feature adds (e.g., new activities).
- **Tech Constraints**: Cross-platform; aim for 50MB app size max.
- **Quality Standards**: 95% test coverage; no critical bugs. Indie polish: Smooth animations, custom icons, splash screen.

#### 4. High-Level Design
- **Architecture**:
  - **Frontend**: React Native (recommended for JS familiarity from web app) or Flutter (for better performance/UI consistency). Use Redux/Flutter Bloc for state management (persist stats/EXP/logs).
  - **Backend/Data**: Local storage with SQLite or AsyncStorage (JSON-like from web app). No server; optional Firebase for future sync.
  - **Components**: Modular—e.g., ActivityLogger component, DegradationService (background check on app resume).
  - **Data Flow**: On app open: Apply degradation → Load dashboard. Log → Update state → Save → Refresh UI.

- **UI/UX Design Guidelines**:
  - **Theme**: RPG-inspired—dark fantasy colors (blues/greens for stats, red for degradation). Use Material Design (Android) / Cupertino (iOS) for native feel.
  - **Screens Layout**:
    - Home: Top: Level/EXP bar. Middle: Stat chart. Bottom: Log FAB + quick stats.
    - Log Screen: Modal or full page with dropdown for activity, slider/input for duration.
    - Progress: Tabbed (Stats, History, Achievements).
  - **Visuals**: Progress bars with gradients, bar/line charts (Recharts in RN or fl_chart in Flutter). Animations via Lottie or native.
  - **Wireframe Ideas**: Bottom nav bar (Home, Logs, Settings). Hero animations for level ups.
  - **Accessibility**: ARIA-like labels, scalable fonts.

- **Tech Stack Proposal**:
  - **Framework**: React Native (easy web-to-mobile port; Expo for quick setup) or Flutter (faster builds, better widgets).
  - **Libraries**: 
    - State: Redux Toolkit or MobX.
    - Charts: Victory (RN) or charts_flutter.
    - Storage: Realm or Hive for persistent data.
    - Notifications: react-native-push-notification.
    - Testing: Jest/Detox (RN) or Flutter's integration tests.
  - **Tools**: VS Code, Git for version control. Figma for mockups.

#### 5. Task Plan (Phased Approach)
Assume 1-2 developers (intern + you/AI oversight). Total: 4-6 weeks for MVP. Use Agile: Weekly sprints, daily standups if team-based.

- **Phase 1: Planning (Week 1)**:
  - Refine requirements: User stories (e.g., "As a user, I can log a workout to gain EXP").
  - Design: Create Figma wireframes/mockups for all screens.
  - Setup: Init repo, install framework (e.g., npx create-expo-app).
  - Milestones: Approved designs, backlog in Trello/Jira.

- **Phase 2: Core Development (Weeks 2-3)**:
  - Build onboarding and dashboard.
  - Implement logging, EXP/leveling logic (port from Python class).
  - Add degradation and stat updates.
  - Integrate local storage and basic UI (text + progress bars).
  - Tasks: 1. Data model (classes for Stats, Logs). 2. Screens setup. 3. Logic integration.

- **Phase 3: Features & Polish (Weeks 4-5)**:
  - Add charts, animations, notifications.
  - Implement history views, settings, achievements/quests.
  - Offline handling: Ensure degradation applies on resume.
  - Testing: Unit tests for mechanics; manual UI tests on emulator/device.
  - Milestones: Functional MVP; beta test on your device.

- **Phase 4: Testing & Deployment (Week 6)**:
  - Bug fixes, performance optimization.
  - Cross-platform testing (Android Emulator, iOS Simulator).
  - Build: Expo EAS for easy APK/IPA generation.
  - Deployment: Sideloading for personal use; optional Play Store/App Store submission.
  - Post-Launch: Gather feedback for v2 (e.g., cloud sync).

- **Risks & Mitigations**:
  - Complexity: Start with core (dashboard/logging) before additions.
  - Time: Prioritize MVP; defer quests if delayed.
  - Budget: Free tools; intern handles coding.

This overview should give your intern/AI editor everything needed to flesh it out—let me know if you want me to expand on any section, provide code snippets for mobile, or even generate sample React Native code based on the web app! What's next—shall we prototype a screen or refine this further?