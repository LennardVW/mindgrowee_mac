import XCTest
@testable import mindgrowee_mac

final class AccessibilityTests: XCTestCase {
    
    // MARK: - Accessibility Manager Tests
    
    func testHabitLabelCompleted() {
        let label = AccessibilityManager.shared.habitLabel(
            title: "Exercise",
            isCompleted: true,
            streak: 5
        )
        XCTAssertEqual(label, "Exercise, completed, 5 day streak")
    }
    
    func testHabitLabelNotCompleted() {
        let label = AccessibilityManager.shared.habitLabel(
            title: "Read",
            isCompleted: false,
            streak: 0
        )
        XCTAssertEqual(label, "Read, not completed")
    }
    
    func testMoodDescriptions() {
        let manager = AccessibilityManager.shared
        
        XCTAssertEqual(manager.moodDescription(1), "Very bad")
        XCTAssertEqual(manager.moodDescription(2), "Bad")
        XCTAssertEqual(manager.moodDescription(3), "Okay")
        XCTAssertEqual(manager.moodDescription(4), "Good")
        XCTAssertEqual(manager.moodDescription(5), "Excellent")
        XCTAssertEqual(manager.moodDescription(0), "Unknown")
        XCTAssertEqual(manager.moodDescription(6), "Unknown")
    }
    
    func testProgressLabel() {
        let label = AccessibilityManager.shared.progressLabel(current: 3, total: 5)
        XCTAssertEqual(label, "3 of 5 habits completed, 60 percent")
    }
    
    func testProgressLabelZeroTotal() {
        let label = AccessibilityManager.shared.progressLabel(current: 0, total: 0)
        XCTAssertEqual(label, "0 of 0 habits completed, 0 percent")
    }
    
    func testStreakLabel() {
        let manager = AccessibilityManager.shared
        
        XCTAssertEqual(manager.streakLabel(days: 0), "No current streak")
        XCTAssertEqual(manager.streakLabel(days: 1), "1 day streak")
        XCTAssertEqual(manager.streakLabel(days: 5), "5 day streak")
        XCTAssertEqual(manager.streakLabel(days: 30), "30 day streak")
    }
    
    // MARK: - Localization Tests
    
    func testGermanLocalizationKeys() {
        // Test that all L10n keys return non-empty strings
        XCTAssertFalse(L10n.appName.isEmpty)
        XCTAssertFalse(L10n.ok.isEmpty)
        XCTAssertFalse(L10n.cancel.isEmpty)
        XCTAssertFalse(L10n.habitsTitle.isEmpty)
        XCTAssertFalse(L10n.journalTitle.isEmpty)
        XCTAssertFalse(L10n.statsTitle.isEmpty)
    }
    
