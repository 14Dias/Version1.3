// Views/ContentView.swift - VERSÃO ATUALIZADA COM ONBOARDING
import SwiftUI
import FirebaseCore

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var treinoManager = TreinoManager()
    @State private var isAppReady = false
    @State private var showLoadingState = true
    @State private var initializationStep = "Preparando sua experiência..."
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        ZStack {
            if showLoadingState {
                // Tela de carregamento com shimmer effect
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        // Logo/Ícone do app com shimmer
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .blue.opacity(0.3), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .mask(Circle())
                        )
                        
                        // Texto com shimmer
                        VStack(spacing: 12) {
                            Text("FitTrack")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(initializationStep)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.blue)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                }
                .transition(.opacity)
            } else if isAppReady {
                // App pronto - conteúdo principal
                if !hasSeenOnboarding {
                    // Mostrar onboarding apenas na primeira vez
                    NavigationStack {
                        OnboardingView()
                            .environmentObject(authViewModel)
                    }
                    .transition(.opacity)
                } else if authViewModel.isAuthenticated && authViewModel.hasValidUser {
                    PaginaInicialView()
                        .environmentObject(authViewModel)
                        .environmentObject(treinoManager)
                        .environmentObject(errorHandler)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                        .environmentObject(errorHandler)
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showLoadingState)
        .animation(.easeInOut(duration: 0.5), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: isAppReady)
        .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
        .alert("Erro", isPresented: $errorHandler.showErrorAlert) {
            Button("OK") {
                errorHandler.clearError()
            }
        } message: {
            if let error = errorHandler.currentError {
                Text(error.errorDescription ?? "Erro desconhecido")
            }
        }
        .onAppear {
            initializeApp()
        }
        .onChange(of: authViewModel.currentUserUID) { newUID in
            if let uid = newUID {
                treinoManager.setup(userUID: uid)
            }
        }
    }
    
    private func initializeApp() {
        print("🟡 Iniciando inicialização do app...")
        
        // Simular passos de inicialização
        let steps = [
            ("Verificando conexão...", 1.0),
            ("Carregando seus dados...", 2.0),
            ("Quase pronto...", 3.0)
        ]
        
        for (index, (step, delay)) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation {
                    initializationStep = step
                }
                
                if index == steps.count - 1 {
                    completeInitialization()
                }
            }
        }
    }
    
    private func completeInitialization() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showLoadingState = false
                isAppReady = true
            }
            
            if let uid = authViewModel.currentUserUID {
                treinoManager.setup(userUID: uid)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
