import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var typeRaw: String
    @NSManaged public var dueDate: Date?
    @NSManaged public var repeatRuleRaw: String
    @NSManaged public var notes: String?
    @NSManaged public var completedDatesData: Data?
    @NSManaged public var priorityRaw: String
    @NSManaged public var tagsData: Data?
    @NSManaged public var iconName: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var subtasksData: Data?
    @NSManaged public var streakCurrent: Int16
    @NSManaged public var streakRecord: Int16
    @NSManaged public var isTemplate: Bool
    
    var type: ItemType {
        get { ItemType(rawValue: typeRaw) ?? .task }
        set { typeRaw = newValue.rawValue }
    }
    
    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    var repeatRule: RepeatRule {
        get { RepeatRule(rawValue: repeatRuleRaw) ?? .none }
        set { repeatRuleRaw = newValue.rawValue }
    }
    
    var completedDates: Set<Date> {
        get {
            guard let data = completedDatesData else { return [] }
            return (try? JSONDecoder().decode(Set<Date>.self, from: data)) ?? []
        }
        set {
            completedDatesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var tags: [String] {
        get {
            guard let data = tagsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            tagsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var subtasks: [Subtask] {
        get {
            guard let data = subtasksData else { return [] }
            return (try? JSONDecoder().decode([Subtask].self, from: data)) ?? []
        }
        set {
            subtasksData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var level: Int {
        let completed = completedDates.filter { $0 > Calendar.current.date(byAdding: .day, value: -30, to: Date())! }.count
        return min(10, Int(ceil(Double(completed) / 3.0)))
    }
    
    func isCompletedToday() -> Bool {
        let calendar = Calendar.current
        return completedDates.contains { calendar.isDateInToday($0) }
    }
    
    func toggleCompletion() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var dates = completedDates
        if dates.contains(today) {
            dates.remove(today)
        } else {
            dates.insert(today)
            updateStreak()
        }
        completedDates = dates
    }
    
    func updateStreak() {
        let calendar = Calendar.current
        let sorted = completedDates.sorted(by: >)
        
        var current = 0
        var lastDate: Date?
        
        for date in sorted {
            if let last = lastDate {
                let daysBetween = calendar.dateComponents([.day], from: date, to: last).day ?? 0
                if daysBetween > 1 {
                    break
                }
            }
            current += 1
            lastDate = date
        }
        
        streakCurrent = Int16(current)
        if current > streakRecord {
            streakRecord = Int16(current)
        }
    }
}

struct Subtask: Codable, Identifiable {
    var id = UUID()
    var title: String
    var completed: Bool
}
