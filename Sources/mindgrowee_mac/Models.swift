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

@Model
class StreakFreeze {
    @Attribute(.unique) var id: UUID
    var date: Date
    var isUsed: Bool
    var usedForHabitId: UUID?
    
    init(date: Date) {
        self.id = UUID()
        self.date = date
        self.isUsed = false
        self.usedForHabitId = nil
    }
}

@Model
class HabitCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var color: String
    var sortOrder: Int
    var createdAt: Date
    var habits: [Habit]?
    
    init(name: String, icon: String, color: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}

@Model
class FocusMode {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String
    var habitIds: [UUID]
    var isActive: Bool
    var createdAt: Date
    
    init(name: String, color: String, habitIds: [UUID] = []) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.habitIds = habitIds
        self.isActive = false
        self.createdAt = Date()
    }
}

@Model
class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var projectDescription: String
    var color: String
    var icon: String
    var createdAt: Date
    var deadline: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var habits: [Habit]?
    var milestones: [Milestone]?
    
    init(name: String, description: String = "", color: String = "blue", icon: String = "folder", deadline: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.projectDescription = description
        self.color = color
        self.icon = icon
        self.createdAt = Date()
        self.deadline = deadline
        self.isCompleted = false
        self.completedAt = nil
    }
}

@Model
class Milestone {
    @Attribute(.unique) var id: UUID
    var title: String
    var milestoneDescription: String
    var targetDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var order: Int
    var project: Project?
    
    init(title: String, description: String = "", targetDate: Date? = nil, order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.milestoneDescription = description
        self.targetDate = targetDate
        self.isCompleted = false
        self.completedAt = nil
        self.order = order
    }
}

// MARK: - Helper Functions

func startOfDay(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
}

func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
    Calendar.current.isDate(date1, inSameDayAs: date2)
}
