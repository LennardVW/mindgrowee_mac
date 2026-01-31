import SwiftUI
import WidgetKit
import SwiftData

// MARK: - Widget Models

struct HabitProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), habits: [], completedCount: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> ()) {
        let entry = HabitEntry(date: Date(), habits: [], completedCount: 0)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> ()) {
        var entries: [HabitEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = HabitEntry(date: entryDate, habits: [], completedCount: 0)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [HabitWidgetData]
    let completedCount: Int
}

struct HabitWidgetData {
    let id: UUID
    let title: String
    let icon: String
    let color: String
    let isCompleted: Bool
}

// MARK: - Habit Widget View

struct HabitWidgetView: View {
    var entry: HabitProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                
                Text("Habits")
                    .font(.headline)
                
                Spacer()
                
                if family != .systemSmall {
                    Text("\(entry.completedCount)/\(entry.habits.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Habits list
            if entry.habits.isEmpty {
                Text("No habits yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.habits.prefix(family == .systemSmall ? 3 : 5), id: \.id) { habit in
                    HStack {
                        Image(systemName: habit.icon)
                            .foregroundStyle(colorFor(habit.color))
                        
                        Text(habit.title)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(habit.isCompleted ? .green : .gray)
                    }
                }
            }
        }
        .padding()
    }
    
    private func colorFor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}

// MARK: - Habit Widget

@main
struct MindGroweeWidgets: WidgetBundle {
    var body: some Widget {
        HabitStatusWidget()
        StreakWidget()
        QuickCompleteWidget()
    }
}

struct HabitStatusWidget: Widget {
    let kind: String = "HabitStatusWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            HabitWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit Status")
        .description("View your daily habits and completion progress")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Streak Widget

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), currentStreak: 7, bestStreak: 14)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> ()) {
        let entry = StreakEntry(date: Date(), currentStreak: 7, bestStreak: 14)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> ()) {
        var entries: [StreakEntry] = []
        let currentDate = Date()
        
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = StreakEntry(date: entryDate, currentStreak: 7, bestStreak: 14)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let bestStreak: Int
}

struct StreakWidgetView: View {
    var entry: StreakProvider.Entry
    
    var body: some View {
        VStack(spacing: 12) {
            // Current Streak
            VStack(spacing: 4) {
                Text("\(entry.currentStreak)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.orange)
                
                Text("day streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 2) {
                    ForEach(0..<min(entry.currentStreak, 7), id: \.self) { _ in
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            // Best Streak
            HStack {
                Text("Best:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(entry.bestStreak)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .padding()
    }
}

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak Counter")
        .description("Track your current and best streaks")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Quick Complete Widget

struct QuickCompleteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickCompleteEntry {
        QuickCompleteEntry(date: Date(), topHabit: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickCompleteEntry) -> ()) {
        let entry = QuickCompleteEntry(date: Date(), topHabit: nil)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickCompleteEntry>) -> ()) {
        var entries: [QuickCompleteEntry] = []
        let currentDate = Date()
        
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = QuickCompleteEntry(date: entryDate, topHabit: nil)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct QuickCompleteEntry: TimelineEntry {
    let date: Date
    let topHabit: QuickHabitData?
}

struct QuickHabitData {
    let id: UUID
    let title: String
    let icon: String
}

struct QuickCompleteWidgetView: View {
    var entry: QuickCompleteProvider.Entry
    
    var body: some View {
        VStack(spacing: 12) {
            if let habit = entry.topHabit {
                Text("Quick Complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Image(systemName: habit.icon)
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                
                Text(habit.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Button(intent: CompleteHabitIntent(habitId: habit.id.uuidString)) {
                    Label("Done", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Text("All done! 🎉")
                    .font(.headline)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }
        }
        .padding()
    }
}

struct QuickCompleteWidget: Widget {
    let kind: String = "QuickCompleteWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CompleteHabitIntent.self,
            provider: QuickCompleteProvider()
        ) { entry in
            QuickCompleteWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Complete")
        .description("Quickly complete your next habit")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - App Intent

struct CompleteHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Habit"
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    init() {}
    
    init(habitId: String) {
        self.habitId = habitId
    }
    
    func perform() async throws -> some IntentResult {
        // This would complete the habit in the app
        return .result()
    }
}
