import SwiftUI
import FirebaseAuth

struct AuthContainerView: View {
    @StateObject private var authService = FirebaseAuthService.shared
    @State private var showingApp = false
    
    var body: some View {
        Group {
            switch authService.authState {
            case .loading:
                EmptyView()
            case .authenticated, .guest:
                if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                    MainTabView()
                } else {
                    OnboardingContainerView()
                }
                
            case .unauthenticated:
                WelcomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.authState)
    }
}

struct WelcomeView: View {
    @State private var showingLogin = false
    @State private var showingRegister = false
    @StateObject private var authService = FirebaseAuthService.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "1A1D23"), Color(hex: "2C3E50")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FF6B35"), Color(hex: "FFD700")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("ForgeFlow PRO")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Forge Your Best Day")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    // Sign Up Button
                    Button(action: { showingRegister = true }) {
                        Text("Create Account")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FF6B35"), Color(hex: "E74C3C")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    
                    // Sign In Button
                    Button(action: { showingLogin = true }) {
                        Text("Sign In")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Guest Mode Button
                    Button(action: { signInAsGuest() }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Continue as Guest")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 30)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
        .overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
    }
    
    func signInAsGuest() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signInAsGuest()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = FirebaseAuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingForgotPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Sign in to continue")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                        
                        // Form
                        VStack(spacing: 16) {
                            // Email field
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
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                SecureField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Enter password").foregroundColor(.gray.opacity(0.5))
                                    }
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            // Forgot password
                            HStack {
                                Spacer()
                                Button(action: { showingForgotPassword = true }) {
                                    Text("Forgot Password?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "4A90E2"))
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        
                        // Sign in button
                        Button(action: signIn) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "4A90E2"), Color(hex: "5DADE2")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 30)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1.0)
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
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

// MARK: - Register View

struct RegisterView: View {
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
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Start forging your best day")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                        
                        // Form
                        VStack(spacing: 16) {
                            // Name field
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
                            
                            // Email field
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
                            
                            // Password field
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
                            
                            // Confirm password field
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
                            
                            // Password match indicator
                            if !password.isEmpty && !confirmPassword.isEmpty {
                                HStack {
                                    Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(password == confirmPassword ? .green : .red)
                                    Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                                        .font(.system(size: 14))
                                        .foregroundColor(password == confirmPassword ? .green : .red)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        
                        // Sign up button
                        Button(action: signUp) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "FF6B35"), Color(hex: "E74C3C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 30)
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.5)
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
        }
    }
    
    var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    func signUp() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signUp(email: email, password: password, displayName: displayName)
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

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = FirebaseAuthService.shared
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "4A90E2"))
                            .padding(.top, 40)
                        
                        Text("Reset Password")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Enter your email to receive a password reset link")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    // Email field
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
                    .padding(.horizontal, 30)
                    
                    // Messages
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    if let success = successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(success)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    }
                    
                    // Send button
                    Button(action: sendResetEmail) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Reset Link")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "4A90E2"))
                    .cornerRadius(16)
                    .padding(.horizontal, 30)
                    .disabled(isLoading || email.isEmpty)
                    .opacity(email.isEmpty ? 0.5 : 1.0)
                    
                    Spacer()
                }
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
        }
    }
    
    func sendResetEmail() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await authService.resetPassword(email: email)
                await MainActor.run {
                    successMessage = "Password reset email sent. Check your inbox."
                    isLoading = false
                    
                    // Auto-dismiss after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        presentationMode.wrappedValue.dismiss()
                    }
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

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Loading...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color(hex: "2C3E50"))
            .cornerRadius(16)
        }
    }
}

// MARK: - TextField Placeholder Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
