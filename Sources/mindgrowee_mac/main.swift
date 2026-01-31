import SwiftUI
import SwiftData



// MARK: - Models

@Model
class Habit {
    @Attribute(.unique) var id: UUID
    var title: String
    var icon: String
    var color: String
    var createdAt: Date
    var categoryId: UUID?
    
    var completions: [DailyCompletion]?
    var project: Project?
    
    init(title: String, icon: String, color: String, categoryId: UUID? = nil, project: Project? = nil) {
        self.id = UUID()
        self.title = title
        self.icon = icon
        self.color = color
        self.categoryId = categoryId
        self.project = project
        self.createdAt = Date()
    }
}

@Model
class DailyCompletion {
    @Attribute(.unique) var id: UUID
    var date: Date
    var completed: Bool
    var habitID: UUID?
    
    init(date: Date, completed: Bool, habit: Habit) {
        self.id = UUID()
        self.date = date
        self.completed = completed
        self.habitID = habit.id
    }
}

@Model
class JournalEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var content: String
    var mood: Int // 1-5
    var tags: [String]
    
    init(date: Date, content: String, mood: Int, tags: [String]) {
        self.id = UUID()
        self.date = date
        self.content = content
        self.mood = mood
        self.tags = tags
    }
}

// MARK: - Helper Functions

func startOfDay(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
}

func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
    Calendar.current.isDate(date1, inSameDayAs: date2)
}

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
        .onReceive(NotificationCenter.default.publisher(for: .quickComplete)) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .newHabit)) { _ in
            selectedTab = 0
            NotificationCenter.default.post(name: .showAddHabit, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .newJournal)) { _ in
            selectedTab = 1
            NotificationCenter.default.post(name: .showNewJournal, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showExport)) { _ in
            showingExport = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            showingSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showKeyboardShortcuts)) { _ in
            showingKeyboardShortcuts = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAbout)) { _ in
            showingAbout = true
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
            // Header
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
                .help("Streak Freezes")
                
                Button(action: { showingAddHabit = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            // Date display
            Text(todayString())
                .font(.headline)
                .foregroundStyle(.secondary)
            
            // Progress
            ProgressView(value: completionRate())
                .padding(.horizontal)
            
            Text("\(completedCount()) of \(habits.count) completed")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
            
            // Habits List with Drag & Drop
            List {
                ForEach(habits) { habit in
                    HabitRow(habit: habit)
                        .draggable(habit.id.uuidString) {
                            HabitDragPreview(habit: habit)
                        }
                        .dropDestination(for: String.self) { items, location in
                            guard let draggedId = items.first,
                                  let uuid = UUID(uuidString: draggedId),
                                  let fromIndex = habits.firstIndex(where: { $0.id == uuid }),
                                  let toIndex = habits.firstIndex(where: { $0.id == habit.id }) else {
                                return false
                            }
                            moveHabit(from: fromIndex, to: toIndex)
                            return true
                        }
                }
                .onDelete(perform: deleteHabit)
            }
            .listStyle(.inset)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddHabit)) { _ in
            showingAddHabit = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .completeAllHabits)) { _ in
            completeAllHabits()
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
    
    private func moveHabit(from source: Int, to destination: Int) {
        var habitIds = habits.map { $0.id }
        habitIds.move(fromOffsets: IndexSet([source]), toOffset: destination > source ? destination + 1 : destination)
        
        // Update sort order based on new positions
        for (index, habit) in habits.enumerated() {
            if let newIndex = habitIds.firstIndex(of: habit.id) {
                habit.createdAt = Date().addingTimeInterval(TimeInterval(newIndex))
            }
        }
    }
    
    private func completeAllHabits() {
        let today = startOfDay(Date())
        var completedCount = 0
        var hasErrors = false
        
        for habit in habits {
            let isCompleted = habit.completions?.contains { completion in
                isSameDay(completion.date, today) && completion.completed
            } ?? false
            
            if !isCompleted {
                let completion = DailyCompletion(date: today, completed: true, habit: habit)
                
                // Safe insert with error handling
                switch modelContext.safeInsert(completion) {
                case .success:
                    completedCount += 1
                case .failure(let error):
                    Logger.shared.error("Failed to complete habit \(habit.title)", error: error)
                    hasErrors = true
                }
            }
        }
        
        if completedCount > 0 {
            SoundManager.shared.playSuccess()
            AccessibilityManager.shared.announce("Completed \(completedCount) habits")
        }
        
        if hasErrors {
            Logger.shared.warning("Some habits could not be completed")
        }
    }
    
    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
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
        // Validate input
        let trimmedTitle = newHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            Logger.shared.warning("Attempted to create habit with empty title")
            return
        }
        
        // Check for duplicates
        let existingHabits = (try? modelContext.fetch(FetchDescriptor<Habit>())) ?? []
        let isDuplicate = existingHabits.contains { 
            $0.title.lowercased() == trimmedTitle.lowercased() 
        }
        
        guard !isDuplicate else {
            Logger.shared.warning("Attempted to create duplicate habit: \(trimmedTitle)")
            // Could show alert here
            return
        }
        
        // Validate icon and color
        let safeIcon = icons.contains(selectedIcon) ? selectedIcon : "star.fill"
        let safeColor = colors.randomElement() ?? "blue"
        
        // Create habit
        let habit = Habit(title: trimmedTitle, icon: safeIcon, color: safeColor)
        
        // Save with error handling
        switch modelContext.safeInsert(habit) {
        case .success:
            Logger.shared.info("Created new habit: \(trimmedTitle)")
            newHabitTitle = ""
            showingAddHabit = false
        case .failure(let error):
            Logger.shared.error("Failed to create habit", error: error)
        }
    }
    
    private func deleteHabit(at offsets: IndexSet) {
        // Validate indices
        guard !habits.isEmpty else {
            Logger.shared.warning("Attempted to delete from empty habits list")
            return
        }
        
        for index in offsets {
            // Bounds check
            guard index >= 0 && index < habits.count else {
                Logger.shared.error("Invalid index for deletion: \(index)")
                continue
            }
            
            let habit = habits[index]
            
            // Safe delete with error handling
            switch modelContext.safeDelete(habit) {
            case .success:
                Logger.shared.info("Deleted habit: \(habit.title)")
            case .failure(let error):
                Logger.shared.error("Failed to delete habit", error: error)
            }
        }
    }
}

