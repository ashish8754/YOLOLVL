# Solo Leveling Theme System

A comprehensive theme system inspired by the Solo Leveling manhwa, designed to provide an immersive dark fantasy gaming experience for the YoLvL Flutter app.

## Overview

The Solo Leveling theme system consists of:

- **Color Palette**: Dark, mysterious colors with electric blue and hunter green accents
- **Hunter Rank System**: Complete rank-based color coding (E through SSS ranks)
- **Typography**: Bold, futuristic text styles for system notifications and UI elements
- **Glassmorphism Effects**: Custom frosted glass and translucent panel effects
- **Gradients**: Epic background and UI element gradients

## Quick Start

### 1. Apply Theme to MaterialApp

```dart
import 'package:yolvl/theme/solo_leveling_theme.dart';

MaterialApp(
  theme: SoloLevelingTheme.buildLightTheme(), // For accessibility
  darkTheme: SoloLevelingTheme.buildDarkTheme(), // Main Solo Leveling theme
  themeMode: ThemeMode.dark, // Use dark theme by default
  // ... rest of your app
)
```

### 2. Access Colors and Typography

```dart
import 'package:yolvl/theme/solo_leveling_theme.dart';

// Use colors directly
Container(
  color: SoloLevelingColors.hunterGreen,
  child: Text(
    'Level Up!',
    style: SoloLevelingTypography.hunterTitle,
  ),
)

// Use hunter rank colors
final rankColor = HunterRankColors.getRankColor('S');
```

### 3. Apply Glassmorphism Effects

```dart
import 'package:yolvl/theme/glassmorphism_effects.dart';

// Basic glassmorphic container
Text('Stats').withGlass(
  padding: EdgeInsets.all(16),
  blur: 15.0,
);

// Hunter-themed panel
Text('Hunter Info').withHunterPanel(
  glowEffect: true,
);

// System interface panel
Text('System Message').withSystemPanel(
  isActive: true,
);
```

## Color System

### Base Theme Colors
- **Void Black**: `#000000` - Deepest shadows
- **Midnight Base**: `#0A0B1E` - Primary background
- **Shadow Depth**: `#161B22` - Secondary surfaces
- **Deep Shadow**: `#21262D` - Subtle borders and dividers

### Primary Colors
- **Hunter Green**: `#10B981` - Success, stats, progress
- **Electric Blue**: `#6366F1` - System interface, EXP, magic
- **Mystic Purple**: `#8B5CF6` - Special abilities, rare items
- **Crimson Red**: `#EF4444` - Danger, warnings, critical

### Text Colors
- **Pure Light**: `#F8FAFC` - Primary text on dark backgrounds
- **Ghost White**: `#F1F5F9` - Secondary text
- **Silver Mist**: `#CBD5E1` - Subtle text and labels
- **Shadow Gray**: `#64748B` - Disabled or inactive text

## Hunter Rank Colors

The theme includes a complete hunter ranking system from Solo Leveling:

| Rank | Color | Description |
|------|-------|-------------|
| E | Gray `#6B7280` | Weakest hunters |
| D | Brown `#92400E` | Below average |
| C | Green `#047857` | Average hunters |
| B | Blue `#1D4ED8` | Above average |
| A | Purple `#7C3AED` | Elite hunters |
| S | Gold `#D97706` | National level |
| SS | Silver `#64748B` | Extremely rare |
| SSS | Rainbow/Prismatic | Legendary (multiple colors) |

```dart
// Get rank color
final color = HunterRankColors.getRankColor('S'); // Returns gold
final lightColor = HunterRankColors.getRankColor('S', light: true);
```

## Typography System

### Hunter-Themed Styles
- **Hunter Title**: Bold, dramatic headings with electric blue color
- **Hunter Subtitle**: Strong subheadings with hunter green
- **Rank Display**: Special style for displaying hunter ranks

### System Interface Styles
- **System Notification**: Clean system messages
- **System Alert**: Urgent notifications in crimson red
- **Stat Value**: Large, bold numbers for displaying stats
- **Level Display**: Epic level number display

### Usage Example
```dart
Text(
  'LEVEL UP!',
  style: SoloLevelingTypography.levelDisplay,
)

Text(
  'You are now an S-Rank Hunter',
  style: SoloLevelingTypography.hunterTitle.copyWith(
    color: HunterRankColors.getRankColor('S'),
  ),
)
```

