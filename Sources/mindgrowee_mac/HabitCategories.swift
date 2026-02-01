import SwiftUI
import SwiftData

// MARK: - Habit Extension

extension Habit {
    func getCategory(context: ModelContext) -> HabitCategory? {
        guard let categoryId = categoryId else { return nil }
        let descriptor = FetchDescriptor<HabitCategory>(predicate: #Predicate { $0.id == categoryId })
        return try? context.fetch(descriptor).first
    }
    
    func setCategory(_ category: HabitCategory?) {
        self.categoryId = category?.id
    }
}

// MARK: - Category Manager

@MainActor
class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    
    let defaultCategories: [(name: String, icon: String, color: String)] = [
        ("Health", "heart.fill", "red"),
        ("Fitness", "figure.walk", "green"),
        ("Productivity", "checkmark.circle.fill", "blue"),
        ("Learning", "book.fill", "purple"),
        ("Mindfulness", "moon.fill", "indigo"),
        ("Social", "person.2.fill", "orange"),
        ("Creative", "paintbrush.fill", "pink"),
        ("Finance", "dollarsign.circle.fill", "green")
    ]
    
    func createDefaultCategories(context: ModelContext) {
        let descriptor = FetchDescriptor<HabitCategory>()
        
        do {
            let existing = try context.fetch(descriptor)
            guard existing.isEmpty else { return }
            
            for (index, category) in defaultCategories.enumerated() {
                let newCategory = HabitCategory(
                    name: category.name,
                    icon: category.icon,
                    color: category.color,
                    sortOrder: index
                )
                context.insert(newCategory)
            }
        } catch {
            Logger.shared.error("Failed to create default categories", error: error)
        }
    }
}

// MARK: - Category Selection View

struct CategorySelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \HabitCategory.sortOrder) private var categories: [HabitCategory]
    
    let habit: Habit
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("No Category") {
                        habit.setCategory(nil)
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }
                
                Section("Categories") {
                    ForEach(categories) { category in
                        Button(action: {
                            habit.setCategory(category)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(colorFor(category.color))
                                    .frame(width: 30)
                                
                                Text(category.name)
                                
                                Spacer()
                                
                                if habit.categoryId == category.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Select Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
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
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

// MARK: - Category Filter View

struct CategoryFilterView: View {
    @Query(sort: \HabitCategory.sortOrder) private var categories: [HabitCategory]
    
    @Binding var selectedCategory: HabitCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All button
                FilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                }
                
                ForEach(categories) { category in
                    FilterChip(
                        title: category.name,
                        icon: category.icon,
                        isSelected: selectedCategory?.id == category.id,
                        color: colorFor(category.color)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
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
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundStyle(isSelected ? color : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
