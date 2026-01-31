import SwiftUI

// MARK: - Keyboard Shortcuts Help

struct KeyboardShortcutsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let shortcuts: [(key: String, description: String)] = [
        ("⌘ D", "Quick complete habits"),
        ("⌘ ⇧ N", "New habit"),
        ("⌘ J", "New journal entry"),
        ("⌘ ⇧ E", "Export data"),
        ("⌘ ,", "Open settings"),
        ("⌘ Q", "Quit app"),
        ("⌘ 1", "Switch to Habits tab"),
        ("⌘ 2", "Switch to Journal tab"),
        ("⌘ 3", "Switch to Stats tab"),
        ("⌘ ⌫", "Delete selected item"),
        ("⌘ F", "Search in Journal"),
        ("Esc", "Close sheet/window"),
        ("↑ ↓", "Navigate habits (when focused)"),
        ("Space", "Toggle habit completion"),
        ("Enter", "Open habit details"),
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.title)
                .fontWeight(.bold)
            
            List(shortcuts, id: \.key) { shortcut in
                HStack {
                    Text(shortcut.key)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Spacer()
                    
                    Text(shortcut.description)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
            
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .padding()
        }
        .frame(width: 450, height: 500)
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("MindGrowee")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .foregroundStyle(.secondary)
            
            Text("Native macOS Habit Tracker & Journal")
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Built with SwiftUI", systemImage: "swift")
                Label("Local storage with SwiftData", systemImage: "internaldrive")
                Label("No cloud, no accounts, fully private", systemImage: "lock.shield")
            }
            .foregroundStyle(.secondary)
            .padding()
            
            HStack(spacing: 20) {
                Link("GitHub", destination: URL(string: "https://github.com/LennardVW/mindgrowee_mac")!)
                
                Button("Keyboard Shortcuts...") {
                    // Show shortcuts
                }
            }
            
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .padding(.top)
        }
        .padding()
        .frame(width: 400, height: 450)
    }
}
