import Foundation
import UIKit
import AVFoundation
import Combine
import UserNotifications

class PomodoroViewModel: ObservableObject {
    @Published var timeRemaining: Int = 1500 // 25 minutes
    @Published var isRunning = false
    @Published var currentMode: PomodoroMode = .work
    @Published var sessions: [PomodoroSession] = []
    @Published var selectedSound: AmbientSound = .none
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    enum PomodoroMode {
        case work
        case shortBreak
        case longBreak
        
        var duration: Int {
            switch self {
            case .work: return 1500 // 25 min
            case .shortBreak: return 300 // 5 min
            case .longBreak: return 900 // 15 min
            }
        }
    }
    
    enum AmbientSound: String, CaseIterable {
        case none = "None"
        case rain = "Rain"
        case forest = "Forest"
        case whiteNoise = "White Noise"
        case cafe = "Coffee Shop"
        
        var filename: String? {
            switch self {
            case .none: return nil
            case .rain: return "rain_loop"
            case .forest: return "forest_loop"
            case .whiteNoise: return "whitenoise_loop"
            case .cafe: return "cafe_loop"
            }
        }
    }
    
    init() {
        loadSessions()
    }
    
    func startTimer() {
        isRunning = true
        requestFocusMode()
        playAmbientSound()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timerCompleted()
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        stopAmbientSound()
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = currentMode.duration
    }
    
    func timerCompleted() {
        pauseTimer()
        sendNotification()
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        // Save session
        let session = PomodoroSession(
            date: Date(),
            duration: currentMode.duration / 60,
            tasksCompleted: [],
            mood: "",
            notes: ""
        )
        sessions.append(session)
        saveSessions()
    }
    
    func requestFocusMode() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                // Note: Actual Focus mode control requires Screen Time API (iOS 15+)
                print("Notifications authorized")
            }
        }
    }
    
    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Complete!"
        content.body = currentMode == .work ? "Great work! Time for a break." : "Break over. Ready to focus?"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func playAmbientSound() {
        guard let filename = selectedSound.filename else { return }
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            audioPlayer?.volume = 0.3
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error)")
        }
    }
    
    func stopAmbientSound() {
        audioPlayer?.stop()
    }
    
    func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "pomodoroSessions"),
           let decoded = try? JSONDecoder().decode([PomodoroSession].self, from: data) {
            sessions = decoded
        }
    }
    
    func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "pomodoroSessions")
        }
    }
}
