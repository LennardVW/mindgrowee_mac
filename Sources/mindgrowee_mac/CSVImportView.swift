import SwiftUI
import SwiftData

// MARK: - CSV Import View

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var csvText = ""
    @State private var showingFilePicker = false
    @State private var parseResult: CSVParseResult?
    @State private var showingResult = false
    @State private var previewData: [CSVHabitPreview] = []
    
    enum CSVParseResult {
        case success(habits: Int)
        case error(message: String)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Import from CSV")
                .font(.title)
                .fontWeight(.bold)
            
            Text("CSV format: date,habit_name,completed(true/false)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Example
            VStack(alignment: .leading) {
                Text("Example:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("""
                2026-01-31,Exercise,true
                2026-01-31,Meditation,false
                2026-01-30,Exercise,true
                """)
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            TextEditor(text: $csvText)
                .font(.system(.body, design: .monospaced))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            // Preview
            if !previewData.isEmpty {
                VStack(alignment: .leading) {
                    Text("Preview (first 5):")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    List(previewData.prefix(5)) { item in
                        HStack {
                            Text(item.date)
                                .font(.caption)
                            Text(item.habitName)
                                .font(.caption)
                            Spacer()
                            Image(systemName: item.completed ? "checkmark" : "xmark")
                                .foregroundStyle(item.completed ? .green : .red)
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 100)
                }
            }
            
            HStack {
                Button("Choose File...") {
                    showingFilePicker = true
                }
                
                Spacer()
                
                Button("Preview") {
                    previewCSV()
                }
                .disabled(csvText.isEmpty)
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Import") {
                    importFromCSV()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(csvText.isEmpty || previewData.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 550, height: 550)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.plainText, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    do {
                        csvText = try String(contentsOf: url, encoding: .utf8)
                        previewCSV()
                    } catch {
                        parseResult = .error(message: "Failed to read file: \(error.localizedDescription)")
                        showingResult = true
                    }
                }
            case .failure(let error):
                parseResult = .error(message: "Failed to select file: \(error.localizedDescription)")
                showingResult = true
            }
        }
        .alert("Import Result", isPresented: $showingResult) {
            Button("OK") {
                if case .success = parseResult {
                    dismiss()
                }
            }
        } message: {
            switch parseResult {
            case .success(let count):
                Text("Successfully imported \(count) habit entries.")
            case .error(let message):
                Text(message)
            case .none:
                Text("")
            }
        }
    }
    
    private func previewCSV() {
        previewData = parseCSVPreview(csvText)
    }
    
    private func importFromCSV() {
        let lines = csvText.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var importedCount = 0
        
        for line in lines {
            let components = line.components(separatedBy: ",")
            guard components.count >= 3 else { continue }
            
            let dateString = components[0].trimmingCharacters(in: .whitespaces)
            let habitName = components[1].trimmingCharacters(in: .whitespaces)
            let completedString = components[2].trimmingCharacters(in: .whitespaces).lowercased()
            
            // Parse date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            guard let date = dateFormatter.date(from: dateString) else { continue }
            let completed = completedString == "true" || completedString == "1" || completedString == "yes"
            
            // Find or create habit
            let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.title == habitName })
            
            do {
                let existingHabits = try modelContext.fetch(descriptor)
                let habit: Habit
                
                if let existing = existingHabits.first {
                    habit = existing
                } else {
                    habit = Habit(title: habitName, icon: "checkmark", color: "blue")
                    modelContext.insert(habit)
                }
                
                // Check if completion already exists
                let completionExists = habit.completions?.contains { completion in
                    Calendar.current.isDate(completion.date, inSameDayAs: date)
                } ?? false
                
                if !completionExists {
                    let completion = DailyCompletion(date: date, completed: completed, habit: habit)
                    modelContext.insert(completion)
                    importedCount += 1
                }
            } catch {
                Logger.shared.error("Failed to import CSV line", error: error)
            }
        }
        
        parseResult = .success(habits: importedCount)
        showingResult = true
    }
    
    private func parseCSVPreview(_ csv: String) -> [CSVHabitPreview] {
        var previews: [CSVHabitPreview] = []
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        for (index, line) in lines.enumerated() {
            let components = line.components(separatedBy: ",")
            guard components.count >= 3 else { continue }
            
            let dateString = components[0].trimmingCharacters(in: .whitespaces)
            let habitName = components[1].trimmingCharacters(in: .whitespaces)
            let completedString = components[2].trimmingCharacters(in: .whitespaces).lowercased()
            
            let completed = completedString == "true" || completedString == "1" || completedString == "yes"
            
            previews.append(CSVHabitPreview(
                id: index,
                date: dateString,
                habitName: habitName,
                completed: completed
            ))
        }
        
        return previews
    }
}

// MARK: - CSV Habit Preview

struct CSVHabitPreview: Identifiable {
    let id: Int
    let date: String
    let habitName: String
    let completed: Bool
}
