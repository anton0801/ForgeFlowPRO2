import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "RoutineForge")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error loading Core Data: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        if !UserDefaults.standard.bool(forKey: "hasSeededTemplates") {
            seedTemplates()
            UserDefaults.standard.set(true, forKey: "hasSeededTemplates")
        }
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func seedTemplates() {
        let context = container.viewContext
        let templates = getDefaultTemplates()
        
        for template in templates {
            let item = Item(context: context)
            item.id = UUID()
            item.title = template.title
            item.type = .checklist
            item.subtasks = template.subtasks
            item.iconName = template.icon
            item.colorHex = template.color
            item.isTemplate = true
            item.createdAt = Date()
            item.repeatRule = .none
            item.priority = .medium
        }
        
        save()
    }
    
    func getDefaultTemplates() -> [ChecklistTemplate] {
        return [
            ChecklistTemplate(
                title: "Morning Ritual",
                icon: "sun.max.fill",
                color: "FFD700",
                subtasks: [
                    Subtask(title: "Drink water (500ml)", completed: false),
                    Subtask(title: "5-minute stretching", completed: false),
                    Subtask(title: "Meditation (5 min)", completed: false),
                    Subtask(title: "Healthy breakfast", completed: false),
                    Subtask(title: "Review daily goals", completed: false)
                ]
            ),
            ChecklistTemplate(
                title: "Evening Wind Down",
                icon: "moon.stars.fill",
                color: "4A90E2",
                subtasks: [
                    Subtask(title: "Clear desk/workspace", completed: false),
                    Subtask(title: "Prepare tomorrow's outfit", completed: false),
                    Subtask(title: "Gratitude journal (3 things)", completed: false),
                    Subtask(title: "No screens 30min before bed", completed: false),
                    Subtask(title: "Set bedtime alarm", completed: false)
                ]
            ),
            ChecklistTemplate(
                title: "Deep Work Session",
                icon: "brain.head.profile",
                color: "9B59B6",
                subtasks: [
                    Subtask(title: "Clear all distractions", completed: false),
                    Subtask(title: "Set phone to DND", completed: false),
                    Subtask(title: "Water bottle ready", completed: false),
                    Subtask(title: "Start Pomodoro timer", completed: false),
                    Subtask(title: "Single task focus", completed: false)
                ]
            ),
            ChecklistTemplate(
                title: "Home Cleaning",
                icon: "house.fill",
                color: "27AE60",
                subtasks: [
                    Subtask(title: "Kitchen: dishes, counters", completed: false),
                    Subtask(title: "Living room: vacuum, dust", completed: false),
                    Subtask(title: "Bathroom: sink, toilet, shower", completed: false),
                    Subtask(title: "Bedroom: make bed, organize", completed: false),
                    Subtask(title: "Take out trash", completed: false)
                ]
            ),
            ChecklistTemplate(
                title: "Travel Packing",
                icon: "suitcase.fill",
                color: "E67E22",
                subtasks: [
                    Subtask(title: "Passport/ID", completed: false),
                    Subtask(title: "Phone charger + cables", completed: false),
                    Subtask(title: "Clothes (check weather)", completed: false),
                    Subtask(title: "Toiletries", completed: false),
                    Subtask(title: "Medications", completed: false),
                    Subtask(title: "Lock doors/windows", completed: false)
                ]
            ),
            ChecklistTemplate(
                title: "Weekly Review",
                icon: "calendar",
                color: "E74C3C",
                subtasks: [
                    Subtask(title: "What went well this week?", completed: false),
                    Subtask(title: "What could improve?", completed: false),
                    Subtask(title: "Review incomplete tasks", completed: false),
                    Subtask(title: "Plan next week priorities", completed: false),
                    Subtask(title: "Schedule important events", completed: false)
                ]
            )
        ]
    }
}

struct ChecklistTemplate {
    let title: String
    let icon: String
    let color: String
    let subtasks: [Subtask]
}
