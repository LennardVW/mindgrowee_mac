import SwiftUI
import SwiftData

// MARK: - Content View

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingExport = false
    @State private var showingSettings = false
    @State private var showingKeyboardShortcuts = false
    @State private var showingAbout = false
    @State private var showingOnboarding = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
                }
                .tag(0)
            
            HabitsView()
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle.fill")
                }
                .tag(1)
            
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(2)
            
            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "folder.fill")
                }
                .tag(3)
            
            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar {
            ToolbarItem {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
                .help("Settings")
            }
            
            ToolbarItem {
                Button(action: { showingExport = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("Export Data")
            }
        }
        .sheet(isPresented: $showingExport) {
            ExportView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingKeyboardShortcuts) {
            KeyboardShortcutsView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .onAppear {
            if !OnboardingManager.shared.hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
    }
}

// MARK: - Habits View

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    
    @State private var showingAddHabit = false
    @State private var showingStreakFreeze = false
    @State private var newHabitTitle = ""
    @State private var selectedIcon = "star.fill"
    
    private let icons = ["star.fill", "heart.fill", "bolt.fill", "flame.fill", "drop.fill", "moon.fill", "sun.max.fill", "figure.walk", "book.fill", "pencil", "guitars.fill", "tv.fill", "gamecontroller.fill", "cart.fill", "creditcard.fill"]
    private let colors = ["red", "orange", "yellow", "green", "blue", "purple", "pink"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Today's Habits")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingStreakFreeze = true }) {
                    Image(systemName: "snowflake")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                
                Button(action: { showingAddHabit = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Text(todayString())
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ProgressView(value: completionRate())
                .padding(.horizontal)
            
            Text("\(completedCount()) of \(habits.count) completed")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            
            List {
                ForEach(habits) { habit in
                    HabitRow(habit: habit)
                }
            }
            .listStyle(.inset)
        }
        .sheet(isPresented: $showingAddHabit) {
            AddHabitSheet(
                title: $newHabitTitle,
                icon: $selectedIcon,
                icons: icons,
                onSave: addHabit,
                onCancel: { showingAddHabit = false }
            )
        }
        .sheet(isPresented: $showingStreakFreeze) {
            StreakFreezeView()
        }
    }
    
    private func todayString() -> String {
        DateFormatter().with { $0.dateStyle = .full }.string(from: Date())
    }
    
    private func completionRate() -> Double {
        guard !habits.isEmpty else { return 0 }
        return Double(completedCount()) / Double(habits.count)
    }
    
    private func completedCount() -> Int {
        let today = startOfDay(Date())
        return habits.filter { habit in
            habit.completions?.contains { completion in
                isSameDay(completion.date, today) && completion.completed
            } ?? false
        }.count
    }
    
    private func addHabit() {
        let trimmedTitle = newHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let safeIcon = icons.contains(selectedIcon) ? selectedIcon : "star.fill"
        let safeColor = colors.randomElement() ?? "blue"
        
        let habit = Habit(title: trimmedTitle, icon: safeIcon, color: safeColor)
        modelContext.insert(habit)
        newHabitTitle = ""
        showingAddHabit = false
    }
}

// MARK: - Habit Row

struct HabitRow: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            Image(systemName: habit.icon)
                .font(.title2)
                .foregroundStyle(colorFor(habit.color))
                .frame(width: 40)
            
            Text(habit.title)
                .font(.title3)
            
            Spacer()
            
            Button(action: toggleCompletion) {
                Image(systemName: isCompletedToday() ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompletedToday() ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    private func isCompletedToday() -> Bool {
        let today = startOfDay(Date())
        return habit.completions?.contains { completion in
            isSameDay(completion.date, today) && completion.completed
        } ?? false
    }
    
    private func toggleCompletion() {
        let today = startOfDay(Date())
        if let existing = habit.completions?.first(where: { isSameDay($0.date, today) }) {
            existing.completed.toggle()
        } else {
            let completion = DailyCompletion(date: today, completed: true, habit: habit)
            modelContext.insert(completion)
        }
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

// MARK: - Add Habit Sheet

struct AddHabitSheet: View {
    @Binding var title: String
    @Binding var icon: String
    let icons: [String]
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Habit")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Habit name", text: $title)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 15) {
                ForEach(icons, id: \.self) { iconName in
                    Button(action: { icon = iconName }) {
                        Image(systemName: iconName)
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(icon == iconName ? Color.blue.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 300)
            
            HStack {
                Button("Cancel", action: onCancel)
                Button("Save", action: onSave)
                    .disabled(title.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}

// MARK: - Journal View

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    
    @State private var showingNewEntry = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Journal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingNewEntry = true }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            List {
                ForEach(entries) { entry in
                    JournalRow(entry: entry)
                }
            }
            .listStyle(.inset)
        }
        .sheet(isPresented: $showingNewEntry) {
            NewEntrySheet(onSave: { content, mood, tags in
                let entry = JournalEntry(date: Date(), content: content, mood: mood, tags: tags)
                modelContext.insert(entry)
                showingNewEntry = false
            }, onCancel: {
                showingNewEntry = false
            })
        }
    }
}

// MARK: - Journal Row

struct JournalRow: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= entry.mood ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(i <= entry.mood ? .yellow : .gray)
                    }
                }
            }
            
            Text(entry.content)
                .font(.body)
                .lineLimit(3)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - New Entry Sheet

struct NewEntrySheet: View {
    let onSave: (String, Int, [String]) -> Void
    let onCancel: () -> Void
    
    @State private var content = ""
    @State private var mood = 3
    @State private var tagInput = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Journal Entry")
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                ForEach(1...5, id: \.self) { i in
                    Button(action: { mood = i }) {
                        Image(systemName: i <= mood ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(i <= mood ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            TextEditor(text: $content)
                .font(.body)
                .frame(minHeight: 150)
            
            TextField("Tags (comma separated)", text: $tagInput)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel", action: onCancel)
                Button("Save") {
                    let tags = tagInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    onSave(content, mood, tags)
                }
                .disabled(content.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Statistics View

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \JournalEntry.date, order: .reverse) private var journalEntries: [JournalEntry]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                HStack(spacing: 20) {
                    StatCard(title: "Total Habits", value: "\(habits.count)", subtitle: "", icon: "list.bullet", color: .blue, progress: nil)
                    StatCard(title: "Today's Progress", value: "\(Int(completionRate() * 100))%", subtitle: "", icon: "checkmark.circle", color: .green, progress: nil)
                }
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    StatCard(title: "Current Streak", value: "\(currentStreak()) days", subtitle: "", icon: "flame.fill", color: .orange, progress: nil)
                    StatCard(title: "Best Streak", value: "\(bestStreak()) days", subtitle: "", icon: "trophy.fill", color: .yellow, progress: nil)
                }
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    StatCard(title: "Journal Entries", value: "\(journalEntries.count)", subtitle: "", icon: "book.fill", color: .purple, progress: nil)
                    StatCard(title: "Avg Mood", value: String(format: "%.1f", avgMood()), subtitle: "", icon: "star.fill", color: .pink, progress: nil)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private func completionRate() -> Double {
        guard !habits.isEmpty else { return 0 }
        let today = startOfDay(Date())
        let completed = habits.filter { habit in
            habit.completions?.contains { completion in
                isSameDay(completion.date, today) && completion.completed
            } ?? false
        }.count
        return Double(completed) / Double(habits.count)
    }
    
    private func currentStreak() -> Int {
        var streak = 0
        var date = startOfDay(Date())
        
        while true {
            let completed = habits.filter { habit in
                habit.completions?.contains { completion in
                    isSameDay(completion.date, date) && completion.completed
                } ?? false
            }.count
            
            if habits.isEmpty { return 0 }
            let rate = Double(completed) / Double(habits.count)
            if rate >= 0.5 {
                streak += 1
                date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            } else {
                break
            }
        }
        return streak
    }
    
    private func bestStreak() -> Int {
        var best = 0
        var current = 0
        
        for dayOffset in (0..<365).reversed() {
            guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: startOfDay(Date())) else { continue }
            let completed = habits.filter { habit in
                habit.completions?.contains { completion in
                    isSameDay(completion.date, date) && completion.completed
                } ?? false
            }.count
            let rate = habits.isEmpty ? 0 : Double(completed) / Double(habits.count)
            if rate >= 0.5 {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }
    
    private func avgMood() -> Double {
        guard !journalEntries.isEmpty else { return 0 }
        let sum = journalEntries.reduce(0) { $0 + $1.mood }
        return Double(sum) / Double(journalEntries.count)
    }
}

// MARK: - Helper Extension

extension DateFormatter {
    func with(_ modify: (DateFormatter) -> Void) -> DateFormatter {
        modify(self)
        return self
    }
}
