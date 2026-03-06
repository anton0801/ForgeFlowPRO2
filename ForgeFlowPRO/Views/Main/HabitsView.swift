import SwiftUI

struct HabitsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: HabitViewModel
    @State private var showingAddSheet = false
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: HabitViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1A1D23").ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.habits) { habit in
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                HabitCard(habit: habit)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
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
                                .background(Color(hex: "27AE60"))
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        .padding(30)
                    }
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddSheet) {
                AddHabitSheet(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.fetchHabits()
        }
    }
}

struct HabitCard: View {
    @ObservedObject var habit: Item
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: habit.iconName ?? "star.fill")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: habit.colorHex ?? "FF6B35"))
                .frame(width: 60, height: 60)
                .background(Color(hex: habit.colorHex ?? "FF6B35").opacity(0.2))
                .clipShape(Circle())
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                        Text("\(habit.streakCurrent)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14))
                        Text("\(habit.streakRecord)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.yellow)
                    
                    HStack(spacing: 4) {
                        Text("Lv")
                            .font(.system(size: 12, weight: .bold))
                        Text("\(habit.level)")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "4A90E2"))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}
