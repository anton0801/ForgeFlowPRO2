import Foundation
import CoreData
import Combine

class DashboardViewModel: ObservableObject {
    @Published var todayItems: [Item] = []
    @Published var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "there"
    @Published var greeting: String = ""
    @Published var completionRate: Double = 0
    
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    init(context: NSManagedObjectContext) {
        self.context = context
        updateGreeting()
        fetchTodayItems()
    }
    
    func fetchTodayItems() {
        let request = NSFetchRequest<Item>(entityName: "Item")
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        request.predicate = NSPredicate(format: "(dueDate >= %@ AND dueDate < %@) OR repeatRuleRaw != %@ OR (typeRaw == %@ AND isTemplate == false)", 
                                       today as NSDate, 
                                       tomorrow as NSDate,
                                       RepeatRule.none.rawValue,
                                       ItemType.habit.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        
        do {
            let items = try context.fetch(request)
            todayItems = items.filter { item in
                if item.type == .habit {
                    return shouldShowHabitToday(item)
                }
                return true
            }
            calculateCompletionRate()
        } catch {
            print("Error fetching items: \(error)")
        }
    }
    
    func shouldShowHabitToday(_ habit: Item) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        switch habit.repeatRule {
        case .daily:
            return true
        case .weekdays:
            return weekday >= 2 && weekday <= 6 // Mon-Fri
        case .everyOtherDay:
            let daysSinceCreation = calendar.dateComponents([.day], from: habit.createdAt, to: Date()).day ?? 0
            return daysSinceCreation % 2 == 0
        case .threeTimesWeek:
            return [2, 4, 6].contains(weekday) // Mon, Wed, Fri
        default:
            return false
        }
    }
    
    func calculateCompletionRate() {
        guard !todayItems.isEmpty else {
            completionRate = 0
            return
        }
        
        let completed = todayItems.filter { item in
            if item.type == .habit {
                return item.isCompletedToday()
            } else if item.type == .checklist {
                return item.subtasks.allSatisfy { $0.completed }
            }
            return false
        }.count
        
        completionRate = Double(completed) / Double(todayItems.count)
    }
    
    func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            greeting = "Good morning"
        case 12..<17:
            greeting = "Good afternoon"
        default:
            greeting = "Good evening"
        }
    }
    
    func toggleItem(_ item: Item) {
        if item.type == .habit {
            item.toggleCompletion()
        }
        PersistenceController.shared.save()
        fetchTodayItems()
    }
}
