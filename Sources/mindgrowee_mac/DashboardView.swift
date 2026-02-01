import SwiftUI
import SwiftData

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \JournalEntry.date, order: .reverse) private var journalEntries: [JournalEntry]
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    
    @State private var selectedTimeRange: TimeRange = .today
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case month = "Month"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with time range selector
                HStack {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                .padding(.horizontal)
                
                // Quick Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(
                        title: "Habits",
                        value: "\(todayCompletedHabits)/\(habits.count)",
                        subtitle: "completed",
                        icon: "checkmark.circle.fill",
                        color: .blue,
                        progress: habits.isEmpty ? 0 : Double(todayCompletedHabits) / Double(habits.count)
                    )
                    
                    StatCard(
                        title: "Current Streak",
                        value: "\(currentStreak)",
                        subtitle: currentStreak == 1 ? "day" : "days",
                        icon: "flame.fill",
                        color: .orange,
                        progress: min(Double(currentStreak) / 30.0, 1.0)
                    )
                    
                    StatCard(
                        title: "Journal Entries",
                        value: "\(journalEntries.count)",
                        subtitle: "total",
                        icon: "book.fill",
                        color: .purple,
                        progress: nil
                    )
                    
                    StatCard(
                        title: "Active Projects",
                        value: "\(activeProjects.count)",
                        subtitle: "in progress",
                        icon: "folder.fill",
                        color: .green,
                        progress: nil
                    )
                }
                .padding(.horizontal)
                
                // Today's Habits Section
                if !habits.isEmpty {
                    DashboardSection(title: "Today's Habits", icon: "checkmark.circle") {
                        VStack(spacing: 8) {
                            ForEach(habits.prefix(5)) { habit in
                                DashboardHabitRow(habit: habit)
                            }
                            
                            if habits.count > 5 {
                                Text("+ \(habits.count - 5) more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 8)
                            }
                        }
                    }
                }
                
                // Weekly Progress Chart
                if !habits.isEmpty {
                    DashboardSection(title: "Weekly Progress", icon: "chart.bar") {
                        WeeklyProgressChart(habits: habits)
                            .frame(height: 150)
                    }
                }
                
                // Recent Journal Entries
                if !journalEntries.isEmpty {
                    DashboardSection(title: "Recent Journal", icon: "book") {
                        VStack(spacing: 12) {
                            ForEach(journalEntries.prefix(3)) { entry in
                                DashboardJournalRow(entry: entry)
                            }
                        }
                    }
                }
                
                // Active Projects
                if !activeProjects.isEmpty {
                    DashboardSection(title: "Active Projects", icon: "folder") {
                        VStack(spacing: 12) {
                            ForEach(activeProjects.prefix(3)) { project in
                                DashboardProjectRow(project: project)
                            }
                        }
                    }
                }
                
                // Mood Trends
                if journalEntries.count >= 7 {
                    DashboardSection(title: "Mood Trends", icon: "face.smiling") {
                        MoodTrendChart(entries: Array(journalEntries.prefix(30)))
                            .frame(height: 100)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Computed Properties
    
    private var todayCompletedHabits: Int {
        let today = startOfDay(Date())
        return habits.filter { habit in
            habit.completions?.contains { completion in
                isSameDay(completion.date, today) && completion.completed
            } ?? false
        }.count
    }
    
    private var currentStreak: Int {
        var streak = 0
        var date = startOfDay(Date())
        
        while true {
            let completedCount = habits.filter { habit in
                habit.completions?.contains { completion in
                    isSameDay(completion.date, date) && completion.completed
                } ?? false
            }.count
            
            let completionRate = habits.isEmpty ? 0 : Double(completedCount) / Double(habits.count)
            
            if completionRate >= 0.5 {
                streak += 1
                date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            } else if isSameDay(date, startOfDay(Date())) {
                date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var activeProjects: [Project] {
        projects.filter { !$0.isCompleted }
    }
}

// MARK: - Dashboard Section

struct DashboardSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.headline)
            }
            .padding(.horizontal)
            
            content
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                .padding(.horizontal)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double?
    
    init(title: String, value: String, subtitle: String = "", icon: String, color: Color = .blue, progress: Double? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
                
                if let progress = progress {
                    CircularProgressView(progress: progress, color: color)
                        .frame(width: 30, height: 30)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Dashboard Habit Row

struct DashboardHabitRow: View {
    let habit: Habit
    
    var body: some View {
        HStack {
            Image(systemName: habit.icon)
                .foregroundStyle(colorFor(habit.color))
                .frame(width: 30)
            
            Text(habit.title)
                .font(.subheadline)
            
            Spacer()
            
            if isCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .padding(.vertical, 4)
    }
    
    private var isCompletedToday: Bool {
        let today = startOfDay(Date())
        return habit.completions?.contains { completion in
            isSameDay(completion.date, today) && completion.completed
        } ?? false
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

// MARK: - Dashboard Journal Row

struct DashboardJournalRow: View {
    let entry: JournalEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Mood indicator
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= entry.mood ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(i <= entry.mood ? .yellow : .gray.opacity(0.3))
                }
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.content)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Dashboard Project Row

struct DashboardProjectRow: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: project.icon)
                .foregroundStyle(colorFor(project.color))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorFor(project.color))
                            .frame(width: geometry.size.width * project.completionPercentage, height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            Spacer()
            
            Text("\(Int(project.completionPercentage * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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

// MARK: - Weekly Progress Chart

struct WeeklyProgressChart: View {
    let habits: [Habit]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = Calendar.current.date(byAdding: .day, value: -(6-dayOffset), to: startOfDay(Date()))!
                let rate = completionRate(for: date)
                
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(rate >= 0.5 ? Color.green : (rate > 0 ? Color.orange : Color.gray.opacity(0.3)))
                        .frame(width: 30, height: max(4, rate * 80))
                    
                    Text(dayLetter(for: date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Mood Trend Chart

struct MoodTrendChart: View {
    let entries: [JournalEntry]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(entries.suffix(14), id: \.id) { entry in
                    VStack {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(moodColor(entry.mood))
                            .frame(width: (geometry.size.width - 52) / 14, height: CGFloat(entry.mood) * 12)
                        
                        Text(dayString(for: entry.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
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
    
    private func dayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .modelContainer(previewContainer)
    }
}
#endif
