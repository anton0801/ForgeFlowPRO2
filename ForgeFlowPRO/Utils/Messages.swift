import Foundation

enum Msg {
    // Lifecycle
    case boot
    case timeout
    
    // Data arrival
    case trackingArrived([String: Any])
    case linkingArrived([String: Any])
    
    // Network
    case networkConnected
    case networkDisconnected
    
    // Validation
    case validateRequested
    case validateSucceeded
    case validateFailed
    
    // Fetching
    case fetchTrackingRequested
    case fetchTrackingSucceeded([String: Any])
    case fetchTrackingFailed
    
    case fetchResourceRequested
    case fetchResourceSucceeded(String)
    case fetchResourceFailed
    
    // Alerts
    case alertPromptShown
    case alertPermissionRequested
    case alertPermissionGranted
    case alertPermissionDenied
    case alertPromptDismissed
    
    // Navigation
    case goToMain
    case goToContent
    
    // Config
    case configLoaded(LoadedConfig)
    case configSaved
    
    struct LoadedConfig {
        var resource: String?
        var mode: String?
        var firstRun: Bool
        var tracking: [String: String]
        var linking: [String: String]
        var alerts: AlertConfig
        
        struct AlertConfig {
            var accepted: Bool
            var rejected: Bool
            var requestedAt: Date?
        }
    }
}

// MARK: - Commands (Elm Architecture)

// UNIQUE: Side effects as commands
enum Cmd {
    case none
    case batch([Cmd])
    case scheduleTimeout
    case loadConfig
    case saveTracking([String: String])
    case saveLinking([String: String])
    case saveResource(String)
    case saveMode(String)
    case markFirstRunDone
    case saveAlerts(Model.AlertInfo)
    case validateFirebase
    case fetchTracking(String)
    case fetchResource([String: Any])
    case requestPermission
    case registerForNotifications
    case monitorNetwork
}
