import Foundation

struct Model: Equatable {
    var stage: Stage
    var resource: String?
    var frozen: Bool
    var tracking: TrackingInfo
    var linking: LinkingInfo
    var alerts: AlertInfo
    var config: ConfigInfo
    
    enum Stage: Equatable {
        case initial
        case booting
        case validating
        case validated
        case active(String)
        case inactive
        case offline
    }
    
    struct TrackingInfo: Equatable {
        let payload: [String: String]
        
        var exists: Bool { !payload.isEmpty }
        var isOrganic: Bool { payload["af_status"] == "Organic" }
        
        static var empty: TrackingInfo {
            TrackingInfo(payload: [:])
        }
    }
    
    struct LinkingInfo: Equatable {
        let payload: [String: String]
        
        var exists: Bool { !payload.isEmpty }
        
        static var empty: LinkingInfo {
            LinkingInfo(payload: [:])
        }
    }
    
    struct AlertInfo: Equatable {
        var accepted: Bool
        var rejected: Bool
        var requestedAt: Date?
        
        var canRequest: Bool {
            guard !accepted && !rejected else { return false }
            
            if let date = requestedAt {
                let days = Date().timeIntervalSince(date) / 86400
                return days >= 3
            }
            return true
        }
        
        static var initial: AlertInfo {
            AlertInfo(accepted: false, rejected: false, requestedAt: nil)
        }
    }
    
    struct ConfigInfo: Equatable {
        var savedResource: String?
        var mode: String?
        var firstRun: Bool
        
        static var initial: ConfigInfo {
            ConfigInfo(savedResource: nil, mode: nil, firstRun: true)
        }
    }
    
    static var initial: Model {
        Model(
            stage: .initial,
            resource: nil,
            frozen: false,
            tracking: .empty,
            linking: .empty,
            alerts: .initial,
            config: .initial
        )
    }
}

struct ViewModel: Equatable {
    var showAlertPrompt: Bool
    var showOfflineView: Bool
    var navigateToMain: Bool
    var navigateToContent: Bool
    
    static var initial: ViewModel {
        ViewModel(
            showAlertPrompt: false,
            showOfflineView: false,
            navigateToMain: false,
            navigateToContent: false
        )
    }
    
    // Derive from Model
    static func from(_ model: Model) -> ViewModel {
        var vm = ViewModel.initial
        
        // Determine navigation
        if case .active = model.stage {
            if model.alerts.canRequest {
                vm.showAlertPrompt = true
            } else {
                vm.navigateToContent = true
            }
        }
        
        if case .inactive = model.stage {
            vm.navigateToMain = true
        }
        
        if case .offline = model.stage {
            vm.showOfflineView = true
        }
        
        return vm
    }
}
