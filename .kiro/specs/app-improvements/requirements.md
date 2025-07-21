# Requirements Document

## Introduction

This specification addresses three critical improvements to the YoloLeveling app based on user feedback: implementing stat reversal when activities are deleted from history, removing the stat ceiling to allow infinite progression, and fixing the UI overlap issue between the log activity button and stats tab.

## Requirements

### Requirement 1: Activity Deletion with Stat Reversal

**User Story:** As a user, I want my stats to be correctly adjusted when I delete an activity from my history, so that my progression accurately reflects only the activities I've actually completed.

#### Acceptance Criteria

1. WHEN a user deletes an activity from the history section THEN the system SHALL reverse the stat gains that were applied when the activity was originally logged
2. WHEN an activity is deleted THEN the system SHALL reverse the EXP gains that were awarded for that activity
3. WHEN stat reversals are calculated THEN the system SHALL use the exact same stat increment values that were applied during the original logging
4. WHEN EXP is reversed THEN the system SHALL handle level-down scenarios if the user's EXP falls below the current level threshold
5. WHEN a level-down occurs THEN the system SHALL adjust the user's level appropriately and recalculate the EXP progress
6. WHEN stats are reversed THEN the system SHALL NOT allow any stat to fall below 1.0 (the minimum floor value)
7. WHEN an activity deletion is confirmed THEN the system SHALL update all relevant UI components immediately to reflect the changes

### Requirement 2: Infinite Stat Progression

**User Story:** As a user, I want my stats to continue growing beyond the current ceiling of 5, so that I can see unlimited progression as I continue to improve myself over time.

#### Acceptance Criteria

1. WHEN stats are calculated THEN the system SHALL remove the current ceiling of 5 and allow stats to grow infinitely
2. WHEN the onboarding questionnaire is completed THEN the system SHALL still convert answers to the 1-5 range as the starting baseline
3. WHEN activities are logged THEN the system SHALL continue to apply the same stat increment rates (e.g., 0.06/hour for Strength from weight training) without any upper limit
4. WHEN stats exceed 5 THEN the system SHALL display them with appropriate precision (e.g., showing 7.23 instead of capping at 5.00)
5. WHEN the stats overview chart is displayed THEN the system SHALL automatically scale the chart to accommodate higher stat values
6. WHEN degradation is applied THEN the system SHALL still respect the 1.0 minimum floor but allow recovery to any level above that
7. WHEN backup/export functionality is used THEN the system SHALL properly save and restore stat values above 5

### Requirement 3: UI Layout Fix for Activity Button Overlap

**User Story:** As a user, I want the log activity button to not overlap with the stats tab, so that I can access both features without UI interference.

#### Acceptance Criteria

1. WHEN the main navigation screen is displayed THEN the system SHALL ensure the floating action button (log activity) does not overlap with the stats tab or any other UI elements
2. WHEN the bottom navigation is visible THEN the system SHALL position the floating action button with appropriate margin above the navigation bar
3. WHEN different screen sizes are used THEN the system SHALL maintain proper spacing and avoid overlaps across all supported device dimensions
4. WHEN the user switches between tabs THEN the system SHALL maintain consistent floating action button positioning
5. WHEN the floating action button is tapped THEN the system SHALL remain easily accessible without requiring users to navigate away from any tab
6. WHEN the UI is displayed THEN the system SHALL ensure all interactive elements have sufficient touch targets and spacing
7. WHEN accessibility features are enabled THEN the system SHALL maintain proper spacing for screen readers and high contrast modes