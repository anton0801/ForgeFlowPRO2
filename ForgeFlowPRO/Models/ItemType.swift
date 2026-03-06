import Foundation

enum ItemType: String, Codable {
    case habit
    case task
    case checklist
    case note
}

enum Priority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    
    var color: String {
        switch self {
        case .low: return "4A90E2"
        case .medium: return "FFD700"
        case .high: return "E74C3C"
        }
    }
}

enum RepeatRule: String, Codable {
    case daily
    case weekdays // Mon-Fri
    case everyOtherDay
    case threeTimesWeek
    case custom
    case none
}
