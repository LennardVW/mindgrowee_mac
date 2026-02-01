import SwiftUI
import SwiftData

@main
struct MindGroweeMacApp: App {
    init() {
        // When running as a bare executable (not an .app bundle),
        // macOS doesn't activate the process as a foreground app.
        // This ensures keyboard input works in TextFields/TextEditors.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Habit.self, DailyCompletion.self, JournalEntry.self, StreakFreeze.self, HabitCategory.self, FocusMode.self, Project.self, Milestone.self])
    }
}
