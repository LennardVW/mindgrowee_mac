# Architecture Documentation

## Overview

MindGrowee is a native macOS application built with SwiftUI and SwiftData. This document describes the high-level architecture and design decisions.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        macOS App                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                      UI Layer                          │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │  │
│  │  │  HabitsView  │ │  JournalView │ │ StatisticsView│  │  │
│  │  └──────────────┘ └──────────────┘ └──────────────┘  │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │  │
│  │  │ MenuBarView  │ │ SettingsView │ │  ExportView  │  │  │
│  │  └──────────────┘ └──────────────┘ └──────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   Business Logic                       │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │  │
│  │  │   Managers   │ │   Services   │ │  Validation  │  │  │
│  │  └──────────────┘ └──────────────┘ └──────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                     Data Layer                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │                  SwiftData                       │  │  │
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐        │  │  │
│  │  │  │  Habit   │ │ Journal  │ │ Category │        │  │  │
│  │  │  └──────────┘ └──────────┘ └──────────┘        │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Layer Description

### 1. UI Layer (Views)

**Responsibilities:**
- Display data to users
- Handle user interactions
- Manage view state

**Key Components:**
- `ContentView`: Main window with tab navigation
- `HabitsView`: Habit tracking interface
- `JournalView`: Journal entry management
- `StatisticsView`: Analytics and charts
- `MenuBarView`: Menu bar popover UI
- `SettingsView`: App configuration

**Design Patterns:**
- MVVM (Model-View-ViewModel) via SwiftUI
- `@Query` for data fetching
- `@State` and `@Binding` for state management

### 2. Business Logic Layer

**Responsibilities:**
- Business rules and calculations
- Data transformation
- Coordination between UI and Data layers

**Managers:**
- `FocusModeManager`: Handles focus mode switching
- `CategoryManager`: Manages habit categories
- `StreakFreezeManager`: Tracks streak freeze usage
- `NotificationManager`: Handles local notifications
- `ThemeManager`: Manages app appearance
- `BackupManager`: Handles data backup/restore

**Services:**
- `SoundManager`: Audio feedback
- `SpotlightIndexManager`: Spotlight integration
- `PerformanceMonitor`: Performance tracking

**Validation:**
- `DataValidator`: Input validation
- `ErrorHandler`: Error presentation

### 3. Data Layer

**Responsibilities:**
- Data persistence
- Model definitions
- Relationships

**Models:**
```swift
Habit
├── id: UUID
├── title: String
├── icon: String
├── color: String
├── categoryId: UUID?
├── createdAt: Date
└── completions: [DailyCompletion]

DailyCompletion
├── id: UUID
├── date: Date
├── completed: Bool
└── habit: Habit?

JournalEntry
├── id: UUID
├── date: Date
├── content: String
├── mood: Int
└── tags: [String]

HabitCategory
├── id: UUID
├── name: String
├── icon: String
├── color: String
└── sortOrder: Int

FocusMode
├── id: UUID
├── name: String
├── icon: String
├── color: String
└── habitIds: [UUID]
```

**Storage:**
- SwiftData (iOS 17+/macOS 14+)
- Local SQLite database
- Stored in Application Support directory

## Key Design Decisions

### 1. Local-First Architecture

**Decision:** All data stored locally, no cloud sync by default.

**Rationale:**
- Privacy-first approach
- Works offline
- No subscription required
- User owns their data

**Trade-offs:**
- No automatic sync between devices
- Manual export/import for backup

### 2. SwiftData Over Core Data

**Decision:** Use SwiftData instead of Core Data.

**Rationale:**
- Modern Swift-native API
- Better SwiftUI integration
- Type-safe queries
- Less boilerplate

**Trade-offs:**
- Requires macOS 14.0+
- Less mature than Core Data

### 3. Notification-Based Communication

**Decision:** Use `NotificationCenter` for cross-view communication.

**Rationale:**
- Decouples views from each other
- Easy to extend
- Works well with menu bar and shortcuts

**Examples:**
```swift
NotificationCenter.default.post(name: .showSettings, object: nil)
NotificationCenter.default.post(name: .completeAllHabits, object: nil)
```

### 4. Singleton Managers

**Decision:** Use singleton pattern for managers.

**Rationale:**
- Single source of truth
- Easy access from anywhere
- State persistence across views

**Managers:**
- `ThemeManager.shared`
- `FocusModeManager.shared`
- `BackupManager.shared`

## Performance Considerations

### 1. Data Fetching

- Use `@Query` for automatic updates
- Fetch only necessary fields
- Lazy loading for relationships

### 2. Caching

- `MemoryCache` for expensive computations
- `ImageCache` for image data
- Throttling for rapid updates

### 3. Background Tasks

- Backup creation in background
- Spotlight indexing async
- Heavy computations off main thread

## Security Architecture

### Data Protection

1. **Local Storage:** Data stored in app container
2. **No Network:** No network requests
3. **No Analytics:** No tracking or telemetry
4. **User Control:** Full export/import control

### Privacy

- No personal information collected
- No third-party SDKs
- Optional notifications only

## Testing Strategy

### Unit Tests

- Model validation
- Business logic
- Utility functions

### Integration Tests

- Data persistence
- UI interactions
- Manager coordination

### UI Tests

- End-to-end workflows
- Screenshot automation

## Build & Deployment

### Development

```bash
swift build
swift test
swift run
```

### CI/CD Pipeline

1. **GitHub Actions:**
   - Build on push/PR
   - Run tests
   - SwiftLint checks

2. **Release Process:**
   - Tag creation triggers release
   - Automated GitHub release
   - Asset upload

### Distribution

- **GitHub Releases:** Direct download
- **App Store:** Future consideration
- **Homebrew:** Potential option

## Extension Points

### Widgets

- `HabitStatusWidget`
- `StreakWidget`
- `QuickCompleteWidget`

### Share Extension

- Share to MindGrowee from other apps

### Shortcuts App

- Automate habit completion
- Query statistics

## Future Considerations

### Scalability

- Current: ~1000 habits, ~10000 entries
- Future: May need pagination for very large datasets

### Platform Expansion

- iOS companion app
- watchOS app
- Web dashboard (read-only)

---

*This document should be updated as the architecture evolves.*
