import SwiftUI
import CoreData

struct HabitDetailView: View {
    @ObservedObject var habit: Item
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: HabitViewModel
    @State private var showingDeleteAlert = false
    
    init(habit: Item) {
        self.habit = habit
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: HabitViewModel(context: context))
    }
    
    var body: some View {
        ZStack {
            Color(hex: "1A1D23").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 16) {
                        Image(systemName: habit.iconName ?? "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: habit.colorHex ?? "FF6B35"))
                        
                        Text(habit.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 30) {
                            StatBubble(icon: "flame.fill", value: "\(habit.streakCurrent)", label: "Current", color: .orange)
                            StatBubble(icon: "trophy.fill", value: "\(habit.streakRecord)", label: "Record", color: .yellow)
                            StatBubble(icon: "star.fill", value: "Lv \(habit.level)", label: "Level", color: Color(hex: "4A90E2"))
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(hex: habit.colorHex ?? "FF6B35").opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    
                    // Heatmap Calendar
                    VStack(alignment: .leading, spacing: 12) {
                        Text("365-Day Streak")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HabitHeatmap(completionData: viewModel.getCompletionData(for: habit))
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    
                    // Quick Actions
                    HStack(spacing: 16) {
                        ActionButton(icon: "checkmark.circle.fill", label: "Mark Today", color: Color(hex: "27AE60")) {
                            habit.toggleCompletion()
                            PersistenceController.shared.save()
                        }
                        
                        ActionButton(icon: "bell.fill", label: "Reminder", color: Color(hex: "4A90E2")) {
                            // Open reminder settings
                        }
                    }
                    
                    // Recent History
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        ForEach(habit.completedDates.sorted(by: >).prefix(10), id: \.self) { date in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "27AE60"))
                                
                                Text(formattedDate(date))
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    
                    // Delete Button
                    Button(action: { showingDeleteAlert = true }) {
                        Text("Delete Habit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Habit"),
                message: Text("Are you sure? All progress will be lost."),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteHabit(habit)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct StatBubble: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(16)
        }
    }
}

struct HabitHeatmap: View {
    let completionData: [Date: Bool]
    
    private let columns = 53 // weeks in a year
    private let cellSize: CGFloat = 12
    private let spacing: CGFloat = 3
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 7), spacing: spacing) {
                ForEach(sortedDates(), id: \.self) { date in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForDate(date))
                        .frame(width: cellSize, height: cellSize)
                }
            }
            .padding(.vertical)
        }
    }
    
    func sortedDates() -> [Date] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -364, to: endDate)!
        
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
    
    func colorForDate(_ date: Date) -> Color {
        if completionData[Calendar.current.startOfDay(for: date)] == true {
            return Color(hex: "27AE60")
        }
        return Color.gray.opacity(0.2)
    }
}

