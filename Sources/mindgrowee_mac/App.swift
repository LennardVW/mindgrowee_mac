import SwiftUI
import SwiftData

@main
struct MindGroweeMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Habit.self, DailyCompletion.self, JournalEntry.self, StreakFreeze.self, HabitCategory.self, FocusMode.self, Project.self, Milestone.self])
    }
}
