import SwiftUI

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            applyTheme()
        }
    }
    
    @Published var accentColor: String {
        didSet {
            UserDefaults.standard.set(accentColor, forKey: "accentColor")
        }
    }
    
    @Published var useSystemAppearance: Bool {
        didSet {
            UserDefaults.standard.set(useSystemAppearance, forKey: "useSystemAppearance")
            applyTheme()
        }
    }
    
    private init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.accentColor = UserDefaults.standard.string(forKey: "accentColor") ?? "blue"
        self.useSystemAppearance = UserDefaults.standard.object(forKey: "useSystemAppearance") as? Bool ?? true
    }
    
    func applyTheme() {
        // Apply to NSApp appearance
        if useSystemAppearance {
            NSApp.appearance = nil
        } else {
            NSApp.appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
        }
    }
    
    func color() -> Color {
        switch accentColor {
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

// MARK: - Theme Extension

extension View {
    func themed() -> some View {
        self.modifier(ThemeModifier())
    }
}

struct ThemeModifier: ViewModifier {
    @StateObject private var theme = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(theme.useSystemAppearance ? nil : (theme.isDarkMode ? .dark : .light))
    }
}

// MARK: - Keyboard Navigation Manager

class KeyboardNavigation: ObservableObject {
    static let shared = KeyboardNavigation()
    
    @Published var selectedHabitIndex: Int?
    @Published var isNavigationActive = false
    
    private init() {}
    
    func handleKey(_ event: NSEvent, habitsCount: Int) -> Bool {
        guard isNavigationActive else { return false }
        
        switch event.keyCode {
        case 125: // Down arrow
            moveDown(habitsCount: habitsCount)
            return true
        case 126: // Up arrow
            moveUp()
            return true
        case 36: // Return/Enter
            return toggleSelected()
        case 53: // Escape
            isNavigationActive = false
            selectedHabitIndex = nil
            return true
        default:
            return false
        }
    }
    
    private func moveDown(habitsCount: Int) {
        if let current = selectedHabitIndex {
            selectedHabitIndex = min(current + 1, habitsCount - 1)
        } else {
            selectedHabitIndex = 0
        }
    }
    
    private func moveUp() {
        if let current = selectedHabitIndex {
            selectedHabitIndex = max(current - 1, 0)
        }
    }
    
    private func toggleSelected() -> Bool {
        // This will be handled by the view
        return selectedHabitIndex != nil
    }
}

// MARK: - Accessibility Manager

class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    func announce(_ message: String) {
        NSAccessibility.post(element: NSApp.mainWindow as Any, notification: .announcementRequested, userInfo: [
            .announcement: message,
            .priority: NSAccessibilityPriorityLevel.high.rawValue
        ])
    }
    
    func announceHabitComplete(_ habitTitle: String) {
        announce("\(habitTitle) completed")
    }
    
    func announceProgress(current: Int, total: Int) {
        let remaining = total - current
        if remaining == 0 {
            announce("All habits completed!")
        } else {
            announce("\(current) of \(total) habits completed, \(remaining) remaining")
        }
    }
}

// MARK: - Haptic Feedback

import AppKit

class HapticManager {
    static let shared = HapticManager()
    
    func playSuccess() {
        // Use system beep as haptic feedback alternative
        NSSound.beep()
    }
    
    func playLightImpact() {
        // Subtle feedback
    }
    
    func playMediumImpact() {
        NSSound.beep()
    }
}