// Views/TasksView.swift
import SwiftUI

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.dueDate, ascending: true)],
        predicate: NSPredicate(format: "typeRaw == %@", ItemType.task.rawValue)
    ) var tasks: FetchedResults<Item>
    
    @State private var showingAddSheet = false
    @State private var selectedFilter: TaskFilter = .all
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case tomorrow = "Tomorrow"
        case overdue = "Overdue"
        case noDate = "No Date"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    withAnimation {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(Color(hex: "2C3E50").opacity(0.5))
                    
                    // Tasks List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTasks) { task in
                                TaskCard(task: task)
                            }
                        }
                        .padding()
                    }
                }
                
                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color(hex: "4A90E2"))
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        .padding(30)
                    }
                }
            }
            .navigationTitle("Tasks")
            .sheet(isPresented: $showingAddSheet) {
                AddTaskSheet()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    var filteredTasks: [Item] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedFilter {
        case .all:
            return Array(tasks)
        case .today:
            return tasks.filter { task in
                guard let date = task.dueDate else { return false }
                return calendar.isDateInToday(date)
            }
        case .tomorrow:
            return tasks.filter { task in
                guard let date = task.dueDate else { return false }
                return calendar.isDateInTomorrow(date)
            }
        case .overdue:
            return tasks.filter { task in
                guard let date = task.dueDate else { return false }
                return date < now && !calendar.isDateInToday(date)
            }
        case .noDate:
            return tasks.filter { $0.dueDate == nil }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "FF6B35") : Color.white.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct TaskCard: View {
    @ObservedObject var task: Item
    
    var body: some View {
        HStack(spacing: 16) {
            // Priority indicator
            Rectangle()
                .fill(Color(hex: task.priority.color))
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(formattedDate(dueDate))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(isOverdue(dueDate) ? .red : .gray)
                }
                
                if !task.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(task.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "4A90E2"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "4A90E2").opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !Calendar.current.isDateInToday(date)
    }
}

// Views/ChecklistsView.swift
import SwiftUI

struct ChecklistsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.createdAt, ascending: false)],
        predicate: NSPredicate(format: "typeRaw == %@ AND isTemplate == false", ItemType.checklist.rawValue)
    ) var userChecklists: FetchedResults<Item>
    
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.title, ascending: true)],
        predicate: NSPredicate(format: "typeRaw == %@ AND isTemplate == true", ItemType.checklist.rawValue)
    ) var templates: FetchedResults<Item>
    
    @State private var showingTemplates = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Templates Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Templates")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: { withAnimation { showingTemplates.toggle() } }) {
                                    Image(systemName: showingTemplates ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            if showingTemplates {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(templates) { template in
                                        TemplateCard(template: template) {
                                            createChecklistFromTemplate(template)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // User Checklists
                        VStack(alignment: .leading, spacing: 16) {
                            Text("My Checklists")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            if userChecklists.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "list.bullet.clipboard")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    
                                    Text("No checklists yet")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                    
                                    Text("Start from a template above")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(userChecklists) { checklist in
                                    ChecklistCard(checklist: checklist)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Checklists")
        }
    }
    
    func createChecklistFromTemplate(_ template: Item) {
        let newChecklist = Item(context: viewContext)
        newChecklist.id = UUID()
        newChecklist.title = template.title
        newChecklist.type = .checklist
        newChecklist.subtasks = template.subtasks.map { Subtask(title: $0.title, completed: false) }
        newChecklist.iconName = template.iconName
        newChecklist.colorHex = template.colorHex
        newChecklist.createdAt = Date()
        newChecklist.dueDate = Date()
        newChecklist.isTemplate = false
        newChecklist.repeatRule = .none
        newChecklist.priority = .medium
        
        PersistenceController.shared.save()
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }
}

struct TemplateCard: View {
    let template: Item
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: template.iconName ?? "list.bullet")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: template.colorHex ?? "4A90E2"))
                
                Text(template.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Text("\(template.subtasks.count) items")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color(hex: template.colorHex ?? "4A90E2").opacity(0.2), Color.white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
    }
}

