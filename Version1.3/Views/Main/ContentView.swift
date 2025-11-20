// Views/ContentView.swift - VERSÃO MINIMALISTA
import SwiftUI
import FirebaseCore

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var treinoManager = TreinoManager()
    @State private var isAppReady = false
    @State private var showLoadingState = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        ZStack {
            if showLoadingState {
                // Tela de carregamento minimalista
                VStack(spacing: 20) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Trainar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .transition(.opacity)
            } else if isAppReady {
                // Lógica principal da aplicação
                if authViewModel.isAuthenticated {
                    PaginaInicialView()
                        .environmentObject(authViewModel)
                        .environmentObject(treinoManager)
                        .environmentObject(errorHandler)
                        .transition(.opacity)
                        .onAppear {
                            if !hasSeenOnboarding {
                                hasSeenOnboarding = true
                            }
                        }
                } else if !hasSeenOnboarding {
                    OnboardingView()
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                        .environmentObject(errorHandler)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showLoadingState)
        .animation(.easeInOut(duration: 0.3), value: isAppReady)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
        .alert("Erro", isPresented: $errorHandler.showErrorAlert) {
            Button("OK") { errorHandler.clearError() }
        } message: {
            if let error = errorHandler.currentError {
                Text(error.errorDescription ?? "Erro desconhecido")
            }
        }
        .onAppear {
            initializeApp()
        }
        .onChange(of: authViewModel.currentUserUID) { newUID in
            if let uid = newUID, !uid.isEmpty {
                treinoManager.setup(userUID: uid)
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                if !hasSeenOnboarding {
                    hasSeenOnboarding = true
                }
                if let uid = authViewModel.currentUserUID {
                    treinoManager.setup(userUID: uid)
                }
            }
        }
    }
    
    private func initializeApp() {
        print("🟡 Iniciando app...")
        
        // Verificação rápida se usuário já está autenticado
        if authViewModel.isAuthenticated && !hasSeenOnboarding {
            hasSeenOnboarding = true
        }
        
        // Chama a completeInitialization imediatamente após carregar
        completeInitialization()
    }
    
    private func completeInitialization() {
        // Transição imediata para o conteúdo principal
        withAnimation(.easeInOut(duration: 0.5)) {
            showLoadingState = false
            isAppReady = true
        }
        
        print("🟢 App inicializado:")
        print("   - Autenticado: \(authViewModel.isAuthenticated)")
        print("   - UserUID: \(authViewModel.currentUserUID ?? "nil")")
        
        // Configurar treinoManager se usuário estiver autenticado
        if authViewModel.isAuthenticated, let uid = authViewModel.currentUserUID, !uid.isEmpty {
            treinoManager.setup(userUID: uid)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
