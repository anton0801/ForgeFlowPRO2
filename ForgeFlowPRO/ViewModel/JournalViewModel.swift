import Foundation
import Combine

class JournalViewModel: ObservableObject {
    @Published var entries: [MoodEntry] = []
    @Published var selectedDate = Date()
    @Published var currentEntry: MoodEntry?
    
    init() {
        loadEntries()
        loadTodayEntry()
    }
    
    func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: "moodEntries"),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            entries = decoded.sorted { $0.date > $1.date }
        }
    }
    
    func loadTodayEntry() {
        let calendar = Calendar.current
        currentEntry = entries.first { calendar.isDate($0.date, inSameDayAs: Date()) }
    }
    
    func saveEntry(mood: Int, energy: Int, sleepHours: Double, notes: String) {
        let calendar = Calendar.current
        
        if let index = entries.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: Date()) }) {
            entries[index].mood = mood
            entries[index].energy = energy
            entries[index].sleepHours = sleepHours
            entries[index].notes = notes
        } else {
            let entry = MoodEntry(date: Date(), mood: mood, energy: energy, sleepHours: sleepHours, notes: notes)
            entries.insert(entry, at: 0)
        }
        
        saveToUserDefaults()
        loadTodayEntry()
    }
    
    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "moodEntries")
        }
    }
    
    func averageMood(days: Int) -> Double {
        let recent = entries.prefix(days)
        guard !recent.isEmpty else { return 0 }
        return Double(recent.map { $0.mood }.reduce(0, +)) / Double(recent.count)
    }
    
    func highEnergyDays(threshold: Int) -> Int {
        return entries.filter { $0.energy >= threshold }.count
    }
}