struct ChecklistCard: View {
    @ObservedObject var checklist: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: checklist.iconName ?? "list.bullet")
                    .foregroundColor(Color(hex: checklist.colorHex ?? "4A90E2"))
                
                Text(checklist.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(completedCount)/\(checklist.subtasks.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: Double(completedCount), total: Double(checklist.subtasks.count))
                .tint(Color(hex: "27AE60"))
            
            ForEach(checklist.subtasks.indices, id: \.self) { index in
                HStack {
                    Button(action: {
                        var subtasks = checklist.subtasks
                        subtasks[index].completed.toggle()
                        checklist.subtasks = subtasks
                        PersistenceController.shared.save()
                    }) {
                        Image(systemName: checklist.subtasks[index].completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(checklist.subtasks[index].completed ? Color(hex: "27AE60") : .gray)
                    }
                    
                    Text(checklist.subtasks[index].title)
                        .font(.system(size: 14))
                        .foregroundColor(checklist.subtasks[index].completed ? .gray : .white)
                        .strikethrough(checklist.subtasks[index].completed)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    var completedCount: Int {
        checklist.subtasks.filter { $0.completed }.count
    }
}

// Views/JournalView.swift
import SwiftUI

struct JournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var selectedMood: Int?
    @State private var selectedEnergy: Int = 5
    @State private var sleepHours: String = "7.5"
    @State private var notes: String = ""
    @State private var showingStats = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Calendar Heatmap
                        MoodCalendarView(entries: viewModel.entries)
                            .padding(.horizontal)
                        
                        // Today's Entry
                        VStack(alignment: .leading, spacing: 20) {
                            Text("How was your day?")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Mood Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Mood")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 16) {
                                    ForEach(1...5, id: \.self) { mood in
                                        MoodButton(mood: mood, isSelected: selectedMood == mood) {
                                            selectedMood = mood
                                        }
                                    }
                                }
                            }
                            
                            // Energy Slider
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Energy Level")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    Text("\(selectedEnergy)/10")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(hex: "FFD700"))
                                }
                                
                                Slider(value: Binding(
                                    get: { Double(selectedEnergy) },
                                    set: { selectedEnergy = Int($0) }
                                ), in: 1...10, step: 1)
                                    .accentColor(Color(hex: "FFD700"))
                            }
                            
                            // Sleep Hours
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sleep (hours)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                TextField("7.5", text: $sleepHours)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            // Notes
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                TextEditor(text: $notes)
                                    .frame(height: 120)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            // Save Button
                            Button(action: saveEntry) {
                                Text("Save Entry")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [Color(hex: "E74C3C"), Color(hex: "C0392B")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                            }
                            .disabled(selectedMood == nil)
                            .opacity(selectedMood == nil ? 0.5 : 1.0)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // Stats Button
                        Button(action: { showingStats = true }) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                Text("View Statistics")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "4A90E2"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "4A90E2").opacity(0.2))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Journal")
            .sheet(isPresented: $showingStats) {
                JournalStatsView(viewModel: viewModel)
            }
            .onAppear {
                loadTodayEntry()
            }
        }
    }
    
    func loadTodayEntry() {
        if let entry = viewModel.currentEntry {
            selectedMood = entry.mood
            selectedEnergy = entry.energy
            sleepHours = String(format: "%.1f", entry.sleepHours)
            notes = entry.notes
        }
    }
    
    func saveEntry() {
        guard let mood = selectedMood else { return }
        
        viewModel.saveEntry(
            mood: mood,
            energy: selectedEnergy,
            sleepHours: Double(sleepHours) ?? 7.5,
            notes: notes
        )
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }
}

struct MoodButton: View {
    let mood: Int
    let isSelected: Bool
    let action: () -> Void
    
    var emoji: String {
        switch mood {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😄"
        default: return "😐"
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 36))
                .frame(width: 60, height: 60)
                .background(isSelected ? Color(hex: "FF6B35").opacity(0.3) : Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color(hex: "FF6B35") : Color.clear, lineWidth: 2)
                )
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct MoodCalendarView: View {
    let entries: [MoodEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Month")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<30, id: \.self) { index in
                    let date = Calendar.current.date(byAdding: .day, value: -29 + index, to: Date())!
                    let entry = entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForMood(entry?.mood))
                        .frame(height: 40)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    func colorForMood(_ mood: Int?) -> Color {
        guard let mood = mood else { return Color.gray.opacity(0.2) }
        
        switch mood {
        case 1: return Color(hex: "E74C3C")
        case 2: return Color(hex: "E67E22")
        case 3: return Color(hex: "F39C12")
        case 4: return Color(hex: "2ECC71")
        case 5: return Color(hex: "27AE60")
        default: return Color.gray
        }
    }
}

