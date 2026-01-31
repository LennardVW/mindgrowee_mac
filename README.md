# mindgrowee_mac

[![macOS](https://img.shields.io/badge/macOS-14.0+-blue)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-green)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/LennardVW/mindgrowee_mac/ci.yml?branch=main)](https://github.com/LennardVW/mindgrowee_mac/actions)

Native macOS Habit Tracker & Journal App built with SwiftUI. Track habits, journal your thoughts, and build better routines - all stored locally on your Mac.

![MindGrowee Screenshot](Assets/screenshot.png)

## Features

### 📝 Habit Tracker
- Create and track daily habits
- Choose from 15 different icons
- 7 color options for each habit
- **Daily Reset**: Habits reset every day at midnight
- Progress tracking with visual indicators
- Completion rate statistics

### 📔 Journal
- Daily journal entries
- Mood tracking (1-5 stars)
- Tag system for organization
- Full history view

### 📊 Statistics
- Total habits count
- Today's completion progress
- Current streak tracking
- Best streak record
- Journal entry count
- Average mood calculation
- 7-day completion chart

### 🎛️ Menu Bar Mode
- Run in menu bar for quick access
- Check habits without opening main window
- Quick stats overview
- Fast journal entry
- Open main window anytime

### ⌨️ Keyboard Shortcuts
- `Cmd+D` - Quick complete habits
- `Cmd+Shift+N` - New habit
- `Cmd+J` - New journal entry
- `Cmd+Shift+E` - Export data
- `Cmd+,` - Settings

### ⚙️ Settings
- Launch at login
- Menu bar visibility toggle
- Dock icon toggle
- Sound effects toggle
- Custom streak goals
- Data management (import/export/reset)

### 📤 Export Data
- Export as **JSON** (structured data)
- Export as **Markdown** (readable format)
- Export as **CSV** (spreadsheet compatible)
- Saved to Downloads folder
- Includes all habits, completions, and journal entries

### 📥 Import Data
- Import from previously exported JSON
- File picker or paste text
- Validates data format
- Merge with existing data

### 🌙 Appearance
- Dark mode support (system or manual)
- 7 accent colors to choose from
- Live theme switching

### 🔔 Notifications
- Daily habit reminders (custom time per habit)
- Evening summary at 8 PM
- Streak reminders for active streaks

### 🔊 Sound Effects
- Audio feedback on habit completion
- Success sounds for milestones
- Toggle in settings

### ✏️ Habit Details
- Edit habit name, icon, color
- Set daily reminder time
- View individual habit statistics
- Check completion history

### 🔍 Journal Search
- Search by content
- Search by tags
- Real-time filtering

### ❄️ Streak Freezes
- Protect your streaks when you can't complete habits
- 3 freezes max, regenerate every 7 days
- Track freeze usage history

### 📊 Period Statistics
- View stats by Week, Month, Year, or All Time
- Completion rates per period
- Habit performance with progress bars

### 📱 Widgets (macOS Sonoma+)
- Habit Status widget
- Streak counter widget
- Quick complete widget

### 🎨 UI/UX
- Drag & drop to reorder habits
- Empty state illustrations
- Progress rings
- Confetti animations for milestones

### ⌨️ Extended Shortcuts
- `Cmd+?` - Keyboard shortcuts help
- `Cmd+1/2/3` - Switch tabs
- `Cmd+F` - Focus search (in Journal)

## Tech Stack

- **Swift 5.9**
- **SwiftUI**
- **SwiftData** (Local storage - no cloud)
- **macOS 14.0+**

## Local Storage

All data is stored locally using SwiftData:
- Habits and their settings
- Daily completion records
- Journal entries with timestamps
- **Data persists** across app restarts
- **Habits reset daily** - each day starts fresh for tracking
- **Export anytime** - your data is always portable

## Build & Run

```bash
cd mindgrowee_mac
swift build
swift run
```

Or open in Xcode and run.

## Architecture

```
Models/
├── Habit (id, title, icon, color, createdAt)
├── DailyCompletion (date, completed, habit relationship)
├── JournalEntry (date, content, mood, tags)
└── StreakFreeze (date, reason, isUsed)

Views/
├── HabitsView (main habit tracking)
├── JournalView (journal entries + search)
├── StatisticsView (charts and stats)
├── PeriodStatsView (detailed period stats)
├── MenuBarView (menu bar quick access)
├── ExportView (data export)
├── SettingsView (preferences + import)
├── HabitDetailView (edit habit + reminders)
├── StreakFreezeView (freeze management)
├── KeyboardShortcutsView (help)
└── AboutView (app info)

Managers/
├── NotificationManager (local notifications)
├── SoundManager (audio feedback)
├── ThemeManager (dark mode + colors)
├── StreakFreezeManager (freeze logic)
├── AccessibilityManager (voiceover)
└── HapticManager (feedback)

Widgets/
├── HabitStatusWidget
├── StreakWidget
└── QuickCompleteWidget
```

## Key Design Decisions

1. **Daily Reset**: Habits automatically reset each day so you can build streaks
2. **Local Only**: No cloud sync, no accounts, completely private
3. **Persistent Data**: History and stats are kept forever
4. **Menu Bar Mode**: Always accessible without cluttering dock
5. **Keyboard Driven**: Fast actions without mouse
6. **Data Portability**: Export and import in multiple formats
7. **Full Control**: Settings for launch, appearance, and data management
8. **Accessibility**: VoiceOver support, keyboard navigation, high contrast
9. **Widgets**: Extend functionality to Notification Center
10. **Modular**: Separate concerns into focused files

## Testing

Run tests with:
```bash
swift test
```

Tests cover:
- Date helper functions
- Streak calculations
- Theme color conversions
- Streak freeze logic

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/) and [SwiftData](https://developer.apple.com/documentation/swiftdata)
- Inspired by the need for a simple, private habit tracker on macOS
- Thanks to the Swift open-source community for documentation and examples

## Support

- Report issues on [GitHub Issues](https://github.com/LennardVW/mindgrowee_mac/issues)
- Follow development on the [develop branch](https://github.com/LennardVW/mindgrowee_mac/tree/develop)
- Read the [Contributing Guide](CONTRIBUTING.md) to get involved

---

<p align="center">
  Built with ❤️ for the macOS community
</p>
