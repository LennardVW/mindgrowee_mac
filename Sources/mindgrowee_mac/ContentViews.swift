import SwiftUI
import SwiftData
import Charts

// MARK: - Content View

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingExport = false
    @State private var showingSettings = false
    @State private var showingKeyboardShortcuts = false
    @State private var showingAbout = false
    @State private var showingOnboarding = false
    @AppStorage("accentColor") private var accentColor = "blue"

    private var resolvedAccent: Color {
        switch accentColor {
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
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
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
            EncryptedExportImportView()
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
        .onReceive(NotificationCenter.default.publisher(for: .showExport)) { _ in
            showingExport = true
        }
        .tint(resolvedAccent)
        .accentColor(resolvedAccent)
    }
}

// MARK: - Habits View

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    
    @State private var showingAddHabit = false
    @State private var showingStreakFreeze = false
    @State private var editingHabit: Habit?
    @State private var selectedDate = Date()
    @State private var newHabitTitle = ""
    @State private var selectedIcon = "star.fill"
    
    private let icons = ["star.fill", "heart.fill", "bolt.fill", "flame.fill", "drop.fill", "moon.fill", "sun.max.fill", "figure.walk", "book.fill", "pencil", "guitars.fill", "tv.fill", "gamecontroller.fill", "cart.fill", "creditcard.fill"]
    private let colors = ["red", "orange", "yellow", "green", "blue", "purple", "pink"]
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Habits")
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

            // Date navigation
            HStack(spacing: 12) {
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)

                Button(action: {
                    let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                    if next <= Date() { selectedDate = next }
                }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .disabled(isToday)

                if !isToday {
                    Button("Today") {
                        selectedDate = Date()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal)

            ProgressView(value: completionRate())
                .padding(.horizontal)

            Text("\(completedCount()) of \(habits.count) completed")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)

            List {
                ForEach(habits) { habit in
                    HabitRow(habit: habit, date: selectedDate)
                        .contextMenu {
                            Button("Edit") {
                                editingHabit = habit
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                modelContext.delete(habit)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingHabit = habit
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
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
        .sheet(item: $editingHabit) { habit in
            EditHabitSheet(habit: habit, icons: icons, colors: colors, onSave: {
                editingHabit = nil
            }, onCancel: {
                editingHabit = nil
            })
        }
    }
    
    private func completionRate() -> Double {
        guard !habits.isEmpty else { return 0 }
        return Double(completedCount()) / Double(habits.count)
    }

    private func completedCount() -> Int {
        let day = startOfDay(selectedDate)
        return habits.filter { habit in
            habit.completions?.contains { completion in
                isSameDay(completion.date, day) && completion.completed
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
    var date: Date = Date()
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
                Image(systemName: isCompleted() ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted() ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }

    private func isCompleted() -> Bool {
        let day = startOfDay(date)
        return habit.completions?.contains { completion in
            isSameDay(completion.date, day) && completion.completed
        } ?? false
    }

    private func toggleCompletion() {
        let day = startOfDay(date)
        if let existing = habit.completions?.first(where: { isSameDay($0.date, day) }) {
            existing.completed.toggle()
        } else {
            let completion = DailyCompletion(date: day, completed: true, habit: habit)
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

// MARK: - Edit Habit Sheet

struct EditHabitSheet: View {
    let habit: Habit
    let icons: [String]
    let colors: [String]
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var selectedIcon: String
    @State private var selectedColor: String

    init(habit: Habit, icons: [String], colors: [String], onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.habit = habit
        self.icons = icons
        self.colors = colors
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: habit.title)
        _selectedIcon = State(initialValue: habit.icon)
        _selectedColor = State(initialValue: habit.color)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Habit")
                .font(.title)
                .fontWeight(.bold)

            TextField("Habit name", text: $title)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 15) {
                ForEach(icons, id: \.self) { iconName in
                    Button(action: { selectedIcon = iconName }) {
                        Image(systemName: iconName)
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(selectedIcon == iconName ? Color.blue.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 300)

            HStack(spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Button(action: { selectedColor = color }) {
                        Circle()
                            .fill(colorFor(color))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Button("Cancel", action: onCancel)
                Button("Save") {
                    habit.title = title
                    habit.icon = selectedIcon
                    habit.color = selectedColor
                    onSave()
                }
                .disabled(title.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 500)
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

// MARK: - Journal View

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var showingNewEntry = false
    @State private var editingEntry: JournalEntry?
    @State private var filterDate: Date?
    @State private var showDateFilter = false

    private var filteredEntries: [JournalEntry] {
        guard let filterDate else { return entries }
        return entries.filter { isSameDay($0.date, filterDate) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Journal")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { showDateFilter.toggle() }) {
                    Image(systemName: filterDate != nil ? "calendar.badge.checkmark" : "calendar")
                        .font(.title3)
                        .foregroundStyle(filterDate != nil ? .blue : .primary)
                }
                .buttonStyle(.plain)

                Button(action: { showingNewEntry = true }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            if showDateFilter {
                HStack(spacing: 12) {
                    DatePicker("Filter by date", selection: Binding(
                        get: { filterDate ?? Date() },
                        set: { filterDate = $0 }
                    ), in: ...Date(), displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)

                    if filterDate != nil {
                        Button("Clear") {
                            filterDate = nil
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Text("\(filteredEntries.count) entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            List {
                ForEach(filteredEntries) { entry in
                    JournalRow(entry: entry)
                        .contextMenu {
                            Button("Edit") {
                                editingEntry = entry
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                modelContext.delete(entry)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingEntry = entry
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
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
        .sheet(item: $editingEntry) { entry in
            EditEntrySheet(entry: entry, onSave: {
                editingEntry = nil
            }, onCancel: {
                editingEntry = nil
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

// MARK: - Edit Entry Sheet

struct EditEntrySheet: View {
    let entry: JournalEntry
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var content: String
    @State private var mood: Int
    @State private var tagInput: String

    init(entry: JournalEntry, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.entry = entry
        self.onSave = onSave
        self.onCancel = onCancel
        _content = State(initialValue: entry.content)
        _mood = State(initialValue: entry.mood)
        _tagInput = State(initialValue: entry.tags.joined(separator: ", "))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Journal Entry")
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
                    entry.content = content
                    entry.mood = mood
                    entry.tags = tagInput.split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    onSave()
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
            VStack(spacing: 24) {
                Text("Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                // Summary cards row
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(title: "Current Streak", value: "\(currentStreak())", subtitle: "days", icon: "flame.fill", color: .orange, progress: nil)
                    StatCard(title: "Best Streak", value: "\(bestStreak())", subtitle: "days", icon: "trophy.fill", color: .yellow, progress: nil)
                    StatCard(title: "Avg Mood", value: String(format: "%.1f", avgMood()), subtitle: "of 5", icon: "star.fill", color: .pink, progress: nil)
                }
                .padding(.horizontal)

                // 30-day completion rate chart
                if !habits.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Daily Completion Rate (30 days)", systemImage: "chart.xyaxis.line")
                            .font(.headline)

                        Chart(last30DaysData, id: \.date) { item in
                            AreaMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Rate", item.rate)
                            )
                            .foregroundStyle(.green.opacity(0.15))

                            LineMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Rate", item.rate)
                            )
                            .foregroundStyle(.green)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Rate", item.rate)
                            )
                            .foregroundStyle(.green)
                            .symbolSize(16)
                        }
                        .chartYAxis {
                            AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text("\(Int(v * 100))%")
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: 0...1)
                        .frame(height: 200)
                    }
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Per-habit completion bar chart
                if !habits.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Habit Completion Rate (30 days)", systemImage: "chart.bar.fill")
                            .font(.headline)

                        Chart(habitCompletionData, id: \.name) { item in
                            BarMark(
                                x: .value("Rate", item.rate),
                                y: .value("Habit", item.name)
                            )
                            .foregroundStyle(item.color.gradient)
                            .cornerRadius(4)
                            .annotation(position: .trailing) {
                                Text("\(Int(item.rate * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartXScale(domain: 0...1)
                        .chartXAxis {
                            AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text("\(Int(v * 100))%")
                                    }
                                }
                            }
                        }
                        .frame(height: CGFloat(habits.count * 44 + 20))
                    }
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Mood trend chart
                if journalEntries.count >= 2 {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Mood Trend", systemImage: "face.smiling")
                            .font(.headline)

                        Chart(moodData, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Mood", item.mood)
                            )
                            .foregroundStyle(.purple)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Mood", item.mood)
                            )
                            .foregroundStyle(moodColor(item.mood))
                            .symbolSize(30)
                        }
                        .chartYScale(domain: 1...5)
                        .chartYAxis {
                            AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let v = value.as(Int.self) {
                                        Text(moodLabel(v))
                                    }
                                }
                            }
                        }
                        .frame(height: 180)
                    }
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Habit heatmap (last 7 weeks)
                if !habits.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Activity Heatmap (7 weeks)", systemImage: "square.grid.3x3.fill")
                            .font(.headline)

                        HeatmapView(habits: habits)
                    }
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Data Helpers

    private var last30DaysData: [(date: Date, rate: Double)] {
        (0..<30).compactMap { offset in
            guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: startOfDay(Date())) else { return nil }
            let completed = habits.filter { habit in
                habit.completions?.contains { isSameDay($0.date, date) && $0.completed } ?? false
            }.count
            let rate = habits.isEmpty ? 0 : Double(completed) / Double(habits.count)
            return (date: date, rate: rate)
        }.reversed()
    }

    private var habitCompletionData: [(name: String, rate: Double, color: Color)] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return habits.map { habit in
            let total = 30.0
            let completed = Double(habit.completions?.filter { $0.completed && $0.date >= thirtyDaysAgo }.count ?? 0)
            return (name: habit.title, rate: min(completed / total, 1.0), color: colorFor(habit.color))
        }
    }

    private var moodData: [(date: Date, mood: Int)] {
        Array(journalEntries.prefix(30)).reversed().map { (date: $0.date, mood: $0.mood) }
    }

    private func moodColor(_ mood: Int) -> Color {
        switch mood {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        default: return .gray
        }
    }

    private func moodLabel(_ mood: Int) -> String {
        switch mood {
        case 1: return "Bad"
        case 2: return "Low"
        case 3: return "OK"
        case 4: return "Good"
        case 5: return "Great"
        default: return ""
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

    private func currentStreak() -> Int {
        var streak = 0
        var date = startOfDay(Date())
        while true {
            let completed = habits.filter { habit in
                habit.completions?.contains { isSameDay($0.date, date) && $0.completed } ?? false
            }.count
            if habits.isEmpty { return 0 }
            if Double(completed) / Double(habits.count) >= 0.5 {
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
                habit.completions?.contains { isSameDay($0.date, date) && $0.completed } ?? false
            }.count
            let rate = habits.isEmpty ? 0 : Double(completed) / Double(habits.count)
            if rate >= 0.5 { current += 1; best = max(best, current) } else { current = 0 }
        }
        return best
    }

    private func avgMood() -> Double {
        guard !journalEntries.isEmpty else { return 0 }
        return Double(journalEntries.reduce(0) { $0 + $1.mood }) / Double(journalEntries.count)
    }
}

// MARK: - Heatmap View

struct HeatmapView: View {
    let habits: [Habit]
    private let weeks = 7
    private let days = 7

    var body: some View {
        HStack(spacing: 3) {
            // Day labels
            VStack(spacing: 3) {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 14, height: 14)
                }
            }

            ForEach(0..<weeks, id: \.self) { week in
                VStack(spacing: 3) {
                    ForEach(0..<days, id: \.self) { day in
                        let offset = -((weeks - 1 - week) * 7 + (days - 1 - day))
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: startOfDay(Date()))!
                        let rate = completionRate(for: date)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatmapColor(rate))
                            .frame(width: 14, height: 14)
                            .help("\(dateString(date)): \(Int(rate * 100))%")
                    }
                }
            }
        }
    }

    private func completionRate(for date: Date) -> Double {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter { habit in
            habit.completions?.contains { isSameDay($0.date, date) && $0.completed } ?? false
        }.count
        return Double(completed) / Double(habits.count)
    }

    private func heatmapColor(_ rate: Double) -> Color {
        if rate == 0 { return Color.gray.opacity(0.15) }
        if rate < 0.25 { return Color.green.opacity(0.25) }
        if rate < 0.5 { return Color.green.opacity(0.45) }
        if rate < 0.75 { return Color.green.opacity(0.65) }
        return Color.green.opacity(0.9)
    }

    private func dateString(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Helper Extension

extension DateFormatter {
    func with(_ modify: (DateFormatter) -> Void) -> DateFormatter {
        modify(self)
        return self
    }
}
