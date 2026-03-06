import SwiftUI

struct OnboardingContainerView: View {
    @State private var currentPage = 0
    @State private var showMainApp = false
    
    var body: some View {
        ZStack {
            if showMainApp {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingPagerView(currentPage: $currentPage, showMainApp: $showMainApp)
            }
        }
        .animation(.easeInOut, value: showMainApp)
    }
}

struct OnboardingPagerView: View {
    @Binding var currentPage: Int
    @Binding var showMainApp: Bool
    @State private var dragOffset: CGFloat = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to RoutineForge",
            description: "Your personal productivity forge where daily habits are crafted into lasting success",
            imageName: "flame.fill",
            color: Color(hex: "FF6B35"),
            animation: .forge
        ),
        OnboardingPage(
            title: "Build Unbreakable Habits",
            description: "Track streaks, visualize progress with heatmaps, and earn achievements as you forge consistency",
            imageName: "chart.bar.fill",
            color: Color(hex: "27AE60"),
            animation: .habits
        ),
        OnboardingPage(
            title: "Master Your Focus",
            description: "Pomodoro timers with ambient sounds and automatic Do Not Disturb mode for deep work",
            imageName: "timer",
            color: Color(hex: "4A90E2"),
            animation: .pomodoro
        ),
        OnboardingPage(
            title: "Templates & Checklists",
            description: "20+ ready-made routines from morning rituals to travel prep—start instantly or customize your own",
            imageName: "checklist",
            color: Color(hex: "9B59B6"),
            animation: .checklists
        ),
        OnboardingPage(
            title: "Track Your Journey",
            description: "Mood journal, energy levels, and insights—understand what fuels your best days",
            imageName: "heart.text.square.fill",
            color: Color(hex: "E74C3C"),
            animation: .journal
        )
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "1A1D23")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? pages[index].color : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 60)
                
                // Pager content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index], pageIndex: index, currentPage: $currentPage)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Bottom buttons
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        Text(currentPage == pages.count - 1 ? "Start Forging" : "Next")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: pages[currentPage].color.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            showMainApp = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
    let animation: AnimationType
    
    enum AnimationType {
        case forge, habits, pomodoro, checklists, journal
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let pageIndex: Int
    @Binding var currentPage: Int
    
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = 0
    @State private var textOpacity: Double = 0
    @State private var particleOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated icon section
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.color.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(iconScale)
                
                // Main icon
                Image(systemName: page.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(page.color)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
                
                // Animated particles for specific pages
                if page.animation == .forge {
                    ForgeParticles(color: page.color, offset: particleOffset)
                }
            }
            .frame(height: 250)
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                
                Text(page.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
                    .opacity(textOpacity)
            }
            
            Spacer()
        }
        .onChange(of: currentPage) { newValue in
            if newValue == pageIndex {
                animateEntry()
            }
        }
        .onAppear {
            if currentPage == pageIndex {
                animateEntry()
            }
        }
    }
    
    func animateEntry() {
        // Reset states
        iconScale = 0.5
        iconRotation = 0
        textOpacity = 0
        particleOffset = 0
        
        // Animate icon
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 15).delay(0.1)) {
            iconScale = 1.0
        }
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            iconRotation = page.animation == .pomodoro ? 360 : 10
        }
        
        // Animate text
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Animate particles
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            particleOffset = 100
        }
    }
}

struct ForgeParticles: View {
    let color: Color
    let offset: CGFloat
    
    var body: some View {
        ForEach(0..<6, id: \.self) { index in
            Circle()
                .fill(color.opacity(0.6))
                .frame(width: 6, height: 6)
                .offset(
                    x: cos(Double(index) * 60.0 * .pi / 180.0) * offset,
                    y: sin(Double(index) * 60.0 * .pi / 180.0) * offset
                )
                .opacity(1.0 - Double(offset) / 100.0)
        }
    }
}
