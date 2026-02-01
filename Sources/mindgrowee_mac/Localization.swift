import Foundation

// MARK: - Localization Extension

extension String {
    /// Localizes the string using the main bundle
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Localizes the string with format arguments
    func localized(_ arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Common Localization Keys

enum L10n {
    // General
    static let appName = "app_name".localized
    static let ok = "ok".localized
    static let cancel = "cancel".localized
    static let save = "save".localized
    static let delete = "delete".localized
    static let edit = "edit".localized
    static let done = "done".localized
    
    // Habits
    static let habitsTitle = "habits_title".localized
    static let habitsToday = "habits_today".localized
    static let habitsEmpty = "habits_empty".localized
    static let habitsCreateFirst = "habits_create_first".localized
    static func habitsOfCompleted(_ completed: Int, _ total: Int) -> String {
        return "habits_of_completed".localized(completed, total)
    }
    static func habitsStreak(_ days: Int) -> String {
        return "habits_streak".localized(days)
    }
    
    // Journal
    static let journalTitle = "journal_title".localized
    static let journalNew = "journal_new".localized
    static let journalEmpty = "journal_empty".localized
    static func journalResults(_ count: Int) -> String {
        return "journal_results".localized(count)
    }
    
    // Statistics
    static let statsTitle = "stats_title".localized
    static let statsTotalHabits = "stats_total_habits".localized
    static let statsCurrentStreak = "stats_current_streak".localized
    static let statsBestStreak = "stats_best_streak".localized
    
    // Settings
    static let settingsTitle = "settings_title".localized
    static let settingsGeneral = "settings_general".localized
    static let settingsAppearance = "settings_appearance".localized
    
    // Categories
    static let categoryHealth = "category_health".localized
    static let categoryFitness = "category_fitness".localized
    static let categoryProductivity = "category_productivity".localized
    static let categoryLearning = "category_learning".localized
    static let categoryMindfulness = "category_mindfulness".localized
    static let categorySocial = "category_social".localized
    static let categoryCreative = "category_creative".localized
    static let categoryFinance = "category_finance".localized
}

// MARK: - Localization Helper

@MainActor
class Localization {
    static let shared = Localization()
    
    var currentLanguage: String {
        return Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    var isGerman: Bool {
        return currentLanguage.hasPrefix("de")
    }
    
    var isEnglish: Bool {
        return currentLanguage.hasPrefix("en")
    }
    
    func localizedString(for key: String) -> String {
        return key.localized
    }
}
