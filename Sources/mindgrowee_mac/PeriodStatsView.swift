import SwiftUI
import SwiftData

// MARK: - Period Stats View

struct PeriodStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Detailed Statistics")
                .font(.title)
                .fontWeight(.bold)
            
            // Period selector
            Picker("Period", selection: $selectedPeriod) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Summary cards
            HStack(spacing: 16) {
                StatCard(
                    title: "Completion Rate",
                    value: "\(Int(completionRateForPeriod() * 100))%",
                    icon: "chart.pie.fill"
                )
                
                StatCard(
                    title: "Days Tracked",
                    value: "\(daysTracked())",
                    icon: "calendar"
                )
            }
            .padding(.horizontal)
            
            // Habit performance list
            List {
                Section("Habit Performance") {
                    ForEach(habits) { habit in
                        HabitPerformanceRow(habit: habit, period: selectedPeriod)
                    }
                }
            }
            .listStyle(.inset)
        }
        .padding(.vertical)
    }
    
    private func dateRange() -> (start: Date, end: Date) {
        let end = Date()
        let calendar = Calendar.current
        let start: Date
        
        switch selectedPeriod {
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: end)!
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: end)!
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: end)!
        case .allTime:
            start = habits.map { $0.createdAt }.min() ?? end
        }
        
        return (start, end)
    }
    
    private func daysTracked() -> Int {
        let range = dateRange()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: range.start, to: range.end)
        return max(1, components.day! + 1)
    }
    
    private func completionRateForPeriod() -> Double {
        let range = dateRange()
        let calendar = Calendar.current
        var totalPossible = 0
        var totalCompleted = 0
        
        var date = range.start
        while date <= range.end {
            for habit in habits {
                totalPossible += 1
                if habit.completions?.contains(where: { isSameDay($0.date, date) && $0.completed }) ?? false {
                    totalCompleted += 1
                }
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        guard totalPossible > 0 else { return 0 }
        return Double(totalCompleted) / Double(totalPossible)
    }
}

// MARK: - Habit Performance Row

struct HabitPerformanceRow: View {
    let habit: Habit
    let period: PeriodStatsView.TimePeriod
    
    var body: some View {
        HStack {
            Image(systemName: habit.icon)
                .foregroundStyle(colorFor(habit.color))
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(habit.title)
                    .fontWeight(.medium)
                
                Text("\(completionCount()) of \(totalDays()) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorFor(habit.color))
                        .frame(width: 80 * completionRate(), height: 8)
                }
            }
            .frame(width: 80, height: 8)
            
            Text("\(Int(completionRate() * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
    
    private func dateRange() -> (start: Date, end: Date) {
        let end = Date()
        let calendar = Calendar.current
        let start: Date
        
        switch period {
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: end)!
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: end)!
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: end)!
        case .allTime:
            start = habit.createdAt
        }
        
        return (start, end)
    }
    
    private func totalDays() -> Int {
        let range = dateRange()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: range.start, to: range.end)
        return max(1, components.day! + 1)
    }
    
    private func completionCount() -> Int {
        let range = dateRange()
        var count = 0
        var date = range.start
        let calendar = Calendar.current
        
        while date <= range.end {
            if habit.completions?.contains(where: { isSameDay($0.date, date) && $0.completed }) ?? false {
                count += 1
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        return count
    }
    
    private func completionRate() -> Double {
        Double(completionCount()) / Double(totalDays())
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