## Glassmorphism Effects

### Available Effects

#### 1. Basic Glassmorphic Container
```dart
GlassmorphismEffects.glassmorphicContainer(
  blur: 10.0,
  opacity: 0.1,
  child: YourWidget(),
)

// Or use extension
YourWidget().withGlass(blur: 15.0)
```

#### 2. Hunter Panel
Advanced panel with gradient background and optional glow effect:
```dart
GlassmorphismEffects.hunterPanel(
  glowEffect: true,
  child: YourWidget(),
)
```

#### 3. System Panel
Interface-style panel with active state support:
```dart
GlassmorphismEffects.systemPanel(
  isActive: true,
  child: YourWidget(),
)
```

#### 4. Stat Card
Rank-based colored card for displaying statistics:
```dart
GlassmorphismEffects.statCard(
  rank: 'S',
  child: StatWidget(),
)
```

#### 5. Achievement Notification
Special notification panel for achievements:
```dart
GlassmorphismEffects.achievementNotification(
  child: AchievementWidget(),
)
```

#### 6. Level Up Overlay
Celebration overlay for level up events:
```dart
GlassmorphismEffects.levelUpOverlay(
  isVisible: showLevelUp,
  onAnimationComplete: () => setState(() => showLevelUp = false),
  child: YourContent(),
)
```

## Gradients

### Available Gradients
- **Main Background**: Deep midnight to void black gradient
- **Hunter Progress**: Hunter green to electric blue
- **System Panel**: Gray gradient for interface elements
- **Level Up Celebration**: Radial gold gradient for celebrations
- **Stat-Specific Gradients**: Individual gradients for each stat type

### Usage
```dart
Container(
  decoration: BoxDecoration(
    gradient: SoloLevelingGradients.mainBackground,
  ),
  child: YourContent(),
)
```

## System Colors

Special colors for specific UI feedback:

- **System Success**: `#10B981` - Achievements, completions
- **System Warning**: `#F59E0B` - Cautions, important notices
- **System Error**: `#EF4444` - Errors, failures
- **System Info**: `#6366F1` - Information, tips
- **Level Up Glow**: `#FFD700` - Level up celebrations
- **Critical Hit**: `#FF6B6B` - Combat feedback
- **Healing Green**: `#51CF66` - Health restoration
- **Mana Blue**: `#4DABF7` - Magic/skill usage

## Accessibility

The theme system maintains accessibility compliance:

- **High Contrast**: All color combinations meet WCAG contrast requirements
- **Light Theme**: Available for users who prefer light backgrounds
- **Text Scaling**: Supports system text scaling preferences
- **Screen Readers**: Semantic color usage with proper labels

## Integration with Flutter Theme

The Solo Leveling theme integrates seamlessly with Flutter's Material Design 3 theming system:

- **ColorScheme**: Properly mapped to Material Design roles
- **TextTheme**: Complete text theme hierarchy
- **Component Themes**: Pre-configured themes for buttons, cards, inputs, etc.

## Demo

See `theme_demo.dart` for a comprehensive showcase of all theme features and usage examples.

## Dependencies

- `flutter_animate: ^4.5.0` - For advanced animations (added to pubspec.yaml)
- Custom glassmorphism implementation (no external dependency)

## File Structure

```
lib/theme/
├── solo_leveling_theme.dart      # Main theme system
├── glassmorphism_effects.dart    # Glassmorphism widgets
├── theme_demo.dart              # Usage examples
└── README.md                    # This documentation
```

## Best Practices

1. **Use semantic colors**: Prefer `SoloLevelingColors.hunterGreen` over hardcoded hex values
2. **Leverage extensions**: Use `.withGlass()` and similar extensions for cleaner code
3. **Respect rank hierarchy**: Use appropriate rank colors for user progression display
4. **Maintain consistency**: Stick to the established color palette and typography
5. **Test accessibility**: Ensure your implementations work with screen readers and high contrast modes

## Performance Considerations

- Glassmorphism effects use `BackdropFilter` which can be expensive on older devices
- Consider reducing blur radius on low-end devices
- Use `RepaintBoundary` around complex glassmorphic widgets if needed

## Future Enhancements

- Particle effects for special events
- Animated gradients for active states
- Season/event theme variations
- Additional hunter rank visual effects
- Custom shader effects for SSS rank items