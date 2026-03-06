import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import Combine

class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()
    
    @Published var authState: AuthState = .loading
    @Published var currentUser: AppUser?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthListener() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            if let user = user {
                let appUser = AppUser(firebaseUser: user)
                self.currentUser = appUser
                
                if user.isAnonymous {
                    self.authState = .guest(appUser)
                } else {
                    self.authState = .authenticated(appUser)
                }
                
                // Save user to Firestore
                self.saveUserToFirestore(appUser)
                
                // Save UID to UserDefaults for data migration
                UserDefaults.standard.set(user.uid, forKey: "currentUserUID")
                
            } else {
                self.currentUser = nil
                self.authState = .unauthenticated
                UserDefaults.standard.removeObject(forKey: "currentUserUID")
            }
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, displayName: String) async throws {
        // Validation
        guard email.contains("@") && email.contains(".") else {
            throw AuthError.invalidEmail
        }
        
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            // Save custom display name to UserDefaults
            UserDefaults.standard.set(displayName, forKey: "userName")
            
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            
            // Update last login
            if let displayName = result.user.displayName {
                UserDefaults.standard.set(displayName, forKey: "userName")
            }
            
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Guest Sign In
    
    func signInAsGuest() async throws {
        do {
            let result = try await auth.signInAnonymously()
            
            // Set default guest name
            UserDefaults.standard.set("Guest", forKey: "userName")
            
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Link Guest to Email Account
    
    func linkGuestToEmail(email: String, password: String, displayName: String) async throws {
        guard let user = auth.currentUser, user.isAnonymous else {
            throw AuthError.guestAccountError
        }
        
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            let result = try await user.link(with: credential)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            UserDefaults.standard.set(displayName, forKey: "userName")
            
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        do {
            try auth.signOut()
            // Clear local data
            UserDefaults.standard.removeObject(forKey: "currentUserUID")
            
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotFound
        }
        
        let uid = user.uid
        
        do {
            // Delete user data from Firestore
            try await deleteUserDataFromFirestore(uid: uid)
            
            // Delete Firebase Auth account
            try await user.delete()
            
            // Clear local data
            UserDefaults.standard.removeObject(forKey: "currentUserUID")
            UserDefaults.standard.removeObject(forKey: "userName")
            
        } catch let error as NSError {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }
        
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Firestore Operations
    
    private func saveUserToFirestore(_ user: AppUser) {
        let userRef = db.collection("users").document(user.id)
        
        let userData: [String: Any] = [
            "email": user.email ?? "",
            "displayName": user.displayName,
            "isGuest": user.isGuest,
            "createdAt": Timestamp(date: user.createdAt),
            "lastLoginAt": Timestamp(date: Date())
        ]
        
        userRef.setData(userData, merge: true) { error in
            if let error = error {
            } else {
            }
        }
    }
    
    private func deleteUserDataFromFirestore(uid: String) async throws {
        let userRef = db.collection("users").document(uid)
        try await userRef.delete()
        
        // Delete user's habits, tasks, etc.
        let habitsRef = db.collection("users").document(uid).collection("habits")
        let habitsSnapshot = try await habitsRef.getDocuments()
        
        for document in habitsSnapshot.documents {
            try await document.reference.delete()
        }
    }
    
    private func mapFirebaseError(_ error: NSError) -> AuthError {
//        guard let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
//            return .unknown(error.localizedDescription)
//        }
//        
//        switch errorCode {
//        case .invalidEmail:
//            return .invalidEmail
//        case .weakPassword:
//            return .weakPassword
//        case .emailAlreadyInUse:
//            return .emailAlreadyInUse
//        case .wrongPassword:
//            return .wrongPassword
//        case .userNotFound:
//            return .userNotFound
//        case .networkError:
//            return .networkError
//        default:
//            return .unknown(error.localizedDescription)
//        }
        return .unknown(error.localizedDescription)
    }
    
    // MARK: - Helper Methods
    
    var isAuthenticated: Bool {
        auth.currentUser != nil
    }
    
    var isGuest: Bool {
        auth.currentUser?.isAnonymous ?? false
    }
    
    var currentUserUID: String? {
        auth.currentUser?.uid
    }
}
