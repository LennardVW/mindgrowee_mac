import SwiftUI
import SwiftData

// MARK: - Project Extension

extension Project {
    var completionPercentage: Double {
        guard let habits = habits, !habits.isEmpty else { return 0 }
        let completed = habits.filter { $0.isCompletedToday }.count
        return Double(completed) / Double(habits.count)
    }
    
    var overallStreak: Int {
        let streaks = habits?.map { $0.currentStreak } ?? []
        return streaks.min() ?? 0
    }
    
    var daysUntilDeadline: Int? {
        guard let deadline = deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
    }
}

// MARK: - Project Extension for Habit

extension Habit {
    var isCompletedToday: Bool {
        let today = startOfDay(Date())
        return completions?.contains { isSameDay($0.date, today) && $0.completed } ?? false
    }
    
    var currentStreak: Int {
        var streak = 0
        var date = startOfDay(Date())
        
        while true {
            let isCompleted = completions?.contains { completion in
                isSameDay(completion.date, date) && completion.completed
            } ?? false
            
            if isCompleted {
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
}

// MARK: - Project Manager

class ProjectManager: ObservableObject {
    static let shared = ProjectManager()
    
    @Published var selectedProject: Project?
    
    private init() {}
    
    func createProject(name: String, description: String, color: String, icon: String, deadline: Date?, context: ModelContext) -> Result<Project, DataError> {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.validationFailed(message: "Project name cannot be empty"))
        }
        
        let project = Project(name: name, description: description, color: color, icon: icon, deadline: deadline)
        return context.safeInsert(project).map { _ in project }
    }
    
    func completeProject(_ project: Project, context: ModelContext) {
        project.isCompleted = true
        project.completedAt = Date()
        
        // Complete all associated habits
        project.habits?.forEach { habit in
            let today = startOfDay(Date())
            if !(habit.completions?.contains { isSameDay($0.date, today) && $0.completed } ?? false) {
                let completion = DailyCompletion(date: today, completed: true, habit: habit)
                context.insert(completion)
            }
        }
        
        try? context.save()
    }
    
    func archiveProject(_ project: Project, context: ModelContext) {
        // Soft delete - just mark as archived
        // In real implementation, would move to archive
        project.isCompleted = true
        try? context.save()
    }
    
    func getProjectProgress(_ project: Project) -> ProjectProgress {
        guard let habits = project.habits, !habits.isEmpty else {
            return ProjectProgress(total: 0, completed: 0, percentage: 0)
        }
        
        let total = habits.count
        let completed = habits.filter { $0.isCompletedToday }.count
        let percentage = Double(completed) / Double(total)
        
        return ProjectProgress(total: total, completed: completed, percentage: percentage)
    }
}

// MARK: - Project Progress

struct ProjectProgress {
    let total: Int
    let completed: Int
    let percentage: Double
    
    var formattedPercentage: String {
        String(format: "%.0f%%", percentage * 100)
    }
}

// MARK: - Project Status

enum ProjectStatus: String, CaseIterable {
    case active = "Active"
    case completed = "Completed"
    case archived = "Archived"
    case overdue = "Overdue"
    
    var color: Color {
        switch self {
        case .active: return .blue
        case .completed: return .green
        case .archived: return .gray
        case .overdue: return .red
        }
    }
}

// MARK: - Project Template

struct ProjectTemplate {
    let name: String
    let description: String
    let icon: String
    let color: String
    let defaultHabits: [String]
    let milestones: [String]
    
    static let templates: [ProjectTemplate] = [
        ProjectTemplate(
            name: "Fitness Challenge",
            description: "30-day fitness transformation",
            icon: "figure.run",
            color: "green",
            defaultHabits: ["Morning Workout", "Track Calories", "Drink Water", "Sleep 8 Hours"],
            milestones: ["Week 1 Complete", "Week 2 Complete", "Halfway Point", "Week 4 Complete"]
        ),
        ProjectTemplate(
            name: "Learning Goal",
            description: "Master a new skill",
            icon: "book.fill",
            color: "purple",
            defaultHabits: ["Study 1 Hour", "Practice", "Review Notes", "Complete Exercise"],
            milestones: ["Basics Complete", "Intermediate", "Advanced", "Mastery"]
        ),
        ProjectTemplate(
            name: "Productivity Boost",
            description: "Improve daily productivity",
            icon: "checkmark.circle.fill",
            color: "blue",
            defaultHabits: ["Plan Day", "Focus Blocks", "No Social Media", "Review Goals"],
            milestones: ["Week 1", "Week 2", "Week 3", "Month Complete"]
        ),
        ProjectTemplate(
            name: "Mindfulness Journey",
            description: "Develop mindfulness practice",
            icon: "sparkles",
            color: "pink",
            defaultHabits: ["Morning Meditation", "Gratitude Journal", "Mindful Eating", "Evening Reflection"],
            milestones: ["Day 7", "Day 14", "Day 21", "Day 30"]
        )
    ]
}
