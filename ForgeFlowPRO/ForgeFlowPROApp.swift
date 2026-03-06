import SwiftUI
import Firebase

@main
struct Routine_ForgeApp: App {
    let persistenceController = PersistenceController.shared
  
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
