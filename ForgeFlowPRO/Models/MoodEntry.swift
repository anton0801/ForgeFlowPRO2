import Foundation

struct MoodEntry: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var mood: Int // 1-5
    var energy: Int // 1-10
    var sleepHours: Double
    var notes: String
}