    func testLocalizedStringInterpolation() {
        let result = L10n.habitsOfCompleted(3, 5)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("3"))
        XCTAssertTrue(result.contains("5"))
    }
    
    func testCategoryLocalization() {
        XCTAssertFalse(L10n.categoryHealth.isEmpty)
        XCTAssertFalse(L10n.categoryFitness.isEmpty)
        XCTAssertFalse(L10n.categoryProductivity.isEmpty)
    }
    
    // MARK: - Validation Tests
    
    func testEmptyHabitTitleValidation() {
        let validator = DataValidator.shared
        
        XCTAssertThrowsError(try validator.validateHabitTitle("")) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.emptyHabitTitle)
        }
        
        XCTAssertThrowsError(try validator.validateHabitTitle("   ")) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.emptyHabitTitle)
        }
    }
    
    func testValidHabitTitle() {
        let validator = DataValidator.shared
        
        XCTAssertNoThrow(try validator.validateHabitTitle("Exercise"))
        XCTAssertNoThrow(try validator.validateHabitTitle("  Read  ")) // Will be trimmed
    }
    
    func testEmptyJournalContentValidation() {
        let validator = DataValidator.shared
        
        XCTAssertThrowsError(try validator.validateJournalContent("")) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.emptyJournalContent)
        }
    }
    
    func testValidJournalContent() {
        let validator = DataValidator.shared
        
        XCTAssertNoThrow(try validator.validateJournalContent("Had a great day!"))
    }
    
    func testDateValidation() {
        let validator = DataValidator.shared
        
        XCTAssertTrue(validator.validateDate("2026-01-31"))
        XCTAssertTrue(validator.validateDate("2024-02-29")) // Leap year
        XCTAssertFalse(validator.validateDate("invalid"))
        XCTAssertFalse(validator.validateDate(""))
        XCTAssertFalse(validator.validateDate("2026-13-01")) // Invalid month
        XCTAssertFalse(validator.validateDate("2026-01-32")) // Invalid day
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecoveryResult() {
        let success = ErrorRecoveryResult.recovered
        let failure = ErrorRecoveryResult.failed(message: "Test error")
        
        switch success {
        case .recovered:
            XCTAssertTrue(true)
        case .failed:
            XCTFail("Should be recovered")
        }
        
        switch failure {
        case .recovered:
            XCTFail("Should be failed")
        case .failed(let message):
            XCTAssertEqual(message, "Test error")
        }
    }
    
    func testValidationResult() {
        let valid = ValidationResult.valid
        let noChanges = ValidationResult.noChanges
        let invalid = ValidationResult.invalid(message: "Validation failed")
        
        switch valid {
        case .valid:
            XCTAssertTrue(true)
        default:
            XCTFail("Should be valid")
        }
        
        switch invalid {
        case .invalid(let message):
            XCTAssertEqual(message, "Validation failed")
        default:
            XCTFail("Should be invalid")
        }
    }
    
    // MARK: - Data Error Tests
    
    func testDataErrorDescriptions() {
        let errors: [DataError] = [
            .operationFailed(message: "Test"),
            .fetchFailed(message: "Test"),
            .saveFailed(message: "Test"),
            .validationFailed(message: "Test"),
            .modelNotFound,
            .corruptedData
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Performance Monitor Tests
    
    func testPerformanceMonitor() {
        let monitor = PerformanceMonitor.shared
        
        let result = monitor.measure(name: "test") {
            // Simple operation
            var sum = 0
            for i in 0..<100 {
                sum += i
            }
            return sum
        }
        
        XCTAssertEqual(result, 4950)
    }
    
    // MARK: - Crash Prevention Tests
    
    func testSafeArrayAccess() {
        let array = [1, 2, 3, 4, 5]
        let prevention = CrashPrevention.shared
        
        XCTAssertEqual(prevention.safeArrayAccess(array: array, index: 0), 1)
        XCTAssertEqual(prevention.safeArrayAccess(array: array, index: 4), 5)
        XCTAssertNil(prevention.safeArrayAccess(array: array, index: -1))
        XCTAssertNil(prevention.safeArrayAccess(array: array, index: 5))
        XCTAssertNil(prevention.safeArrayAccess(array: [], index: 0))
    }
    
    func testSafeUnwrap() {
        let prevention = CrashPrevention.shared
        
        XCTAssertEqual(prevention.safeUnwrap(42, defaultValue: 0, context: "test"), 42)
        XCTAssertEqual(prevention.safeUnwrap(nil, defaultValue: 0, context: "test"), 0)
    }
    
    func testSafeString() {
        let prevention = CrashPrevention.shared
        
        XCTAssertEqual(prevention.safeString("Hello", defaultValue: "default"), "Hello")
        XCTAssertEqual(prevention.safeString("", defaultValue: "default"), "default")
        XCTAssertEqual(prevention.safeString(nil, defaultValue: "default"), "default")
    }
    
    // MARK: - Memory Cache Tests
    
    func testMemoryCache() {
        let cache = MemoryCache<String, Int>(countLimit: 10)
        
        XCTAssertNil(cache.get("key1"))
        
        cache.set(42, forKey: "key1")
        XCTAssertEqual(cache.get("key1"), 42)
        
        cache.remove("key1")
        XCTAssertNil(cache.get("key1"))
        
        cache.set(1, forKey: "a")
        cache.set(2, forKey: "b")
        cache.clear()
        XCTAssertNil(cache.get("a"))
        XCTAssertNil(cache.get("b"))
    }
    
    // MARK: - Throttler Tests
    
    func testThrottler() {
        let expectation = self.expectation(description: "Throttled action executed")
        var callCount = 0
        
        let throttler = Throttler(minimumDelay: 0.1)
        
        // Call multiple times rapidly
        for _ in 0..<5 {
            throttler.throttle {
                callCount += 1
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.5) { _ in
            XCTAssertEqual(callCount, 1, "Throttler should only execute once")
        }
    }
    
    // MARK: - Debouncer Tests
    
    func testDebouncer() {
        let expectation = self.expectation(description: "Debounced action executed")
        var callCount = 0
        
        let debouncer = Debouncer(delay: 0.1)
        
        // Call multiple times rapidly
        for _ in 0..<5 {
            debouncer.debounce {
                callCount += 1
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.5) { _ in
            XCTAssertEqual(callCount, 1, "Debouncer should only execute once")
        }
    }
}
