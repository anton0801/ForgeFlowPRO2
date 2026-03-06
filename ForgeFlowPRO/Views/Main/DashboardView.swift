import SwiftUI

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DashboardViewModel
    @StateObject private var pomodoroVM: PomodoroViewModel
    @State private var showingAddSheet = false
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: DashboardViewModel(context: context))
        _pomodoroVM = StateObject(wrappedValue: PomodoroViewModel())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "1A1D23"), Color(hex: "2C3E50")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(viewModel.greeting), \(viewModel.userName)!")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                NavigationLink(destination: SettingsView()
                                    .navigationBarBackButtonHidden(true)) {
                                    Image(systemName: "gear")
                                        .foregroundColor(.white)
                                }
                            }
                            
                            HStack {
                                Text("Your forge awaits")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                CircularProgressView(progress: viewModel.completionRate)
                                    .frame(width: 50, height: 50)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Pomodoro Timer (if active)
                        if pomodoroVM.isRunning {
                            PomodoroCardView(viewModel: pomodoroVM)
                                .padding(.horizontal)
                        }
                        
                        // Today's Items
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Today's Focus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            if viewModel.todayItems.isEmpty {
                                EmptyStateView()
                                    .padding()
                            } else {
                                ForEach(viewModel.todayItems) { item in
                                    DashboardItemCard(item: item) {
                                        viewModel.toggleItem(item)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
                
                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "FF6B35"), Color(hex: "E74C3C")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Color(hex: "FF6B35").opacity(0.5), radius: 15, x: 0, y: 5)
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSheet) {
                AddItemSheet()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onAppear {
            viewModel.fetchTodayItems()
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "27AE60"), Color(hex: "2ECC71")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct DashboardItemCard: View {
    let item: Item
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: item.iconName ?? "circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: item.colorHex ?? "4A90E2"))
                .frame(width: 40, height: 40)
                .background(Color(hex: item.colorHex ?? "4A90E2").opacity(0.2))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                if item.type == .habit {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                        Text("\(item.streakCurrent) day streak")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.isCompletedToday() ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundColor(item.isCompletedToday() ? Color(hex: "27AE60") : .gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct PomodoroCardView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Focus Session")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.timeRemaining) / CGFloat(viewModel.currentMode.duration))
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "4A90E2"), Color(hex: "5DADE2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: viewModel.timeRemaining)
                
                VStack(spacing: 4) {
                    Text(timeString(from: viewModel.timeRemaining))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(viewModel.currentMode == .work ? "Work" : "Break")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 180, height: 180)
            
            HStack(spacing: 20) {
                Button(action: { viewModel.isRunning ? viewModel.pauseTimer() : viewModel.startTimer() }) {
                    Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color(hex: "4A90E2"))
                        .clipShape(Circle())
                }
                
                Button(action: { viewModel.resetTimer() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color(hex: "2C3E50").opacity(0.8), Color(hex: "34495E").opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    func timeString(from seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No tasks for today")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Text("Tap + to forge your first routine")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
