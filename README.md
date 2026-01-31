# mindgrowee_mac

Native macOS Habit Tracker & Journal App built with SwiftUI.

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
├── Habit (id, title, icon, color)
├── DailyCompletion (date, completed, habit relationship)
└── JournalEntry (date, content, mood, tags)

Views/
├── HabitsView (main habit tracking)
├── JournalView (journal entries)
├── StatisticsView (charts and stats)
├── MenuBarView (menu bar quick access)
├── ExportView (data export)
└── SettingsView (preferences + import)
```

## Key Design Decisions

1. **Daily Reset**: Habits automatically reset each day so you can build streaks
2. **Local Only**: No cloud sync, no accounts, completely private
3. **Persistent Data**: History and stats are kept forever
4. **Menu Bar Mode**: Always accessible without cluttering dock
5. **Keyboard Driven**: Fast actions without mouse
6. **Data Portability**: Export and import in multiple formats
7. **Full Control**: Settings for launch, appearance, and data management

## License

MIT
