import Foundation

func update(msg: Msg, model: Model) -> (Model, Cmd) {
    var newModel = model
    var cmd: Cmd = .none
    
    switch msg {
    case .boot:
        newModel.stage = .booting
        cmd = .batch([.loadConfig, .scheduleTimeout, .monitorNetwork])
        
    case .timeout:
        if !newModel.frozen {
            newModel.stage = .inactive
        }
        
    case .trackingArrived(let data):
        let converted = convertToStringDict(data)
        newModel.tracking = Model.TrackingInfo(payload: converted)
        cmd = .batch([
            .saveTracking(converted),
            .validateFirebase
        ])
        
    case .linkingArrived(let data):
        let converted = convertToStringDict(data)
        newModel.linking = Model.LinkingInfo(payload: converted)
        cmd = .saveLinking(converted)
        
    case .networkConnected:
        if case .offline = newModel.stage, !newModel.frozen {
            newModel.stage = .inactive
        }
        
    case .networkDisconnected:
        if !newModel.frozen {
            newModel.stage = .offline
        }
        
    case .validateRequested:
        newModel.stage = .validating
        
    case .validateSucceeded:
        newModel.stage = .validated
        
        if newModel.tracking.exists {
            if let temp = UserDefaults.standard.string(forKey: "temp_url") {
                newModel.resource = temp
                newModel.stage = .active(temp)
                newModel.frozen = true
                if newModel.alerts.canRequest {
                    cmd = .none // Alert will be shown by view
                }
            } else if shouldRunOrganicFlow(model: newModel) {
                cmd = .fetchTracking(getDeviceID())
            } else {
                cmd = .fetchResource(convertToAnyDict(newModel.tracking.payload))
            }
        } else if let saved = newModel.config.savedResource {
            newModel.resource = saved
            newModel.stage = .active(saved)
            newModel.frozen = true
        } else {
            newModel.stage = .inactive
        }
        
    case .validateFailed:
        newModel.stage = .inactive
        
    case .fetchTrackingRequested:
        break
        
    case .fetchTrackingSucceeded(let data):
        var merged = data
        let linkingDict = convertToAnyDict(newModel.linking.payload)
        
        for (key, value) in linkingDict {
            if merged[key] == nil {
                merged[key] = value
            }
        }
        
        let converted = convertToStringDict(merged)
        newModel.tracking = Model.TrackingInfo(payload: converted)
        cmd = .batch([
            .saveTracking(converted),
            .fetchResource(merged)
        ])
        
    case .fetchTrackingFailed:
        newModel.stage = .inactive
        
    case .fetchResourceRequested:
        break
        
    case .fetchResourceSucceeded(let resource):
        newModel.resource = resource
        newModel.config.savedResource = resource
        newModel.config.mode = "Active"
        newModel.config.firstRun = false
        newModel.stage = .active(resource)
        newModel.frozen = true
        
        cmd = .batch([
            .saveResource(resource),
            .saveMode("Active"),
            .markFirstRunDone
        ])
        
    case .fetchResourceFailed:
        if let saved = newModel.config.savedResource {
            newModel.resource = saved
            newModel.stage = .active(saved)
            newModel.frozen = true
        } else {
            newModel.stage = .inactive
        }
        
    case .alertPromptShown:
        break
        
    case .alertPermissionRequested:
        cmd = .requestPermission
        
    case .alertPermissionGranted:
        newModel.alerts = Model.AlertInfo(
            accepted: true,
            rejected: false,
            requestedAt: Date()
        )
        cmd = .batch([
            .saveAlerts(newModel.alerts),
            .registerForNotifications
        ])
        
    case .alertPermissionDenied:
        newModel.alerts = Model.AlertInfo(
            accepted: false,
            rejected: true,
            requestedAt: Date()
        )
        cmd = .saveAlerts(newModel.alerts)
        
    case .alertPromptDismissed:
        newModel.alerts = Model.AlertInfo(
            accepted: false,
            rejected: false,
            requestedAt: Date()
        )
        cmd = .saveAlerts(newModel.alerts)
        
    case .goToMain:
        newModel.stage = .inactive
        
    case .goToContent:
        break
        
    case .configLoaded(let config):
        newModel.config.savedResource = config.resource
        newModel.config.mode = config.mode
        newModel.config.firstRun = config.firstRun
        newModel.tracking = Model.TrackingInfo(payload: config.tracking)
        newModel.linking = Model.LinkingInfo(payload: config.linking)
        
        let accepted = config.alerts.accepted
        let rejected = config.alerts.rejected
        newModel.alerts = Model.AlertInfo(
            accepted: accepted,
            rejected: rejected,
            requestedAt: config.alerts.requestedAt
        )
        
    case .configSaved:
        break
    }
    
    return (newModel, cmd)
}

// MARK: - Helpers

private func shouldRunOrganicFlow(model: Model) -> Bool {
    model.config.firstRun && model.tracking.isOrganic
}

private func getDeviceID() -> String {
    AppsFlyerLib.shared().getAppsFlyerUID()
}

private func convertToStringDict(_ dict: [String: Any]) -> [String: String] {
    var result: [String: String] = [:]
    for (key, value) in dict {
        result[key] = "\(value)"
    }
    return result
}

private func convertToAnyDict(_ dict: [String: String]) -> [String: Any] {
    var result: [String: Any] = [:]
    for (key, value) in dict {
        result[key] = value
    }
    return result
}

import AppsFlyerLib
