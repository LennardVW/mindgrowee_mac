import SwiftUI

// MARK: - Quick Actions Manager

@MainActor
class QuickActionsManager: ObservableObject {
    static let shared = QuickActionsManager()
    
    @Published var quickAction: QuickAction?
    
    private init() {}
    
    func handleQuickAction(_ action: QuickAction) {
        quickAction = action
    }
    
    func clearQuickAction() {
        quickAction = nil
    }
}

// MARK: - Quick Action Types

enum QuickAction: String, CaseIterable {
    case completeFirstHabit = "completeFirst"
    case openJournal = "openJournal"
    case viewStats = "viewStats"
    case addNewHabit = "addHabit"
    
    var title: String {
        switch self {
        case .completeFirstHabit:
            return "Complete First Habit"
        case .openJournal:
            return "Write Journal Entry"
        case .viewStats:
            return "View Statistics"
        case .addNewHabit:
            return "Add New Habit"
        }
    }
    
    var icon: String {
        switch self {
        case .completeFirstHabit:
            return "checkmark.circle"
        case .openJournal:
            return "book"
        case .viewStats:
            return "chart.bar"
        case .addNewHabit:
            return "plus.circle"
        }
    }
    
    #if os(iOS)
    var shortcutItem: UIApplicationShortcutItem {
        UIApplicationShortcutItem(
            type: rawValue,
            localizedTitle: title,
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(type: .compose),
            userInfo: nil
        )
    }
    #endif
}

// MARK: - Quick Actions Bar

struct QuickActionsBar: View {
    let actions: [QuickAction] = [.completeFirstHabit, .openJournal, .viewStats, .addNewHabit]
    let onAction: (QuickAction) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(actions, id: \.self) { action in
                    QuickActionButton(action: action, onTap: {
                        onAction(action)
                    })
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: action.icon)
                    .font(.title2)
                
                Text(action.title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 60)
            .padding(.horizontal, 8)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today Widget Extension (for macOS)
// Note: Using modern WidgetKit instead of deprecated NCWidgetProviding

#if os(macOS)
// Widget implementation would go here using WidgetKit
// For now, this is a placeholder for future widget support
#endif
