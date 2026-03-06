import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

struct AppUser: Identifiable, Codable {
    let id: String // Firebase UID
    var email: String?
    var displayName: String
    var isGuest: Bool
    var createdAt: Date
    var lastLoginAt: Date
    
    init(id: String, email: String? = nil, displayName: String, isGuest: Bool) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.isGuest = isGuest
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
    
    // Initialize from Firebase User
    init(firebaseUser: User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName ?? "User"
        self.isGuest = firebaseUser.isAnonymous
        self.createdAt = firebaseUser.metadata.creationDate ?? Date()
        self.lastLoginAt = Date()
    }
}

// MARK: - Authentication State

enum AuthState: Equatable {
    case loading
    case authenticated(AppUser)
    case guest(AppUser)
    case unauthenticated
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser.id == rhsUser.id
        case (.guest(let lhsUser), .guest(let rhsUser)):
            return lhsUser.id == rhsUser.id
        case (.unauthenticated, .unauthenticated):
            return true
        default:
            return true
        }
    }
}

// MARK: - Authentication Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case wrongPassword
    case userNotFound
    case networkError
    case guestAccountError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Invalid email address format"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .wrongPassword:
            return "Incorrect password"
        case .userNotFound:
            return "No account found with this email"
        case .networkError:
            return "Network connection error. Try again."
        case .guestAccountError:
            return "Cannot perform this action as guest"
        case .unknown(let message):
            return message
        }
    }
}

extension UserDefaults {
    var currentUserUID: String? {
        get { string(forKey: "currentUserUID") }
        set { set(newValue, forKey: "currentUserUID") }
    }
    
    var isFirstLaunchAfterAuth: Bool {
        get { bool(forKey: "isFirstLaunchAfterAuth") }
        set { set(newValue, forKey: "isFirstLaunchAfterAuth") }
    }
}
