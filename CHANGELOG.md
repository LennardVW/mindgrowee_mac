# Changelog

All notable changes to mindgrowee_mac will be documented in this file.

## [Unreleased] - develop branch

### Added
- **Widgets**: 3 widget types for Notification Center
  - HabitStatusWidget: Shows habits and completion
  - StreakWidget: Shows current and best streaks
  - QuickCompleteWidget: Complete habits from widget
- **Drag & Drop**: Reorder habits by dragging
- **View Components**: Empty states, progress rings, confetti animations
- **Tests**: Unit tests for core functionality
- **Documentation**: Comprehensive README updates
- **Accessibility**: Full VoiceOver support
  - Accessibility labels for all interactive elements
  - Proper accessibility hints and values
  - Accessibility announcements for important events
  - Reduced motion support
  - Accessibility testing helpers
- **Comprehensive Tests**: New test suite (AccessibilityAndValidationTests.swift)
  - 30+ unit tests for accessibility features
  - Validation tests for all input types
  - Error handling tests
  - Performance tests
  - Cache and throttling tests

## [1.0.0] - 2026-01-31

### Added
- **Dark Mode**: System or manual dark mode toggle
- **Theme Support**: 7 accent colors
- **Keyboard Shortcuts Help**: View all shortcuts with Cmd+?
- **About View**: App information and credits
- **Accessibility**: VoiceOver support and announcements
- **Haptic Feedback**: System feedback for actions
- **Notifications**: Habit reminders, evening summary, streak alerts
- **Sound Effects**: Audio feedback on completion
- **Habit Details**: Edit habits and set reminders
- **Journal Search**: Search by content and tags
- **Streak Freezes**: Protect streaks (3 max, regenerate every 7 days)
- **Period Statistics**: Week/Month/Year/All Time stats
- **Menu Bar Mode**: Quick access from menu bar
- **Import/Export**: JSON, Markdown, CSV formats
- **Settings**: Comprehensive preferences panel

### Core Features
- Habit tracking with daily reset
- Journal with mood and tags
- Statistics and streaks
- Local SwiftData storage
- Keyboard shortcuts
- Export/Import functionality

## Initial Release

- Basic habit tracking
- Journal entries
- Simple statistics
- Local storage
