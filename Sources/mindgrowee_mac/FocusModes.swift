import SwiftUI
import SwiftData

// MARK: - Focus Mode Manager

class FocusModeManager: ObservableObject {
    static let shared = FocusModeManager()
    
    @Published var activeFocusMode: FocusMode?
    
    private init() {}
    
    func activateFocusMode(_ mode: FocusMode, allHabits: [Habit]) {
        // Deactivate all other modes
        allHabits.forEach { $0.isActive = false }
        
        // Activate this mode
        mode.isActive = true
        activeFocusMode = mode
        
        // Post notification
        NotificationCenter.default.post(name: .focusModeChanged, object: mode)
    }
    
    func deactivateFocusMode(allHabits: [Habit]) {
        allHabits.forEach { $0.isActive = false }
        activeFocusMode = nil
        
        NotificationCenter.default.post(name: .focusModeChanged, object: nil)
    }
    
    func getHabitsForFocusMode(_ mode: FocusMode, allHabits: [Habit]) -> [Habit] {
        return allHabits.filter { mode.habitIds.contains($0.id) }
    }
}

// MARK: - Habit Extension for Focus

extension Habit {
    var isActive: Bool {
        get {
            // This would be stored in a transient property
            false
        }
        set {
            // Store in a way that doesn't affect SwiftData
        }
    }
}

// MARK: - Focus Mode Selection View

struct FocusModeSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \FocusMode.createdAt) private var focusModes: [FocusMode]
    @Query(sort: \Habit.createdAt) private var allHabits: [Habit]
    
    @State private var showingNewFocusMode = false
    @State private var newFocusModeName = ""
    @State private var selectedHabits: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("All Habits") {
                        FocusModeManager.shared.deactivateFocusMode(allHabits: allHabits)
                        dismiss()
                    }
                    .foregroundStyle(FocusModeManager.shared.activeFocusMode == nil ? .blue : .primary)
                }
                
                Section("Focus Modes") {
                    ForEach(focusModes) { mode in
                        FocusModeRow(mode: mode, isActive: FocusModeManager.shared.activeFocusMode?.id == mode.id) {
                            FocusModeManager.shared.activateFocusMode(mode, allHabits: allHabits)
                            dismiss()
                        }
                    }
                    .onDelete(perform: deleteFocusMode)
                }
                
                Section {
                    Button("Create New Focus Mode...") {
                        showingNewFocusMode = true
                    }
                }
            }
            .navigationTitle("Focus Modes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewFocusMode) {
                NewFocusModeSheet(
                    name: $newFocusModeName,
                    habits: allHabits,
                    selectedHabits: $selectedHabits,
                    onSave: createFocusMode,
                    onCancel: { showingNewFocusMode = false }
                )
            }
        }
        .frame(width: 400, height: 500)
    }
    
    private func createFocusMode() {
        guard !newFocusModeName.isEmpty else { return }
        
        let mode = FocusMode(
            name: newFocusModeName,
            icon: "target",
            color: "blue",
            habitIds: Array(selectedHabits)
        )
        
        modelContext.insert(mode)
        newFocusModeName = ""
        selectedHabits.removeAll()
        showingNewFocusMode = false
    }
    
    private func deleteFocusMode(at offsets: IndexSet) {
        for index in offsets {
            let mode = focusModes[index]
            if mode.isActive {
                FocusModeManager.shared.deactivateFocusMode(allHabits: allHabits)
            }
            modelContext.delete(mode)
        }
    }
}

// MARK: - Focus Mode Row

struct FocusModeRow: View {
    let mode: FocusMode
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: mode.icon)
                    .foregroundStyle(colorFor(mode.color))
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text(mode.name)
                    
                    Text("\(mode.habitIds.count) habits")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .foregroundStyle(.primary)
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

// MARK: - New Focus Mode Sheet

struct NewFocusModeSheet: View {
    @Binding var name: String
    let habits: [Habit]
    @Binding var selectedHabits: Set<UUID>
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("New Focus Mode")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Mode name (e.g., Morning Routine)", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Text("Select habits for this mode:")
                .font(.headline)
            
            List(habits) { habit in
                HStack {
                    Image(systemName: habit.icon)
                        .foregroundStyle(colorFor(habit.color))
                    
                    Text(habit.title)
                    
                    Spacer()
                    
                    if selectedHabits.contains(habit.id) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedHabits.contains(habit.id) {
                        selectedHabits.remove(habit.id)
                    } else {
                        selectedHabits.insert(habit.id)
                    }
                }
            }
            .listStyle(.inset)
            
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || selectedHabits.isEmpty)
            }
            .padding()
        }
        .frame(width: 350, height: 500)
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

// MARK: - Focus Mode Indicator

struct FocusModeIndicator: View {
    let mode: FocusMode?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                if let mode = mode {
                    Image(systemName: mode.icon)
                        .foregroundStyle(colorFor(mode.color))
                    Text(mode.name)
                        .font(.subheadline)
                } else {
                    Image(systemName: "rectangle.stack")
                        .foregroundStyle(.secondary)
                    Text("All Habits")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

// MARK: - Notification Extension

extension Notification.Name {
    static let focusModeChanged = Notification.Name("focusModeChanged")
}
