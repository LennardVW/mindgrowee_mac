import SwiftUI
import SwiftData

// MARK: - Projects List View

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    
    @State private var showingNewProject = false
    @State private var selectedProject: Project?
    
    var body: some View {
        List {
            ForEach(projects) { project in
                ProjectRow(project: project)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProject = project
                    }
            }
            .onDelete(perform: deleteProject)
        }
        .listStyle(.inset)
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem {
                Button(action: { showingNewProject = true }) {
                    Label("New Project", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectView()
        }
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(project: project)
        }
    }
    
    private func deleteProject(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            
            switch modelContext.safeDelete(project) {
            case .success:
                Logger.shared.info("Deleted project: \(project.name)")
            case .failure(let error):
                Logger.shared.error("Failed to delete project", error: error)
            }
        }
    }
}

// MARK: - Project Row

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: project.icon)
                    .font(.title2)
                    .foregroundStyle(colorFor(project.color))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.headline)
                    
                    if !project.projectDescription.isEmpty {
                        Text(project.projectDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Status badge
                if project.isCompleted {
                    Text("Completed")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                } else if let days = project.daysUntilDeadline, days < 0 {
                    Text("Overdue")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorFor(project.color))
                            .frame(width: max(0, geometry.size.width * project.completionPercentage), height: 6)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(Int(project.completionPercentage * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if let days = project.daysUntilDeadline {
                        if days > 0 {
                            Text("\(days) days left")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if days == 0 {
                            Text("Due today")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    if let habits = project.habits, !habits.isEmpty {
                        Text("\(habits.count) habits")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorFor(_ colorName: String) -> Color {
        switch colorName {
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
}

// MARK: - New Project View

struct NewProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "folder"
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
    @State private var useTemplate: ProjectTemplate?
    
    private let colors = ["red", "orange", "yellow", "green", "blue", "purple", "pink"]
    private let icons = ["folder", "star", "heart", "bolt", "flame", "target", "flag", "checkmark.circle"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text("New Project")
                    .font(.headline)
                Spacer()
                Button("Create") { createProject() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()

            Form {
                Section("Project Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Appearance") {
                    // Icon picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .foregroundStyle(selectedIcon == icon ? .blue : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Color picker
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(colorFor(color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.gray : Color.clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Deadline") {
                    Toggle("Set Deadline", isOn: $hasDeadline)

                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                    }
                }

                Section("Templates") {
                    ForEach(ProjectTemplate.templates, id: \.name) { template in
                        Button(action: {
                            useTemplate = template
                            name = template.name
                            description = template.description
                            selectedIcon = template.icon
                            selectedColor = template.color
                        }) {
                            HStack {
                                Image(systemName: template.icon)
                                    .foregroundStyle(colorFor(template.color))
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                        .font(.subheadline)
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if useTemplate?.name == template.name {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 600)
    }
    
    private func createProject() {
        let projectDeadline = hasDeadline ? deadline : nil
        
        let result = ProjectManager.shared.createProject(
            name: name,
            description: description,
            color: selectedColor,
            icon: selectedIcon,
            deadline: projectDeadline,
            context: modelContext
        )
        
        switch result {
        case .success(let project):
            Logger.shared.info("Created project: \(project.name)")
            
            // Create habits from template if selected
            if let template = useTemplate {
                for habitName in template.defaultHabits {
                    let habit = Habit(
                        title: habitName,
                        icon: "checkmark",
                        color: selectedColor,
                        project: project
                    )
                    _ = modelContext.safeInsert(habit)
                }
                
                // Create milestones from template
                for (index, milestoneTitle) in template.milestones.enumerated() {
                    let milestone = Milestone(
                        title: milestoneTitle,
                        order: index
                    )
                    milestone.project = project
                    modelContext.insert(milestone)
                }
            }
            
            dismiss()
        case .failure(let error):
            Logger.shared.error("Failed to create project", error: error)
        }
    }
    
    private func colorFor(_ colorName: String) -> Color {
        switch colorName {
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
}

// MARK: - Project Detail View

struct ProjectDetailView: View {
    let project: Project
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text(project.name)
                    .font(.headline)
                Spacer()
            }
            .padding()

            List {
                // Progress section
                Section {
                    VStack(spacing: 16) {
                        CircularProgressView(
                            progress: project.completionPercentage,
                            color: colorFor(project.color)
                        )
                        .frame(width: 120, height: 120)

                        Text("\(Int(project.completionPercentage * 100))% Complete")
                            .font(.title2)
                            .fontWeight(.bold)

                        if let days = project.daysUntilDeadline {
                            if days > 0 {
                                Text("\(days) days until deadline")
                                    .foregroundStyle(.secondary)
                            } else if days == 0 {
                                Text("Due today!")
                                    .foregroundStyle(.orange)
                                    .fontWeight(.semibold)
                            } else {
                                Text("Overdue by \(-days) days")
                                    .foregroundStyle(.red)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                }

                // Habits section
                if let habits = project.habits, !habits.isEmpty {
                    Section("Habits") {
                        ForEach(habits) { habit in
                            ProjectHabitRow(habit: habit)
                        }
                    }
                }

                // Milestones section
                if let milestones = project.milestones, !milestones.isEmpty {
                    Section("Milestones") {
                        ForEach(milestones.sorted(by: { $0.order < $1.order })) { milestone in
                            MilestoneRow(milestone: milestone)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
        .frame(width: 500, height: 600)
    }
    
    private func colorFor(_ colorName: String) -> Color {
        switch colorName {
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
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

// MARK: - Project Habit Row

struct ProjectHabitRow: View {
    let habit: Habit
    
    var body: some View {
        HStack {
            Image(systemName: habit.icon)
                .foregroundStyle(colorFor(habit.color))
            
            Text(habit.title)
            
            Spacer()
            
            if habit.isCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.gray)
            }
        }
    }
    
    private func colorFor(_ colorName: String) -> Color {
        switch colorName {
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
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: Milestone
    
    var body: some View {
        HStack {
            Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(milestone.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading) {
                Text(milestone.title)
                    .strikethrough(milestone.isCompleted)
                
                if let targetDate = milestone.targetDate {
                    Text(targetDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
}
