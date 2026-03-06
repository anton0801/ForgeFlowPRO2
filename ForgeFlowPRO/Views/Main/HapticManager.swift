import Foundation
import CoreData
import SwiftUI
import UIKit

extension UserDefaults {
    
    static var userName: String {
        get { standard.string(forKey: "userName") ?? "there" }
        set { standard.set(newValue, forKey: "userName") }
    }
    
    static var hasCompletedOnboarding: Bool {
        get { standard.bool(forKey: "hasCompletedOnboarding") }
        set { standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    static var hasSeededTemplates: Bool {
        get { standard.bool(forKey: "hasSeededTemplates") }
        set { standard.set(newValue, forKey: "hasSeededTemplates") }
    }
    
    static var isDarkMode: Bool {
        get { standard.bool(forKey: "isDarkMode") }
        set { standard.set(newValue, forKey: "isDarkMode") }
    }
    
    static var iCloudSyncEnabled: Bool {
        get { standard.bool(forKey: "iCloudSyncEnabled") }
        set { standard.set(newValue, forKey: "iCloudSyncEnabled") }
    }
}

// MARK: - Date Extensions

extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self.startOfDay(), to: date.startOfDay())
        return abs(components.day ?? 0)
    }
    
    func isInLast(_ days: Int) -> Bool {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return false }
        return self >= startDate
    }
}

// MARK: - View Extensions

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
    }
}

// MARK: - Haptic Feedback Helper

struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Animation Helpers

extension Animation {
    static var smoothSpring: Animation {
        .interpolatingSpring(stiffness: 200, damping: 15)
    }
    
    static var bounceSpring: Animation {
        .interpolatingSpring(stiffness: 300, damping: 10)
    }
}

extension View {
    func accessibleLabel(_ label: String) -> some View {
        self.accessibilityLabel(Text(label))
    }
    
    func accessibleHint(_ hint: String) -> some View {
        self.accessibilityHint(Text(hint))
    }
    
    func accessibleAction(_ action: String) -> some View {
        self.accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text(action))
    }
}

// ===============================================
// ACHIEVEMENTS SYSTEM (Gamification)
// ===============================================

enum Achievement: String, CaseIterable, Identifiable {
    case firstHabit = "First Step"
    case sevenDayStreak = "Week Warrior"
    case thirtyDayStreak = "Monthly Master"
    case hundredDayStreak = "Century Champion"
    case fiveHabits = "Habit Collector"
    case perfectWeek = "Flawless Seven"
    case earlyBird = "Morning Glory"
    case nightOwl = "Night Forger"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .firstHabit: return "Created your first habit"
        case .sevenDayStreak: return "Maintained a 7-day streak"
        case .thirtyDayStreak: return "Maintained a 30-day streak"
        case .hundredDayStreak: return "Maintained a 100-day streak"
        case .fiveHabits: return "Created 5 active habits"
        case .perfectWeek: return "Completed all habits for 7 days"
        case .earlyBird: return "Completed 10 morning sessions"
        case .nightOwl: return "Completed 10 evening sessions"
        }
    }
    
    var icon: String {
        switch self {
        case .firstHabit: return "flag.fill"
        case .sevenDayStreak: return "flame.fill"
        case .thirtyDayStreak: return "crown.fill"
        case .hundredDayStreak: return "star.circle.fill"
        case .fiveHabits: return "square.stack.3d.up.fill"
        case .perfectWeek: return "checkmark.seal.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        }
    }
    
    var color: String {
        switch self {
        case .firstHabit: return "4A90E2"
        case .sevenDayStreak: return "FF6B35"
        case .thirtyDayStreak: return "FFD700"
        case .hundredDayStreak: return "9B59B6"
        case .fiveHabits: return "27AE60"
        case .perfectWeek: return "E74C3C"
        case .earlyBird: return "F39C12"
        case .nightOwl: return "34495E"
        }
    }
}

class AchievementManager: ObservableObject {
    @Published var unlockedAchievements: Set<Achievement> = []
    
    init() {
        loadAchievements()
    }
    
