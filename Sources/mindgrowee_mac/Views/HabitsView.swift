import SwiftUI
import SwiftData

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

