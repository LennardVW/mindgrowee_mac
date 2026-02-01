import SwiftUI
import SwiftData

// MARK: - Streak Freeze Manager

class StreakFreezeManager: ObservableObject {
    @Published var availableFreezes: Int = 0
    @Published var usedFreezes: Int = 0
    
    private let maxFreezes = 3
    private let freezeRegenDays = 7 // Regenerate 1 freeze every 7 days
    
    func calculateAvailableFreezes(freezes: [StreakFreeze]) -> Int {
        let usedCount = freezes.filter { $0.isUsed }.count

        // Simple calculation: max - used
        return max(0, maxFreezes - usedCount)
    }
    
    func canUseFreeze(freezes: [StreakFreeze]) -> Bool {
        calculateAvailableFreezes(freezes: freezes) > 0
    }
    
    func useFreeze(freezes: [StreakFreeze], reason: String = "") -> StreakFreeze? {
        guard canUseFreeze(freezes: freezes) else { return nil }
        
        let freeze = StreakFreeze(date: Date(), reason: reason)
        freeze.isUsed = true
        return freeze
    }
}

// MARK: - Streak Freeze View

struct StreakFreezeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \StreakFreeze.date, order: .reverse) private var freezes: [StreakFreeze]
    
    @State private var showingUseFreeze = false
    @State private var freezeReason = ""
    
    private let manager = StreakFreezeManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Streak Freezes")
                .font(.title)
                .fontWeight(.bold)
            
            // Available freezes
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < availableCount() ? "snowflake" : "snowflake.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(index < availableCount() ? .blue : .gray.opacity(0.3))
                }
            }
            .padding()
            
            Text("\(availableCount()) of 3 available")
                .font(.headline)
            
            Text("Use a freeze to protect your streak when you can't complete your habits. You regenerate 1 freeze every 7 days.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingUseFreeze = true }) {
                Label("Use Freeze Today", systemImage: "snowflake")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canUseFreeze())
            .padding()
            
            // History
            if !freezes.isEmpty {
                List {
                    Section("History") {
                        ForEach(freezes) { freeze in
                            HStack {
                                Image(systemName: "snowflake")
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(freeze.date, style: .date)
                                    if !freeze.reason.isEmpty {
                                        Text(freeze.reason)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if freeze.isUsed {
                                    Text("Used")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            .padding()
        }
        .frame(width: 400, height: 500)
        .alert("Use Streak Freeze?", isPresented: $showingUseFreeze) {
            Button("Cancel", role: .cancel) { }
            Button("Use Freeze", role: .destructive) {
                useFreeze()
            }
        } message: {
            Text("This will protect your streak for today. You have \(availableCount()) freezes remaining.")
        }
    }
    
    private func availableCount() -> Int {
        manager.calculateAvailableFreezes(freezes: freezes)
    }
    
    private func canUseFreeze() -> Bool {
        manager.canUseFreeze(freezes: freezes)
    }
    
    private func useFreeze() {
        if let freeze = manager.useFreeze(freezes: freezes, reason: freezeReason) {
            modelContext.insert(freeze)
        }
    }
}

// MARK: - Streak Protection Extension

extension Habit {
    func isProtectedByFreeze(freezes: [StreakFreeze], date: Date) -> Bool {
        let dayStart = startOfDay(date)
        return freezes.contains { freeze in
            isSameDay(freeze.date, dayStart) && freeze.isUsed
        }
    }
}
