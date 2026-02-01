import SwiftUI
import SwiftData

// MARK: - Export View

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \JournalEntry.date, order: .reverse) private var journalEntries: [JournalEntry]
    
    @State private var exportFormat: ExportFormat = .json
    @State private var isExporting = false
    @State private var showSuccess = false
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case markdown = "Markdown"
        case csv = "CSV"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Data")
                .font(.title)
                .fontWeight(.bold)
            
            // Stats
            VStack(alignment: .leading, spacing: 8) {
                Label("\(habits.count) Habits", systemImage: "list.bullet")
                Label("\(totalCompletions()) Completions", systemImage: "checkmark.circle")
                Label("\(journalEntries.count) Journal Entries", systemImage: "book.fill")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Format selection
            Picker("Format", selection: $exportFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Preview
            VStack(alignment: .leading) {
                Text("Preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ScrollView {
                    Text(previewContent())
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(height: 150)
            .padding(.horizontal)
            
            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(action: exportData) {
                    if isExporting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Export", systemImage: "square.and.arrow.down")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isExporting)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 450)
        .alert("Export Successful", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your data has been exported to Downloads folder.")
        }
    }
    
    private func totalCompletions() -> Int {
        habits.reduce(0) { count, habit in
            count + (habit.completions?.filter { $0.completed }.count ?? 0)
        }
    }
    
    private func previewContent() -> String {
        switch exportFormat {
        case .json:
            return """
            {
              "habits": [\(habits.count) items],
              "journal": [\(journalEntries.count) entries],
              "exported_at": "\(ISO8601DateFormatter().string(from: Date()))"
            }
            """
        case .markdown:
            return """
            # MindGrowee Export
            
            ## Habits (\(habits.count))
            - Habit 1
            - Habit 2
            ...
            
            ## Journal Entries (\(journalEntries.count))
            """
        case .csv:
            return """
            date,habit,completed
            2026-01-31,Exercise,true
            2026-01-31,Read,false
            ...
            """
        }
    }
    
    private func exportData() {
        isExporting = true
        
        let content: String
        let filename: String
        
        switch exportFormat {
        case .json:
            content = exportAsJSON()
            filename = "mindgrowee_export_\(dateString()).json"
        case .markdown:
            content = exportAsMarkdown()
            filename = "mindgrowee_export_\(dateString()).md"
        case .csv:
            content = exportAsCSV()
            filename = "mindgrowee_export_\(dateString()).csv"
        }
        
        // Save to Downloads
        if let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let fileURL = downloadsURL.appendingPathComponent(filename)
            
            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                showSuccess = true
            } catch {
                Logger.shared.error("Failed to export", error: error)
            }
        }
        
        isExporting = false
    }
    
    private func exportAsJSON() -> String {
        var habitsData: [[String: Any]] = []
        
        for habit in habits {
            var habitDict: [String: Any] = [
                "id": habit.id.uuidString,
                "title": habit.title,
                "icon": habit.icon,
                "color": habit.color,
                "created_at": ISO8601DateFormatter().string(from: habit.createdAt)
            ]
            
            var completionsData: [[String: Any]] = []
            for completion in habit.completions ?? [] {
                completionsData.append([
                    "date": ISO8601DateFormatter().string(from: completion.date),
                    "completed": completion.completed
                ])
            }
            habitDict["completions"] = completionsData
            habitsData.append(habitDict)
        }
        
        var entriesData: [[String: Any]] = []
        for entry in journalEntries {
            entriesData.append([
                "id": entry.id.uuidString,
                "date": ISO8601DateFormatter().string(from: entry.date),
                "content": entry.content,
                "mood": entry.mood,
                "tags": entry.tags
            ])
        }
        
        let exportData: [String: Any] = [
            "export_date": ISO8601DateFormatter().string(from: Date()),
            "app_version": "1.0",
            "habits": habitsData,
            "journal_entries": entriesData
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    private func exportAsMarkdown() -> String {
        var md = """
        # MindGrowee Export
        
        **Exported:** \(Date().formatted(date: .long, time: .shortened))\n        
        ---
        
        ## Habits (\(habits.count))
        
        """
        
        for habit in habits {
            md += "### \(habit.icon) \(habit.title)\n\n"
            md += "- Created: \(habit.createdAt.formatted(date: .long, time: .omitted))\n"
            
            let completedCount = habit.completions?.filter { $0.completed }.count ?? 0
            md += "- Total Completions: \(completedCount)\n\n"
        }
        
        md += """
        ---
        
        ## Journal Entries (\(journalEntries.count))
        
        """
        
        for entry in journalEntries {
            md += "### \(entry.date.formatted(date: .long, time: .shortened))\n\n"
            md += "**Mood:** \(String(repeating: "⭐", count: entry.mood))\n\n"
            if !entry.tags.isEmpty {
                md += "**Tags:** \(entry.tags.joined(separator: ", "))\n\n"
            }
            md += "\(entry.content)\n\n---\n\n"
        }
        
        return md
    }
    
    private func exportAsCSV() -> String {
        var csv = "date,habit_id,habit_title,completed\n"
        
        for habit in habits {
            for completion in habit.completions ?? [] {
                let date = ISO8601DateFormatter().string(from: completion.date)
                let completed = completion.completed ? "true" : "false"
                csv += "\(date),\(habit.id.uuidString),\"\(habit.title)\",\(completed)\n"
            }
        }
        
        return csv
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