// MARK: - Habit Row

struct HabitRow: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    @State private var showingDetail = false
    
    var body: some View {
        HStack {
            Image(systemName: habit.icon)
                .font(.title2)
                .foregroundStyle(colorFor(habit.color))
                .frame(width: 40)
            
            Text(habit.title)
                .font(.title3)
            
            Spacer()
            
            // Edit button
            Button(action: { showingDetail = true }) {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            // Complete button
            Button(action: toggleCompletion) {
                Image(systemName: isCompletedToday() ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompletedToday() ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingDetail) {
            HabitDetailView(habit: habit)
        }
    }
    
    private func isCompletedToday() -> Bool {
        let today = startOfDay(Date())
        return habit.completions?.contains { completion in
            isSameDay(completion.date, today) && completion.completed
        } ?? false
    }
    
    private func toggleCompletion() {
        let today = startOfDay(Date())
        let wasCompleted = isCompletedToday()
        
        do {
            // Check if already completed today
            if let existing = habit.completions?.first(where: { isSameDay($0.date, today) }) {
                existing.completed.toggle()
                try modelContext.save()
            } else {
                // Create new completion
                let completion = DailyCompletion(date: today, completed: true, habit: habit)
                modelContext.insert(completion)
                try modelContext.save()
            }
            
            // Play sound effect
            if wasCompleted {
                SoundManager.shared.playHabitUncheck()
            } else {
                SoundManager.shared.playHabitComplete()
            }
            
            Logger.shared.info("Toggled completion for habit: \(habit.title)")
        } catch {
            Logger.shared.error("Failed to toggle completion", error: error)
            modelContext.rollback()
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
            
            Text("Choose Icon")
                .font(.headline)
            
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
                    .keyboardShortcut(.cancelAction)
                
                Button("Save", action: onSave)
                    .keyboardShortcut(.defaultAction)
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
    
    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return entries
        }
        return entries.filter { entry in
            entry.content.localizedCaseInsensitiveContains(searchText) ||
            entry.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
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
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search entries...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            
            // Entry count
            if !searchText.isEmpty {
                Text("\(filteredEntries.count) results")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            
            List {
                ForEach(filteredEntries) { entry in
                    JournalRow(entry: entry)
                }
                .onDelete(perform: deleteEntry)
            }
            .listStyle(.inset)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNewJournal)) { _ in
            showingNewEntry = true
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
    
    private func deleteEntry(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredEntries[index])
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
                
                // Mood indicator
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
            
            if !entry.tags.isEmpty {
                HStack {
                    ForEach(entry.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
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
            
            // Mood selector
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
            
            // Content
            TextEditor(text: $content)
                .font(.body)
                .frame(minHeight: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            // Tags
            TextField("Tags (comma separated)", text: $tagInput)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    let tags = tagInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    onSave(content, mood, tags)
                }
                .keyboardShortcut(.defaultAction)
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
                
                // Habit Stats
                HStack(spacing: 20) {
                    StatCard(title: "Total Habits", value: "\(habits.count)", icon: "list.bullet")
                    StatCard(title: "Today's Progress", value: "\(Int(completionRate() * 100))%", icon: "checkmark.circle")
                }
                .padding(.horizontal)
                
                // Streak Stats
                HStack(spacing: 20) {
                    StatCard(title: "Current Streak", value: "\(currentStreak()) days", icon: "flame.fill")
                    StatCard(title: "Best Streak", value: "\(bestStreak()) days", icon: "trophy.fill")
                }
                .padding(.horizontal)
                
                // Journal Stats
                HStack(spacing: 20) {
                    StatCard(title: "Journal Entries", value: "\(journalEntries.count)", icon: "book.fill")
                    StatCard(title: "Avg Mood", value: String(format: "%.1f", avgMood()), icon: "star.fill")
                }
                .padding(.horizontal)
                
                // Weekly Chart
                WeeklyChart(habits: habits)
                    .frame(height: 200)
                    .padding()
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
            
            if habits.isEmpty {
                return 0
            }
            
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
        
        // Check last 365 days
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

// MARK: - Weekly Chart

struct WeeklyChart: View {
    let habits: [Habit]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Last 7 Days")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -(6-dayOffset), to: startOfDay(Date()))!
                    let rate = completionRate(for: date)
                    
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(rate >= 0.5 ? Color.green : (rate > 0 ? Color.orange : Color.gray.opacity(0.3)))
                            .frame(width: 30, height: max(4, rate * 100))
                        
                        Text(dayLetter(for: date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func completionRate(for date: Date) -> Double {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter { habit in
            habit.completions?.contains { completion in
                isSameDay(completion.date, date) && completion.completed
            } ?? false
        }.count
        return Double(completed) / Double(habits.count)
    }
    
    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}
