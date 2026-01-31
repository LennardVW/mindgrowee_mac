import SwiftUI

// MARK: - Accessibility Manager

class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    private init() {}
    
    // MARK: - VoiceOver Labels
    
    func habitLabel(title: String, isCompleted: Bool, streak: Int) -> String {
        let status = isCompleted ? "completed" : "not completed"
        let streakText = streak > 0 ? ", \(streak) day streak" : ""
        return "\(title), \(status)\(streakText)"
    }
    
    func journalEntryLabel(date: Date, mood: Int) -> String {
        let dateText = date.formatted(date: .long, time: .omitted)
        let moodText = moodDescription(mood)
        return "Journal entry from \(dateText), mood: \(moodText)"
    }
    
    func moodDescription(_ mood: Int) -> String {
        switch mood {
        case 1: return "Very bad"
        case 2: return "Bad"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Excellent"
        default: return "Unknown"
        }
    }
    
    func progressLabel(current: Int, total: Int) -> String {
        let percentage = total > 0 ? (current * 100 / total) : 0
        return "\(current) of \(total) habits completed, \(percentage) percent"
    }
    
    func streakLabel(days: Int) -> String {
        if days == 0 {
            return "No current streak"
        } else if days == 1 {
            return "1 day streak"
        } else {
            return "\(days) day streak"
        }
    }
    
    // MARK: - VoiceOver Actions
    
    func announce(_ message: String, priority: AnnouncementPriority = .normal) {
        DispatchQueue.main.async {
            #if os(macOS)
            // Use NSAccessibility post notification
            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: [
                    .announcement: message,
                    .priority: priority.rawValue
                ]
            )
            #endif
            
            Logger.shared.info("Accessibility announcement: \(message)")
        }
    }
    
    func announceHabitComplete(_ title: String) {
        announce("\(title) completed", priority: .high)
    }
    
    func announceProgress(current: Int, total: Int) {
        let remaining = total - current
        if remaining == 0 {
            announce("All habits completed!", priority: .high)
        } else {
            announce("\(current) of \(total) completed, \(remaining) remaining")
        }
    }
    
    func announceStreakMilestone(_ days: Int) {
        if days == 7 {
            announce("Congratulations! 7 day streak!", priority: .high)
        } else if days == 30 {
            announce("Amazing! 30 day streak!", priority: .high)
        } else if days == 100 {
            announce("Incredible! 100 day streak!", priority: .high)
        }
    }
    
    // MARK: - Accessibility Checks
    
    var isVoiceOverEnabled: Bool {
        #if os(macOS)
        return NSWorkspace.shared.isVoiceOverEnabled
        #else
        return false
        #endif
    }
    
    var isReduceMotionEnabled: Bool {
        #if os(macOS)
        // Check accessibility settings
        return false // Simplified for macOS
        #else
        return false
        #endif
    }
    
    // MARK: - Dynamic Type Support
    
    func scaledFont(for textStyle: Font.TextStyle) -> Font {
        // macOS doesn't support dynamic type like iOS,
        // but we can respect system font size preferences
        return Font.system(textStyle)
    }
}

// MARK: - Announcement Priority

enum AnnouncementPriority: Int {
    case low = 1
    case normal = 10
    case high = 20
}

// MARK: - View Extensions for Accessibility

extension View {
    func withAccessibilityLabel(_ label: String) -> some View {
        self.accessibilityLabel(label)
    }
    
    func withAccessibilityHint(_ hint: String) -> some View {
        self.accessibilityHint(hint)
    }
    
    func withAccessibilityValue(_ value: String) -> some View {
        self.accessibilityValue(value)
    }
    
    func withAccessibilityTraits(_ traits: AccessibilityTraits) -> some View {
        self.accessibilityAddTraits(traits)
    }
    
    func withAccessibilityAction(named name: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: name, action)
    }
    
    func withAccessibilityHidden(_ hidden: Bool) -> some View {
        self.accessibilityHidden(hidden)
    }
    
    func withAccessibilitySortPriority(_ priority: Double) -> some View {
        self.accessibilitySortPriority(priority)
    }
}

// MARK: - Accessible Button

struct AccessibleButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    let accessibilityLabel: String
    let accessibilityHint: String?
    
    init(
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }
    
    var body: some View {
        Button(action: action) {
            label
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "")
    }
}

// MARK: - Accessible Toggle

struct AccessibleToggle: View {
    @Binding var isOn: Bool
    let title: String
    let accessibilityLabel: String
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(isOn ? "On" : "Off")
    }
}

// MARK: - Accessibility Testing Helper

#if DEBUG
class AccessibilityTester {
    static let shared = AccessibilityTester()
    
    private init() {}
    
    func runAccessibilityAudit(on view: NSView) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // Check for missing labels
        if view.accessibilityLabel() == nil && !view.isAccessibilityElement() {
            issues.append(AccessibilityIssue(
                type: .missingLabel,
                element: view,
                description: "Interactive element missing accessibility label"
            ))
        }
        
        // Check for contrast (simplified)
        // In real implementation, would check actual color contrast ratios
        
        return issues
    }
    
    func validateAccessibility(for viewController: NSViewController) -> Bool {
        guard let view = viewController.view else { return false }
        let issues = runAccessibilityAudit(on: view)
        
        if !issues.isEmpty {
            Logger.shared.warning("Accessibility issues found: \(issues.count)")
            for issue in issues {
                Logger.shared.warning("  - \(issue.description)")
            }
        }
        
        return issues.isEmpty
    }
}

struct AccessibilityIssue {
    enum IssueType {
        case missingLabel
        case missingHint
        case lowContrast
        case smallTarget
    }
    
    let type: IssueType
    let element: NSView
    let description: String
}
#endif

// MARK: - Reduced Motion Support

extension View {
    func withReducedMotion() -> some View {
        self.modifier(ReducedMotionModifier())
    }
}

struct ReducedMotionModifier: ViewModifier {
    @State private var reduceMotion = false
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? .none : .default, value: reduceMotion)
    }
}