struct JournalStatsView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Average Mood
                        StatCard(
                            title: "Average Mood (7 days)",
                            value: String(format: "%.1f", viewModel.averageMood(days: 7)),
                            icon: "heart.fill",
                            color: Color(hex: "E74C3C")
                        )
                        
                        // High Energy Days
                        StatCard(
                            title: "High Energy Days",
                            value: "\(viewModel.highEnergyDays(threshold: 7))",
                            icon: "bolt.fill",
                            color: Color(hex: "FFD700")
                        )
                        
                        // Total Entries
                        StatCard(
                            title: "Total Entries",
                            value: "\(viewModel.entries.count)",
                            icon: "book.fill",
                            color: Color(hex: "4A90E2")
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistics")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Add Item Sheets

struct AddItemSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedType: ItemType?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("What would you like to add?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        AddTypeButton(
                            icon: "chart.bar.fill",
                            title: "Habit",
                            description: "Recurring activity",
                            color: Color(hex: "27AE60")
                        ) {
                            selectedType = .habit
                        }
                        
                        AddTypeButton(
                            icon: "checklist",
                            title: "Task",
                            description: "One-time action",
                            color: Color(hex: "4A90E2")
                        ) {
                            selectedType = .task
                        }
                        
                        AddTypeButton(
                            icon: "list.bullet.clipboard",
                            title: "Checklist",
                            description: "Multiple steps",
                            color: Color(hex: "9B59B6")
                        ) {
                            selectedType = .checklist
                        }
                        
                        AddTypeButton(
                            icon: "note.text",
                            title: "Note",
                            description: "Quick thought",
                            color: Color(hex: "E67E22")
                        ) {
                            selectedType = .note
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(item: $selectedType) { type in
            getDetailSheet(for: type)
        }
    }
    
    @ViewBuilder
    func getDetailSheet(for type: ItemType) -> some View {
        switch type {
        case .habit:
            AddHabitSheet(viewModel: HabitViewModel(context: PersistenceController.shared.container.viewContext))
        case .task:
            AddTaskSheet()
        default:
            Text("Coming soon")
        }
    }
}

extension ItemType: Identifiable {
    var id: String { rawValue }
}

struct AddTypeButton: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
    }
}

struct AddHabitSheet: View {
    @ObservedObject var viewModel: HabitViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "FF6B35"
    @State private var selectedRepeat: RepeatRule = .daily
    
    let icons = ["star.fill", "flame.fill", "heart.fill", "bolt.fill", "moon.fill", "sun.max.fill", "leaf.fill", "drop.fill"]
    let colors = ["FF6B35", "27AE60", "4A90E2", "9B59B6", "E74C3C", "F39C12", "1ABC9C", "E67E22"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Habit Name")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            TextField("e.g., Morning meditation", text: $title)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Icon")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                ForEach(icons, id: \.self) { icon in
                                    IconButton(icon: icon, isSelected: selectedIcon == icon) {
                                        selectedIcon = icon
                                    }
                                }
                            }
                        }
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                ForEach(colors, id: \.self) { color in
                                    ColorButton(color: color, isSelected: selectedColor == color) {
                                        selectedColor = color
                                    }
                                }
                            }
                        }
                        
                        // Repeat Rule
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Frequency")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Picker("Repeat", selection: $selectedRepeat) {
                                Text("Daily").tag(RepeatRule.daily)
                                Text("Weekdays").tag(RepeatRule.weekdays)
                                Text("Every Other Day").tag(RepeatRule.everyOtherDay)
                                Text("3x per Week").tag(RepeatRule.threeTimesWeek)
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Create Button
                        Button(action: createHabit) {
                            Text("Create Habit")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "27AE60"), Color(hex: "2ECC71")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.5 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Habit")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func createHabit() {
        viewModel.createHabit(title: title, icon: selectedIcon, color: selectedColor, repeatRule: selectedRepeat)
        presentationMode.wrappedValue.dismiss()
    }
}

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(width: 60, height: 60)
                .background(isSelected ? Color(hex: "FF6B35") : Color.white.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

struct ColorButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
        }
    }
}

struct AddTaskSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var selectedPriority: Priority = .medium
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Name")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            TextField("e.g., Finish presentation", text: $title)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Priority
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Priority")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                ForEach(Priority.allCases, id: \.self) { priority in
                                    PriorityButton(priority: priority, isSelected: selectedPriority == priority) {
                                        selectedPriority = priority
                                    }
                                }
                            }
                        }
                        
                        // Due Date
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Set due date", isOn: $hasDueDate)
                                .foregroundColor(.white)
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "4A90E2")))
                            
                            if hasDueDate {
                                DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .foregroundColor(.white)
                                    .accentColor(Color(hex: "4A90E2"))
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (optional)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Create Button
                        Button(action: createTask) {
                            Text("Create Task")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "4A90E2"))
                                .cornerRadius(16)
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.5 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Task")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func createTask() {
        let task = Item(context: viewContext)
        task.id = UUID()
        task.title = title
        task.type = .task
        task.notes = notes.isEmpty ? nil : notes
        task.dueDate = hasDueDate ? dueDate : nil
        task.priority = selectedPriority
        task.createdAt = Date()
        task.repeatRule = .none
        
        PersistenceController.shared.save()
        presentationMode.wrappedValue.dismiss()
    }
}

