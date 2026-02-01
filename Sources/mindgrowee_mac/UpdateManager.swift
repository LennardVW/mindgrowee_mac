import SwiftUI
import Foundation

/// Manages app updates and version checking
@MainActor
class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    @Published var isChecking = false
    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var releaseNotes: String?
    @Published var downloadURL: URL?
    @Published var error: String?
    
    private let currentVersion = "1.0.0"
    private let githubAPI = "https://api.github.com/repos/LennardVW/mindgrowee_mac/releases/latest"
    
    private init() {}
    
    // MARK: - Version Checking
    
    func checkForUpdates() {
        isChecking = true
        error = nil
        
        Task {
            do {
                guard let url = URL(string: githubAPI) else {
                    throw UpdateError.invalidURL
                }
                
                var request = URLRequest(url: url)
                request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw UpdateError.apiError
                }
                
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                
                await MainActor.run {
                    latestVersion = release.tagName.replacingOccurrences(of: "v", with: "")
                    releaseNotes = release.body
                    downloadURL = URL(string: release.htmlURL)
                    
                    // Compare versions
                    updateAvailable = isNewerVersion(release.tagName, than: currentVersion)
                    isChecking = false
                    
                    if updateAvailable {
                        Logger.shared.info("📦 Update available: \(release.tagName)")
                    } else {
                        Logger.shared.info("✅ App is up to date")
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isChecking = false
                }
            }
        }
    }
    
    private func isNewerVersion(_ version1: String, than version2: String) -> Bool {
        let v1 = version1.replacingOccurrences(of: "v", with: "")
        let v2 = version2.replacingOccurrences(of: "v", with: "")
        
        let components1 = v1.split(separator: ".").compactMap { Int($0) }
        let components2 = v2.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(components1.count, components2.count) {
            let c1 = i < components1.count ? components1[i] : 0
            let c2 = i < components2.count ? components2[i] : 0
            
            if c1 > c2 {
                return true
            } else if c1 < c2 {
                return false
            }
        }
        
        return false
    }
    
    // MARK: - Auto Check
    
    func scheduleAutoCheck() {
        // Check once per day
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            Task { @MainActor in
                self.checkForUpdates()
            }
        }
        
        // Initial check after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.checkForUpdates()
        }
    }
}

// MARK: - GitHub API Models

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let body: String
    let htmlURL: String
    let publishedAt: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlURL = "html_url"
        case publishedAt = "published_at"
    }
}

enum UpdateError: Error {
    case invalidURL
    case apiError
    case parsingError
}

// MARK: - Update View

struct UpdateCheckerView: View {
    @StateObject private var updateManager = UpdateManager.shared
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(spacing: 16) {
            if updateManager.isChecking {
                ProgressView("Checking for updates...")
            } else if updateManager.updateAvailable {
                updateAvailableView
            } else if let error = updateManager.error {
                errorView(message: error)
            } else {
                upToDateView
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private var updateAvailableView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
            
            Text("Update Available")
                .font(.title2)
                .fontWeight(.bold)
            
            if let version = updateManager.latestVersion {
                Text("Version \(version)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            if let notes = updateManager.releaseNotes {
                ScrollView {
                    Text(notes)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 150)
            }
            
            HStack {
                Button("Later") {
                    // Dismiss
                }
                
                Button("Download") {
                    if let url = updateManager.downloadURL {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var upToDateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)
            
            Text("You're Up to Date")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Version \(UpdateManager.shared.currentVersion)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            Text("Check Failed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
            
            Button("Try Again") {
                updateManager.checkForUpdates()
            }
        }
    }
}

// MARK: - Settings Extension

extension SettingsView {
    var updateSection: some View {
        Section("Updates") {
            HStack {
                Text("Current Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            
            Button("Check for Updates") {
                UpdateManager.shared.checkForUpdates()
            }
            
            Toggle("Automatically Check for Updates", isOn: .constant(true))
        }
    }
}
