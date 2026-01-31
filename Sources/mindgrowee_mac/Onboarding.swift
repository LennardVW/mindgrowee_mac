import SwiftUI

// MARK: - Onboarding Manager

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @AppStorage("showTips") var showTips = true
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = OnboardingManager.shared
    
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to MindGrowee",
            description: "Your personal habit tracker and journal for macOS. Build better habits, one day at a time.",
            icon: "checkmark.circle.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "Track Daily Habits",
            description: "Create habits, mark them complete each day, and build streaks. Your progress resets daily so you always have a fresh start.",
            icon: "list.bullet.circle.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Journal Your Thoughts",
            description: "Record your daily thoughts, track your mood, and tag entries for easy searching. Look back on your journey anytime.",
            icon: "book.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "View Your Progress",
            description: "See detailed statistics about your habits, streaks, and mood over time. Visualize your growth.",
            icon: "chart.bar.fill",
            color: .purple
        ),
        OnboardingPage(
            title: "Quick Access",
            description: "MindGrowee lives in your menu bar for instant access. Use keyboard shortcuts for lightning-fast habit tracking.",
            icon: "menubar.rectangle",
            color: .pink
        ),
        OnboardingPage(
            title: "Your Data, Your Control",
            description: "Everything is stored locally on your Mac. No accounts, no cloud, complete privacy. Export anytime.",
            icon: "lock.shield.fill",
            color: .teal
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding()
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .keyboardShortcut(.cancelAction)
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                } else {
                    Button("Get Started") {
                        manager.completeOnboarding()
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .frame(width: 500, height: 450)
    }
}

// MARK: - Onboarding Page

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(page.color)
            
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

// MARK: - Tips Manager

class TipsManager: ObservableObject {
    static let shared = TipsManager()
    
    @Published var currentTip: Tip?
    @Published var isShowingTip = false
    
    let tips: [Tip] = [
        Tip(
            title: "Keyboard Shortcuts",
            message: "Press Cmd+D to quickly complete habits, Cmd+J for new journal entries",
            icon: "keyboard"
        ),
        Tip(
            title: "Menu Bar Access",
            message: "Click the checkmark icon in your menu bar for quick access to your habits",
            icon: "menubar.rectangle"
        ),
        Tip(
            title: "Drag to Reorder",
            message: "Drag habits in the list to reorder them however you like",
            icon: "arrow.up.arrow.down"
        ),
        Tip(
            title: "Streak Freezes",
            message: "Can't complete your habits today? Use a streak freeze to protect your progress",
            icon: "snowflake"
        ),
        Tip(
            title: "Export Your Data",
            message: "Regularly export your data as backup. Find it in Settings > Export",
            icon: "square.and.arrow.up"
        ),
        Tip(
            title: "Search Your Journal",
            message: "Use the search bar in Journal to find entries by content or tags",
            icon: "magnifyingglass"
        ),
        Tip(
            title: "Complete All",
            message: "In a hurry? Press Cmd+Shift+A to complete all habits at once",
            icon: "checkmark.circle.fill"
        ),
        Tip(
            title: "Spotlight Search",
            message: "Find your habits and journal entries using macOS Spotlight (Cmd+Space)",
            icon: "sparkle.magnifyingglass"
        )
    ]
    
    private var shownTips: Set<String> = []
    
    private init() {
        loadShownTips()
    }
    
    func showRandomTip() {
        let availableTips = tips.filter { !shownTips.contains($0.id) }
        
        if let tip = availableTips.randomElement() {
            currentTip = tip
            isShowingTip = true
            shownTips.insert(tip.id)
            saveShownTips()
        } else {
            // Reset if all tips shown
            shownTips.removeAll()
            showRandomTip()
        }
    }
    
    func dismissTip() {
        isShowingTip = false
    }
    
    private func loadShownTips() {
        if let tips = UserDefaults.standard.array(forKey: "shownTips") as? [String] {
            shownTips = Set(tips)
        }
    }
    
    private func saveShownTips() {
        UserDefaults.standard.set(Array(shownTips), forKey: "shownTips")
    }
}

// MARK: - Tip

struct Tip: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
}

// MARK: - Tip View

struct TipView: View {
    let tip: Tip
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tip.icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.headline)
                
                Text(tip.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
