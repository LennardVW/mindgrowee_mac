import SwiftUI
import SwiftData

/// Main entry point with encryption check
struct SecureContentView: View {
    @State private var showingSetup = false
    @State private var showingUnlock = false
    @State private var isReady = false
    
    var body: some View {
        Group {
            if isReady {
                ContentView()
            } else {
                loadingView
            }
        }
        .onAppear {
            checkEncryption()
        }
        .sheet(isPresented: $showingSetup) {
            SetupEncryptionView {
                isReady = true
            }
        }
        .sheet(isPresented: $showingUnlock) {
            UnlockEncryptionView {
                isReady = true
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("MindGrowee")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Loading...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 300, height: 200)
    }
    
    private func checkEncryption() {
        let hasSetup = EncryptionManager.shared.checkExistingSetup()
        
        if hasSetup {
            // Need to unlock
            showingUnlock = true
        } else {
            // First time - show setup
            showingSetup = true
        }
    }
}

/// Modified ContentView that works with encryption
struct EncryptedContentView: View {
    @State private var selectedTab = 0
    @State private var showingExport = false
    @State private var showingSettings = false
    @State private var showingKeyboardShortcuts = false
    @State private var showingAbout = false
    @State private var showingOnboarding = false
    
    @AppStorage("accentColor") private var accentColor = "blue"
    
    private var resolvedAccent: Color {
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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
                }
                .tag(0)
            
            HabitsView()
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle.fill")
                }
                .tag(1)
            
            EncryptedJournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(2)
            
            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "folder.fill")
                }
                .tag(3)
            
            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
        .frame(minWidth: 800, minHeight: 600)
        .tint(resolvedAccent)
        .accentColor(resolvedAccent)
    }
}

/// Journal view that uses encrypted models
struct EncryptedJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EncryptedJournalEntry.date, order: .reverse) private var entries: [EncryptedJournalEntry]
    
    @State private var showingNewEntry = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Journal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingNewEntry = true }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            List {
                ForEach(entries) { entry in
                    EncryptedJournalRow(entry: entry)
                }
            }
            .listStyle(.inset)
        }
        .sheet(isPresented: $showingNewEntry) {
            NewEncryptedEntrySheet { content, mood, tags in
                do {
                    let entry = try EncryptedJournalEntry(
                        date: Date(),
                        content: content,
                        mood: mood,
                        tags: tags
                    )
                    modelContext.insert(entry)
                    showingNewEntry = false
                } catch {
                    Logger.shared.error("Failed to create encrypted entry", error: error)
                }
            } onCancel: {
                showingNewEntry = false
            }
        }
    }
}

/// Sheet for creating new encrypted entry
struct NewEncryptedEntrySheet: View {
    let onSave: (String, Int, [String]) -> Void
    let onCancel: () -> Void
    
    @State private var content = ""
    @State private var mood = 3
    @State private var tagInput = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Journal Entry")
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                ForEach(1...5, id: \.self) { i in
                    Button(action: { mood = i }) {
                        Image(systemName: i <= mood ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(i <= mood ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            TextEditor(text: $content)
                .font(.body)
                .frame(minHeight: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            TextField("Tags (comma separated)", text: $tagInput)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel", action: onCancel)
                Button("Save") {
                    let tags = tagInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    onSave(content, mood, tags)
                }
                .disabled(content.isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}
