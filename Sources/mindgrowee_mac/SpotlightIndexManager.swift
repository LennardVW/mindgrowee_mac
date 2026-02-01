import SwiftUI
import CoreSpotlight
import SwiftData

// MARK: - Spotlight Index Manager

@MainActor
class SpotlightIndexManager {
    static let shared = SpotlightIndexManager()
    
    private let domainIdentifier = "com.mindgrowee"
    
    private init() {}
    
    // MARK: - Index Habits
    
    func indexHabits(_ habits: [Habit]) {
        var items: [CSSearchableItem] = []
        
        for habit in habits {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
            attributeSet.title = habit.title
            attributeSet.contentDescription = "Habit - Track your daily progress"
            attributeSet.keywords = ["habit", "tracking", "daily", habit.title]
            attributeSet.thumbnailData = iconData(for: habit.icon, color: habit.color)
            
            let item = CSSearchableItem(
                uniqueIdentifier: "habit-\(habit.id.uuidString)",
                domainIdentifier: domainIdentifier,
                attributeSet: attributeSet
            )
            items.append(item)
        }
        
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                Logger.shared.error("Failed to index habits", error: error)
            }
        }
    }
    
    // MARK: - Index Journal Entries
    
    func indexJournalEntries(_ entries: [JournalEntry]) {
        var items: [CSSearchableItem] = []
        
        for entry in entries {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = entry.date.formatted(date: .long, time: .shortened)
            attributeSet.contentDescription = String(entry.content.prefix(100))
            attributeSet.keywords = ["journal", "entry", "mood"] + entry.tags
            attributeSet.contentModificationDate = entry.date
            
            let item = CSSearchableItem(
                uniqueIdentifier: "journal-\(entry.id.uuidString)",
                domainIdentifier: domainIdentifier,
                attributeSet: attributeSet
            )
            items.append(item)
        }
        
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                Logger.shared.error("Failed to index journal entries", error: error)
            }
        }
    }
    
    // MARK: - Delete from Index
    
    func deleteHabitFromIndex(habitId: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["habit-\(habitId.uuidString)"])
    }
    
    func deleteJournalEntryFromIndex(entryId: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["journal-\(entryId.uuidString)"])
    }
    
    func deleteAllIndexes() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
    }
    
    // MARK: - Handle Search Result
    
    func handleSearchResult(identifier: String) -> SearchResult? {
        if identifier.hasPrefix("habit-") {
            let idString = String(identifier.dropFirst(6))
            if let uuid = UUID(uuidString: idString) {
                return .habit(id: uuid)
            }
        } else if identifier.hasPrefix("journal-") {
            let idString = String(identifier.dropFirst(8))
            if let uuid = UUID(uuidString: idString) {
                return .journalEntry(id: uuid)
            }
        }
        return nil
    }
    
    // MARK: - Helper
    
    private func iconData(for iconName: String, color: String) -> Data? {
        // Create a simple NSImage representation
        let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        return image?.tiffRepresentation
    }
}

// MARK: - Search Result

enum SearchResult {
    case habit(id: UUID)
    case journalEntry(id: UUID)
}

// MARK: - Notification Names

extension Notification.Name {
    static let openHabit = Notification.Name("openHabit")
    static let openJournalEntry = Notification.Name("openJournalEntry")
}
