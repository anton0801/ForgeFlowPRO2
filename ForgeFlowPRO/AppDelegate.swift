import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

struct ForgeConfig {
    static let appID = "6759285329"
    static let devKey = "VFSHsyJyjeNB7MTWguAkAQ"
}

final class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    private let attrBridge = AttributionBridge()
    private let pushBridge = PushBridge()
    private var sdkBridge: SDKBridge?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        attrBridge.onTracking = { [weak self] in self?.relay(tracking: $0) }
        attrBridge.onNavigation = { [weak self] in self?.relay(navigation: $0) }
        sdkBridge = SDKBridge(bridge: attrBridge)
        
        setupFirebase()
        setupPush()
        setupSDK()
        
        if let push = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushBridge.process(push)
        }
        
        observeLifecycle()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func setupFirebase() { FirebaseApp.configure(); Auth.auth().signInAnonymously() }
    
    private func setupPush() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func setupSDK() { sdkBridge?.configure() }
    
    private func observeLifecycle() {
        NotificationCenter.default.addObserver(self, selector: #selector(activate), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func activate() { sdkBridge?.start() }
    
    private func relay(tracking data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: .init("ConversionDataReceived"), object: nil, userInfo: ["conversionData": data])
    }
    
    private func relay(navigation data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: .init("deeplink_values"), object: nil, userInfo: ["deeplinksData": data])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, error in
            guard error == nil, let token else { return }
            UserDefaults.standard.set(token, forKey: "fcm_token")
            UserDefaults.standard.set(token, forKey: "push_token")
            UserDefaults(suiteName: "group.forge.vault")?.set(token, forKey: "shared_fcm")
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        pushBridge.process(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        pushBridge.process(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        pushBridge.process(userInfo)
        completionHandler(.newData)
    }
}

final class AttributionBridge: NSObject {
    var onTracking: (([AnyHashable: Any]) -> Void)?
    var onNavigation: (([AnyHashable: Any]) -> Void)?
    
    private var trackingBuf: [AnyHashable: Any] = [:]
    private var navigationBuf: [AnyHashable: Any] = [:]
    private var timer: Timer?
    
    func receiveTracking(_ data: [AnyHashable: Any]) {
        trackingBuf = data
        scheduleTimer()
        if !navigationBuf.isEmpty { merge() }
    }
    
    func receiveNavigation(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: "ff_launched_flag") else { return }
        navigationBuf = data
        onNavigation?(data)
        timer?.invalidate()
        if !trackingBuf.isEmpty { merge() }
    }
    
    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.merge() }
    }
    
    private func merge() {
        var result = trackingBuf
        navigationBuf.forEach { k, v in
            let key = "deep_\(k)"
            if result[key] == nil { result[key] = v }
        }
        onTracking?(result)
    }
}

final class PushBridge: NSObject {
    func process(_ payload: [AnyHashable: Any]) {
        guard let url = extract(from: payload) else { return }
        UserDefaults.standard.set(url, forKey: "temp_url")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationCenter.default.post(name: .init("LoadTempURL"), object: nil, userInfo: ["temp_url": url])
        }
    }
    
    private func extract(from p: [AnyHashable: Any]) -> String? {
        if let u = p["url"] as? String { return u }
        if let d = p["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let a = p["aps"] as? [String: Any], let d = a["data"] as? [String: Any], let u = d["url"] as? String { return u }
        if let c = p["custom"] as? [String: Any], let u = c["url"] as? String { return u }
        return nil
    }
}

final class SDKBridge: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate {
    private var bridge: AttributionBridge
    
    init(bridge: AttributionBridge) { self.bridge = bridge }
    
    func configure() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = ForgeConfig.devKey
        sdk.appleAppID = ForgeConfig.appID
        sdk.delegate = self
        sdk.deepLinkDelegate = self
        sdk.isDebug = false
    }
    
    func start() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) { bridge.receiveTracking(data) }
    func onConversionDataFail(_ error: Error) {
        bridge.receiveTracking(["error": true, "error_desc": error.localizedDescription])
    }
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let dl = result.deepLink else { return }
        bridge.receiveNavigation(dl.clickEvent)
    }
}
