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
└── StatisticsView (charts and stats)
```

## Key Design Decisions

1. **Daily Reset**: Habits automatically reset each day so you can build streaks
2. **Local Only**: No cloud sync, no accounts, completely private
3. **Persistent Data**: History and stats are kept forever
4. **Simple & Fast**: Native macOS performance

## License

MIT
