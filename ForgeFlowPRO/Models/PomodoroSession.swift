import Foundation

struct PomodoroSession: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var duration: Int // minutes
    var tasksCompleted: [String]
    var mood: String
    var notes: String
}
