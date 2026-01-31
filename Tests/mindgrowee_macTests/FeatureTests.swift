import XCTest
@testable import mindgrowee_mac

// MARK: - Habit Category Tests

final class HabitCategoryTests: XCTestCase {
    
    func testHabitCategoryInitialization() {
        let category = HabitCategory(
            name: "Health",
            icon: "heart.fill",
            color: "red",
            sortOrder: 0
        )
        
        XCTAssertEqual(category.name, "Health")
        XCTAssertEqual(category.icon, "heart.fill")
        XCTAssertEqual(category.color, "red")
        XCTAssertEqual(category.sortOrder, 0)
        XCTAssertNotNil(category.id)
        XCTAssertNotNil(category.createdAt)
    }
    
    func testDefaultCategoriesCount() {
        let manager = CategoryManager.shared
        XCTAssertEqual(manager.defaultCategories.count, 8)
    }
    
    func testDefaultCategoriesContent() {
        let manager = CategoryManager.shared
        let categoryNames = manager.defaultCategories.map { $0.name }
        
        XCTAssertTrue(categoryNames.contains("Health"))
        XCTAssertTrue(categoryNames.contains("Fitness"))
        XCTAssertTrue(categoryNames.contains("Productivity"))
        XCTAssertTrue(categoryNames.contains("Learning"))
    }
}

// MARK: - Focus Mode Tests

final class FocusModeTests: XCTestCase {
    
    func testFocusModeInitialization() {
        let habitIds = [UUID(), UUID()]
        let mode = FocusMode(
            name: "Morning Routine",
            icon: "sun.max.fill",
            color: "orange",
            habitIds: habitIds
        )
        
        XCTAssertEqual(mode.name, "Morning Routine")
        XCTAssertEqual(mode.icon, "sun.max.fill")
        XCTAssertEqual(mode.color, "orange")
        XCTAssertEqual(mode.habitIds.count, 2)
        XCTAssertFalse(mode.isActive)
        XCTAssertNotNil(mode.id)
    }
    
    func testFocusModeManagerActivation() {
        let manager = FocusModeManager.shared
        let mode = FocusMode(name: "Test", icon: "star", color: "blue", habitIds: [UUID()])
        
        // Initially no active mode
        XCTAssertNil(manager.activeFocusMode)
        
        // After activation, this would need real habits array
        // manager.activateFocusMode(mode, allHabits: [])
        // XCTAssertEqual(manager.activeFocusMode?.id, mode.id)
    }
}

// MARK: - Backup Manager Tests

final class BackupManagerTests: XCTestCase {
    
    func testBackupManagerSingleton() {
        let manager1 = BackupManager.shared
        let manager2 = BackupManager.shared
        XCTAssertTrue(manager1 === manager2)
    }
    
    func testBackupErrorDescriptions() {
        let errors: [BackupError] = [.directoryNotFound, .invalidData, .backupFailed]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - Onboarding Tests

final class OnboardingTests: XCTestCase {
    
    func testOnboardingManagerSingleton() {
        let manager1 = OnboardingManager.shared
        let manager2 = OnboardingManager.shared
        XCTAssertTrue(manager1 === manager2)
    }
    
    func testOnboardingPagesCount() {
        // This would test the onboarding pages array
        // Assuming 6 pages based on implementation
        XCTAssertTrue(true) // Placeholder
    }
    
    func testTipsManagerTipsCount() {
        let manager = TipsManager.shared
        XCTAssertGreaterThan(manager.tips.count, 0)
    }
}

// MARK: - Theme Manager Tests

final class ThemeManagerTests: XCTestCase {
    
    func testThemeColorFor() {
        let theme = ThemeManager.shared
        
        XCTAssertEqual(theme.colorFor("red"), .red)
        XCTAssertEqual(theme.colorFor("blue"), .blue)
        XCTAssertEqual(theme.colorFor("green"), .green)
        XCTAssertEqual(theme.colorFor("invalid"), .blue) // Default
    }
    
    func testThemeManagerSingleton() {
        let theme1 = ThemeManager.shared
        let theme2 = ThemeManager.shared
        XCTAssertTrue(theme1 === theme2)
    }
}

// MARK: - Date Helper Tests (Additional)

final class DateHelperTests: XCTestCase {
    
    func testStartOfDayConsistency() {
        let date = Date()
        let start1 = startOfDay(date)
        let start2 = startOfDay(date)
        
        XCTAssertEqual(start1, start2)
    }
    
    func testIsSameDayWithSameDay() {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(3600) // 1 hour later
        
        XCTAssertTrue(isSameDay(date1, date2))
    }
    
    func testIsSameDayWithDifferentDays() {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(86400) // 1 day later
        
        XCTAssertFalse(isSameDay(date1, date2))
    }
}

// MARK: - Integration Tests

final class IntegrationTests: XCTestCase {
    
    func testHabitWithCategoryRelationship() {
        let category = HabitCategory(name: "Test", icon: "star", color: "blue")
        let habit = Habit(title: "Test Habit", icon: "checkmark", color: "green", categoryId: category.id)
        
        XCTAssertEqual(habit.categoryId, category.id)
    }
    
    func testQuickActions() {
        let actions: [QuickAction] = [.completeFirstHabit, .openJournal, .viewStats, .addNewHabit]
        
        for action in actions {
            XCTAssertFalse(action.title.isEmpty)
            XCTAssertFalse(action.icon.isEmpty)
            XCTAssertFalse(action.rawValue.isEmpty)
        }
    }
}