    func checkAndUnlock(_ achievement: Achievement) {
        guard !unlockedAchievements.contains(achievement) else { return }
        
        unlockedAchievements.insert(achievement)
        saveAchievements()
        
        // Show notification
        HapticManager.notification(.success)
        // Could trigger a modal or toast here
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedAchievements = Set(decoded.compactMap { Achievement(rawValue: $0) })
        }
    }
    
    private func saveAchievements() {
        let rawValues = unlockedAchievements.map { $0.rawValue }
        if let encoded = try? JSONEncoder().encode(rawValues) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
    }
}

struct AchievementsView: View {
    @StateObject private var manager = AchievementManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(Achievement.allCases) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                isUnlocked: manager.unlockedAchievements.contains(achievement)
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.system(size: 40))
                .foregroundColor(isUnlocked ? Color(hex: achievement.color) : .gray)
            
            Text(achievement.rawValue)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            isUnlocked ?
            LinearGradient(
                colors: [Color(hex: achievement.color).opacity(0.3), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ) :
            LinearGradient(
                colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked ? Color(hex: achievement.color).opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}

// ===============================================
// SEARCH FUNCTIONALITY
// ===============================================

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var searchResults: [Item] = []
    @State private var selectedTags: Set<String> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search habits, tasks, notes...", text: $searchText)
                            .foregroundColor(.white)
                            .onChange(of: searchText) { _ in
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                    
                    // Results
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchResults) { item in
                                SearchResultCard(item: item)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
    
    func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", searchText, searchText)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: false)]
        
        do {
            searchResults = try viewContext.fetch(request)
        } catch {
            print("Search error: \(error)")
        }
    }
}

struct SearchResultCard: View {
    let item: Item
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.iconName ?? typeIcon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: item.colorHex ?? "4A90E2"))
                .frame(width: 40, height: 40)
                .background(Color(hex: item.colorHex ?? "4A90E2").opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                HStack {
                    Text(item.type.rawValue.capitalized)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if let notes = item.notes, !notes.isEmpty {
                        Text("•")
                            .foregroundColor(.gray)
                        Text(notes.prefix(30) + (notes.count > 30 ? "..." : ""))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    var typeIcon: String {
        switch item.type {
        case .habit: return "chart.bar.fill"
        case .task: return "checklist"
        case .checklist: return "list.bullet.clipboard"
        case .note: return "note.text"
        }
    }
}

// ===============================================
// NOTIFICATION MANAGER
// ===============================================

import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
    
    func scheduleHabitReminder(for habit: Item, at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to build your habit!"
        content.body = habit.title
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelReminder(for habitId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habitId.uuidString])
    }
}

// ===============================================
// WIDGET SUPPORT HELPERS (for iOS 14+)
// ===============================================

// Note: Full Widget implementation requires separate WidgetExtension target
// This provides data structure for potential widget integration

struct WidgetData: Codable {
    let todayCompletionRate: Double
    let currentStreak: Int
    let topHabit: String?
    let upcomingTasks: Int
    
    static func generate(from context: NSManagedObjectContext) -> WidgetData {
        // Fetch today's items
        let request = NSFetchRequest<Item>(entityName: "Item")
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", today as NSDate, tomorrow as NSDate)
        
        let items = (try? context.fetch(request)) ?? []
        let completed = items.filter { $0.isCompletedToday() }.count
        let rate = items.isEmpty ? 0.0 : Double(completed) / Double(items.count)
        
        // Get top habit by streak
        let habitRequest = NSFetchRequest<Item>(entityName: "Item")
        habitRequest.predicate = NSPredicate(format: "typeRaw == %@", ItemType.habit.rawValue)
        habitRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.streakCurrent, ascending: false)]
        habitRequest.fetchLimit = 1
        
        let topHabit = try? context.fetch(habitRequest).first
        
        return WidgetData(
            todayCompletionRate: rate,
            currentStreak: Int(topHabit?.streakCurrent ?? 0),
            topHabit: topHabit?.title,
            upcomingTasks: items.count - completed
        )
    }
    
    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults(suiteName: "group.com.routineforge.widgets")?.set(encoded, forKey: "widgetData")
        }
    }
}
