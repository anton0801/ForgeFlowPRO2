import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = FirebaseAuthService.shared
    
    @AppStorage("userName") private var userName = "User"
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("iCloudSyncEnabled") private var iCloudSync = false
    
    @State private var showingExportAlert = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingLinkAccountSheet = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        profileSection
                        
                        // App Settings
                        settingsSection
                        
                        // Account Actions
                        if authService.isAuthenticated {
                            accountActionsSection
                        }
                        
                        // About Section
                        aboutSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.white))
            .alert(isPresented: $showingSignOutAlert) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("This will permanently delete your account and all data. This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete Forever")) {
                        deleteAccount()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingLinkAccountSheet) {
                LinkGuestAccountView()
            }
        }
        .overlay {
            if isDeleting {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - Profile Section
    
    var profileSection: some View {
        VStack(spacing: 16) {
            // Profile Picture Placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color(hex: "FFD700")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text(userName.prefix(1).uppercased())
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Name
            VStack(spacing: 4) {
                Text(userName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                if let user = authService.currentUser {
                    if user.isGuest {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 12))
                            Text("Guest Account")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.gray)
                    } else if let email = user.email {
                        Text(email)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Link Guest Account Button (only for guest users)
            if authService.isGuest {
                Button(action: { showingLinkAccountSheet = true }) {
                    HStack {
                        Image(systemName: "link")
                        Text("Convert to Full Account")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "4A90E2"))
                    .cornerRadius(20)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Settings Section
    
    var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Name
                HStack {
                    Text("Name")
                        .foregroundColor(.white)
                    Spacer()
                    TextField("Your name", text: $userName)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // Dark Mode
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(Color(hex: "FFD700"))
                        .frame(width: 24)
                    
                    Text("Dark Mode")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: $isDarkMode)
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "FF6B35")))
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // iCloud Sync (disabled for guests)
                HStack {
                    Image(systemName: "icloud.fill")
                        .foregroundColor(Color(hex: "4A90E2"))
                        .frame(width: 24)
                    
                    Text("iCloud Sync")
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Toggle("", isOn: $iCloudSync)
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "4A90E2")))
                        .disabled(authService.isGuest)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .opacity(authService.isGuest ? 0.5 : 1.0)
                
                if authService.isGuest {
                    Text("iCloud sync requires a full account")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // MARK: - Account Actions Section
    
    var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Export Data
                Button(action: { showingExportAlert = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color(hex: "27AE60"))
                            .frame(width: 24)
                        
                        Text("Export Data")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Sign Out
                Button(action: { showingSignOutAlert = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(Color(hex: "FFD700"))
                            .frame(width: 24)
                        
                        Text("Sign Out")
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Delete Account
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text("Delete Account")
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - About Section
    
    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Version
                HStack {
                    Text("Version")
                        .foregroundColor(.white)
                    Spacer()
                    Text("1.20.0")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // Privacy Policy
//                Link(destination: URL(string: "https://forgeflowapp.com/privacy")!) {
//                    HStack {
//                        Text("Privacy Policy")
//                            .foregroundColor(.white)
//                        Spacer()
//                        Image(systemName: "arrow.up.right")
//                            .foregroundColor(.gray)
//                    }
//                    .padding()
//                    .background(Color.white.opacity(0.05))
//                    .cornerRadius(12)
//                }
//                
//                // Support
//                Link(destination: URL(string: "https://forgeflowapp.com/support")!) {
//                    HStack {
//                        Text("Support")
//                            .foregroundColor(.white)
//                        Spacer()
//                        Image(systemName: "arrow.up.right")
//                            .foregroundColor(.gray)
//                    }
//                    .padding()
//                    .background(Color.white.opacity(0.05))
//                    .cornerRadius(12)
//                }
            }
        }
    }
    
    // MARK: - Actions
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteAccount() {
        isDeleting = true
        
        Task {
            do {
                try await authService.deleteAccount()
                
                // Clear all local data
                UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                
                await MainActor.run {
                    isDeleting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isDeleting = false
                }
            }
        }
    }
}

// MARK: - Link Guest Account View

struct LinkGuestAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = FirebaseAuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(hex: "4A90E2"))
                            
                            Text("Convert Guest Account")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Keep all your data by creating a full account")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        
                        // Form
                        VStack(spacing: 16) {
                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                TextField("", text: $displayName)
                                    .placeholder(when: displayName.isEmpty) {
                                        Text("Your name").foregroundColor(.gray.opacity(0.5))
                                    }
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                TextField("", text: $email)
                                    .placeholder(when: email.isEmpty) {
                                        Text("your@email.com").foregroundColor(.gray.opacity(0.5))
                                    }
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                SecureField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Minimum 6 characters").foregroundColor(.gray.opacity(0.5))
                                    }
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                SecureField("", text: $confirmPassword)
                                    .placeholder(when: confirmPassword.isEmpty) {
                                        Text("Re-enter password").foregroundColor(.gray.opacity(0.5))
                                    }
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        // Error
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        
                        // Info
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Keep all your habits and data")
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Enable iCloud sync")
                            }
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 30)
                        
                        // Convert Button
                        Button(action: linkAccount) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Convert Account")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "4A90E2"))
                        .cornerRadius(16)
                        .padding(.horizontal, 30)
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.5)
                    }
                }
            }
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.white))
        }
    }
    
    var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    func linkAccount() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.linkGuestToEmail(email: email, password: password, displayName: displayName)
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
