import SwiftUI
import SwiftData

// MARK: - Menu Bar View

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    
    @State private var showingNewEntry = false
    @State private var showingMainWindow = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                
                Text("MindGrowee")
                    .font(.headline)
                
                Spacer()
                
                Button(action: openMainWindow) {
                    Image(systemName: "arrow.up.forward.app")
                }
                .buttonStyle(.plain)
                .help("Open Main Window")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Quick Stats
            HStack(spacing: 20) {
                VStack {
                    Text("\(completedCount())/\(habits.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("\(currentStreak())")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 10)
            
            Divider()
            
            // Quick Habits List
            if habits.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No habits yet")
                        .foregroundStyle(.secondary)
                    Button("Create in Main App") {
                        openMainWindow()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
            } else {
                List {
                    ForEach(habits) { habit in
                        MenuBarHabitRow(habit: habit)
                    }
                }
                .listStyle(.plain)
            }
            
            Divider()
            
            // Quick Actions
            HStack(spacing: 15) {
                Button(action: { showingNewEntry = true }) {
                    Label("Journal", systemImage: "book.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button(action: quitApp) {
                    Label("Quit", systemImage: "power")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
        }
        .frame(width: 350)
        .sheet(isPresented: $showingNewEntry) {
            QuickJournalSheet(onSave: { content, mood, tags in
                let entry = JournalEntry(date: Date(), content: content, mood: mood, tags: tags)
                modelContext.insert(entry)
                showingNewEntry = false
            }, onCancel: {
                showingNewEntry = false
            })
        }
    }
    
    private func completedCount() -> Int {
        let today = startOfDay(Date())
        return habits.filter { habit in
            habit.completions?.contains { completion in
                isSameDay(completion.date, today) && completion.completed
            } ?? false
        }.count
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
    
    private func openMainWindow() {
        // Close popover
        NSApp.keyWindow?.close()
        
        // Open main window
        if let window = NSApp.windows.first(where: { $0.title == "MindGrowee" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Create new window
            let contentView = ContentView()
                .modelContainer(modelContext.container)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "MindGrowee"
            window.contentView = NSHostingView(rootView: contentView)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Menu Bar Habit Row

struct MenuBarHabitRow: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            Image(systemName: habit.icon)
                .foregroundStyle(colorFor(habit.color))
                .frame(width: 25)
            
            Text(habit.title)
                .lineLimit(1)
            
            Spacer()
            
            Button(action: toggleCompletion) {
                Image(systemName: isCompletedToday() ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompletedToday() ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
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

// MARK: - Quick Journal Sheet

struct QuickJournalSheet: View {
    let onSave: (String, Int, [String]) -> Void
    let onCancel: () -> Void
    
    @State private var content = ""
    @State private var mood = 3
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Quick Journal Entry")
                .font(.headline)
            
            // Mood selector
            HStack {
                ForEach(1...5, id: \.self) { i in
                    Button(action: { mood = i }) {
                        Image(systemName: i <= mood ? "star.fill" : "star")
                            .foregroundStyle(i <= mood ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Content
            TextEditor(text: $content)
                .font(.body)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            HStack {
                Button("Cancel", action: onCancel)
                
                Button("Save") {
                    onSave(content, mood, [])
                }
                .disabled(content.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
