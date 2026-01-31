import SwiftUI
import SwiftData

// MARK: - App with Menu Bar Support

@main
struct MindGroweeMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Habit.self, DailyCompletion.self, JournalEntry.self])
        .commands {
            CommandMenu("Habits") {
                Button("Quick Complete") {
                    NotificationCenter.default.post(name: .quickComplete, object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Button("New Habit") {
                    NotificationCenter.default.post(name: .newHabit, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            CommandMenu("Journal") {
                Button("New Entry") {
                    NotificationCenter.default.post(name: .newJournal, object: nil)
                }
                .keyboardShortcut("j", modifiers: .command)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let quickComplete = Notification.Name("quickComplete")
    static let newHabit = Notification.Name("newHabit")
    static let newJournal = Notification.Name("newJournal")
    static let showAddHabit = Notification.Name("showAddHabit")
    static let showNewJournal = Notification.Name("showNewJournal")
}

// MARK: - App Delegate for Menu Bar

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var modelContainer: ModelContainer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup model container for menu bar
        do {
            modelContainer = try ModelContainer(for: Habit.self, DailyCompletion.self, JournalEntry.self)
        } catch {
            print("Failed to create model container: \(error)")
        }
        
        // Create status item
        statusItem = NSStatusBar.shared.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "MindGrowee")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .modelContainer(modelContainer!)
        )
        self.popover = popover
        
        // Hide main window initially if launched as menu bar app
        if let window = NSApplication.shared.windows.first {
            window.close()
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
