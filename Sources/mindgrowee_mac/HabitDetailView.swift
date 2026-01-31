import SwiftUI
import SwiftData

// MARK: - Habit Detail View

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let habit: Habit
    
    @State private var title: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var reminderTime: Date
    @State private var reminderEnabled: Bool
    
    private let icons = ["star.fill", "heart.fill", "bolt.fill", "flame.fill", "drop.fill", "moon.fill", "sun.max.fill", "figure.walk", "book.fill", "pencil", "guitars.fill", "tv.fill", "gamecontroller.fill", "cart.fill", "creditcard.fill"]
    
    private let colors = [
        ("red", Color.red),
        ("orange", Color.orange),
        ("yellow", Color.yellow),
        ("green", Color.green),
        ("blue", Color.blue),
        ("purple", Color.purple),
        ("pink", Color.pink)
    ]
    
    init(habit: Habit) {
        self.habit = habit
        _title = State(initialValue: habit.title)
        _selectedIcon = State(initialValue: habit.icon)
        _selectedColor = State(initialValue: habit.color)
        _reminderTime = State(initialValue: Date())
        _reminderEnabled = State(initialValue: false)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Habit")
                .font(.title)
                .fontWeight(.bold)
            
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    
                    // Icon picker
                    VStack(alignment: .leading) {
                        Text("Icon")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 10) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Color picker
                    VStack(alignment: .leading) {
                        Text("Color")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.0) { colorName, color in
                                Button(action: { selectedColor = colorName }) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == colorName ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == colorName ? Color.gray : Color.clear, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Reminder") {
                    Toggle("Enable Daily Reminder", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("Statistics") {
                    StatRow(label: "Total Completions", value: "\(totalCompletions())")
                    StatRow(label: "Current Streak", value: "\(currentStreak()) days")
                    StatRow(label: "Best Streak", value: "\(bestStreak()) days")
                    StatRow(label: "Completion Rate", value: "\(Int(completionRate() * 100))%")
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    saveHabit()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 450, height: 550)
        .onAppear {
            NotificationManager.shared.requestAuthorization()
        }
    }
    
    private func saveHabit() {
        habit.title = title
        habit.icon = selectedIcon
        habit.color = selectedColor
        
        // Handle reminder
        if reminderEnabled {
            NotificationManager.shared.scheduleHabitReminder(
                habitId: habit.id,
                title: title,
                time: reminderTime
            )
        } else {
            NotificationManager.shared.cancelHabitReminder(habitId: habit.id)
        }
        
        dismiss()
    }
    
    private func totalCompletions() -> Int {
        habit.completions?.filter { $0.completed }.count ?? 0
    }
    
    private func currentStreak() -> Int {
        var streak = 0
        var date = startOfDay(Date())
        
        while true {
            let isCompleted = habit.completions?.contains { completion in
                isSameDay(completion.date, date) && completion.completed
            } ?? false
            
            if isCompleted {
                streak += 1
                date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
            } else if isSameDay(date, startOfDay(Date())) {
                // Today doesn't break streak yet
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
            
            let isCompleted = habit.completions?.contains { completion in
                isSameDay(completion.date, date) && completion.completed
            } ?? false
            
            if isCompleted {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        
        return best
    }
    
    private func completionRate() -> Double {
        let totalDays = max(1, Calendar.current.dateComponents([.day], from: habit.createdAt, to: Date()).day ?? 1)
        let completed = totalCompletions()
        return Double(completed) / Double(totalDays)
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }
}
