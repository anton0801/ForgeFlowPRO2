import Foundation
import CoreData
import Combine

class HabitViewModel: ObservableObject {
    @Published var habits: [Item] = []
    @Published var selectedHabit: Item?
    @Published var showingAddSheet = false
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchHabits()
    }
    
    func fetchHabits() {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(format: "typeRaw == %@", ItemType.habit.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: false)]
        
        do {
            habits = try context.fetch(request)
        } catch {
            print("Error fetching habits: \(error)")
        }
    }
    
    func createHabit(title: String, icon: String, color: String, repeatRule: RepeatRule) {
        let habit = Item(context: context)
        habit.id = UUID()
        habit.title = title
        habit.type = .habit
        habit.iconName = icon
        habit.colorHex = color
        habit.repeatRule = repeatRule
        habit.createdAt = Date()
        habit.priority = .medium
        
        PersistenceController.shared.save()
        fetchHabits()
    }
    
    func deleteHabit(_ habit: Item) {
        context.delete(habit)
        PersistenceController.shared.save()
        fetchHabits()
    }
    
    func getCompletionData(for habit: Item, days: Int = 365) -> [Date: Bool] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        var data: [Date: Bool] = [:]
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            data[dayStart] = habit.completedDates.contains(dayStart)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return data
    }
}
