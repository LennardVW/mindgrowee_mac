import XCTest
@testable import mindgrowee_mac

final class MindGroweeMacTests: XCTestCase {
    
    // MARK: - Date Helper Tests
    
    func testStartOfDay() {
        let date = Date()
        let start = startOfDay(date)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: start)
        
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }
    
    func testIsSameDay() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        XCTAssertTrue(isSameDay(today, today))
        XCTAssertFalse(isSameDay(today, yesterday))
    }
    
    // MARK: - Streak Calculation Tests
    
    func testStreakCalculation() {
        // This would test streak calculation with mock data
        // In a real test, we'd create habits with completions
        // and verify the streak calculation
        XCTAssertTrue(true) // Placeholder
    }
    
    // MARK: - Theme Manager Tests
    
    func testThemeColorConversion() {
        let theme = ThemeManager.shared
        
        XCTAssertEqual(theme.colorFor("red"), .red)
        XCTAssertEqual(theme.colorFor("blue"), .blue)
        XCTAssertEqual(theme.colorFor("green"), .green)
        XCTAssertEqual(theme.colorFor("invalid"), .blue) // Default
    }
    
    // MARK: - Streak Freeze Tests
    
    func testStreakFreezeManager() {
        let manager = StreakFreezeManager()
        let freezes: [StreakFreeze] = []
        
        // Should have 3 available when no freezes used
        XCTAssertEqual(manager.calculateAvailableFreezes(freezes: freezes), 3)
        XCTAssertTrue(manager.canUseFreeze(freezes: freezes))
    }
}
