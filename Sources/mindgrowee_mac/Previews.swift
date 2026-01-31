import SwiftUI
import SwiftData

// MARK: - Preview Container

@MainActor
let previewContainer: ModelContainer = {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Habit.self,
            DailyCompletion.self,
            JournalEntry.self,
            configurations: config
        )
        
        // Add sample data
        let context = container.mainContext
        
        // Sample habits
        let habit1 = Habit(title: "Morning Exercise", icon: "figure.walk", color: "green")
        let habit2 = Habit(title: "Read 30 Minutes", icon: "book.fill", color: "blue")
        let habit3 = Habit(title: "Meditate", icon: "moon.fill", color: "purple")
        
        context.insert(habit1)
        context.insert(habit2)
        context.insert(habit3)
        
        // Sample completions
        let today = Date()
        let completion1 = DailyCompletion(date: today, completed: true, habit: habit1)
        let completion2 = DailyCompletion(date: today, completed: false, habit: habit2)
        
        context.insert(completion1)
        context.insert(completion2)
        
        // Sample journal entries
        let entry1 = JournalEntry(
            date: today,
            content: "Had a great day today! Completed all my habits and felt productive.",
            mood: 5,
            tags: ["productive", "happy"]
        )
        
        let entry2 = JournalEntry(
            date: Calendar.current.date(byAdding: .day, value: -1, to: today)!,
            content: "Was a bit tired today but still managed to get some things done.",
            mood: 3,
            tags: ["tired", "okay"]
        )
        
        context.insert(entry1)
        context.insert(entry2)
        
        return container
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}()

// MARK: - Preview Helpers

struct PreviewHelpers {
    static let sampleHabits: [Habit] = [
        Habit(title: "Exercise", icon: "figure.walk", color: "green"),
        Habit(title: "Read", icon: "book.fill", color: "blue"),
        Habit(title: "Meditate", icon: "moon.fill", color: "purple")
    ]
    
    static let sampleJournalEntries: [JournalEntry] = [
        JournalEntry(date: Date(), content: "Great day!", mood: 5, tags: ["happy"]),
        JournalEntry(date: Date(), content: "Okay day", mood: 3, tags: ["okay"])
    ]
}

// MARK: - View Previews

#if DEBUG
struct HabitsView_Previews: PreviewProvider {
    static var previews: some View {
        HabitsView()
            .modelContainer(previewContainer)
    }
}

struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        JournalView()
            .modelContainer(previewContainer)
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .modelContainer(previewContainer)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(previewContainer)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .modelContainer(previewContainer)
    }
}

struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
            .modelContainer(previewContainer)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

struct KeyboardShortcutsView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardShortcutsView()
    }
}

struct EmptyHabitsView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyHabitsView(onCreate: {})
    }
}

struct LoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        LoadingOverlay()
    }
}

struct SuccessAnimation_Previews: PreviewProvider {
    static var previews: some View {
        SuccessAnimation()
    }
}

struct AnimatedCheckmark_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedCheckmark()
    }
}

struct SkeletonView_Previews: PreviewProvider {
    static var previews: some View {
        SkeletonView()
            .frame(width: 200, height: 100)
    }
}

struct TipView_Previews: PreviewProvider {
    static var previews: some View {
        TipView(
            tip: Tip(
                title: "Did you know?",
                message: "You can use keyboard shortcuts to quickly complete habits!",
                icon: "keyboard"
            ),
            onDismiss: {}
        )
    }
}

struct QuickActionButton_Previews: PreviewProvider {
    static var previews: some View {
        QuickActionButton(
            action: .completeFirstHabit,
            onTap: {}
        )
    }
}
#endif
