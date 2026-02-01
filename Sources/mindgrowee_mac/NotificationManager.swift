import Foundation
import UserNotifications

// MARK: - Notification Manager

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            
            if let error = error {
                Logger.shared.error("Notification authorization failed", error: error)
            }
        }
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isAuthorized = settings.authorizationStatus == .authorized
            DispatchQueue.main.async {
                self.isAuthorized = isAuthorized
            }
        }
    }
    
    func scheduleHabitReminder(habitId: UUID, title: String, time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for \(title)"
        content.body = "Don't break your streak! Complete your habit now."
        content.sound = .default
        
        // Extract hour and minute from time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "habit-\(habitId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.error("Failed to schedule notification", error: error)
            }
        }
    }
    
    func cancelHabitReminder(habitId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["habit-\(habitId.uuidString)"]
        )
    }
    
    func scheduleEveningSummary(habits: [Habit]) {
        let content = UNMutableNotificationContent()
        
        let completed = habits.filter { habit in
            habit.completions?.contains { completion in
                Calendar.current.isDate(completion.date, inSameDayAs: Date()) && completion.completed
            } ?? false
        }.count
        
        let total = habits.count
        let remaining = total - completed
        
        if remaining > 0 {
            content.title = "Daily Summary"
            content.body = "You have \(remaining) habit\(remaining == 1 ? "" : "s") remaining today. Keep going!"
        } else if total > 0 {
            content.title = "All Done! 🎉"
            content.body = "You completed all your habits today. Great job!"
        } else {
            return // No habits, no notification
        }
        
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "evening-summary",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelEveningSummary() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["evening-summary"]
        )
    }
    
    func scheduleStreakReminder(streak: Int) {
        guard streak >= 3 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 Streak Alert!"
        content.body = "You're on a \(streak)-day streak! Don't break it today."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9 // 9 AM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "streak-reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - Habit Reminder Time

struct HabitReminder: Codable, Equatable {
    var habitId: UUID
    var time: Date
    var isEnabled: Bool
}

// MARK: - Sound Manager

import AVFoundation

@MainActor
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isEnabled = true
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    func playHabitComplete() {
        guard isEnabled else { return }
        playSystemSound(id: 1394) // Tock sound
    }
    
    func playHabitUncheck() {
        guard isEnabled else { return }
        playSystemSound(id: 1105) // Tock sound
    }
    
    func playSuccess() {
        guard isEnabled else { return }
        playSystemSound(id: 1407) // Success sound
    }
    
    func playStreakMilestone() {
        guard isEnabled else { return }
        playSystemSound(id: 1325) // Fanfare
    }
    
    private func playSystemSound(id: UInt32) {
        AudioServicesPlaySystemSound(id)
    }
}

import AudioToolbox