struct PriorityButton: View {
    let priority: Priority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(priority.rawValue.capitalized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: priority.color) : Color.white.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

// MARK: - Core Data Model Definition

extension Item {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }
}

import WebKit

struct BiteWebView: View {
    @State private var targetURL: String? = ""
    @State private var ready = false
    
    var body: some View {
        ZStack {
            if ready, let url = targetURL, let destination = URL(string: url) {
                WebViewWrapper(url: destination).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { setup() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func setup() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let saved = UserDefaults.standard.string(forKey: "fb_resource_url") ?? ""
        targetURL = temp ?? saved
        ready = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            ready = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { ready = true }
        }
    }
}

struct WebViewWrapper: UIViewRepresentable {
    let url: URL
    
    func makeCoordinator() -> WebCoordinator { WebCoordinator() }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = buildWebView(coordinator: context.coordinator)
        context.coordinator.webView = webView
        context.coordinator.navigate(to: url, in: webView)
        Task { await context.coordinator.loadCookies(in: webView) }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func buildWebView(coordinator: WebCoordinator) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        let controller = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body { touch-action: pan-x pan-y; -webkit-user-select: none; } input, textarea { font-size: 16px !important; }`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        controller.addUserScript(script)
        config.userContentController = controller
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

final class WebCoordinator: NSObject {
    weak var webView: WKWebView?
    
    private var redirects = 0
    private var redirectMax = 70
    private var lastURL: URL?
    private var trail: [URL] = []
    private var anchor: URL?
    private var windows: [WKWebView] = []
    private let cookieKey = "bite_cookies"
    
    func navigate(to url: URL, in webView: WKWebView) {
        print("🍔 [Bite] Navigate: \(url.absoluteString)")
        trail = [url]
        redirects = 0
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(req)
    }
    
    func loadCookies(in webView: WKWebView) {
        guard let data = UserDefaults.standard.object(forKey: cookieKey) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let store = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = data.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { store.setCookie($0) }
    }
    
    func saveCookies(from webView: WKWebView) {
        let store = webView.configuration.websiteDataStore.httpCookieStore
        store.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var data: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domain = data[cookie.domain] ?? [:]
                if let props = cookie.properties { domain[cookie.name] = props }
                data[cookie.domain] = domain
            }
            UserDefaults.standard.set(data, forKey: self.cookieKey)
        }
    }
}

extension WebCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        lastURL = url
        if shouldAllow(url) {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    private func shouldAllow(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let schemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let special = ["srcdoc", "about:blank", "about:srcdoc"]
        return schemes.contains(scheme) || special.contains { path.hasPrefix($0) } || path == "about:blank"
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirects += 1
        if redirects > redirectMax {
            webView.stopLoading()
            if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
            redirects = 0
            return
        }
        lastURL = webView.url
        saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url {
            anchor = current
            print("✅ [Bite] Commit: \(current.absoluteString)")
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { anchor = current }
        redirects = 0
        saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let code = (error as NSError).code
        if code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL {
            webView.load(URLRequest(url: recovery))
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension WebCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let window = WKWebView(frame: webView.bounds, configuration: configuration)
        window.navigationDelegate = self
        window.uiDelegate = self
        window.allowsBackForwardNavigationGestures = true
        webView.addSubview(window)
        window.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            window.topAnchor.constraint(equalTo: webView.topAnchor),
            window.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            window.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            window.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(closeWindow(_:)))
        gesture.edges = .left
        window.addGestureRecognizer(gesture)
        windows.append(window)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            window.load(navigationAction.request)
        }
        return window
    }
    
    @objc private func closeWindow(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        if let last = windows.last {
            last.removeFromSuperview()
            windows.removeLast()
        } else {
            webView?.goBack()
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
