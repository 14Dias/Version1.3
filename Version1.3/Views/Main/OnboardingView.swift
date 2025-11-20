// Views/Onboarding/OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = OnboardingViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.9), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Bem-vindo ao Trainar")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Sua jornada fitness começa aqui")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // Features
                VStack(spacing: 20) {
                    FeatureRow(icon: "dumbbell.fill", text: "Crie treinos personalizados")
                    FeatureRow(icon: "heart.fill", text: "Acompanhe seu progresso")
                    FeatureRow(icon: "star.fill", text: "Treinos em destaque")
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    // Login com Google
                    Button {
                        Task {
                            await loginWithGoogle()
                        }
                    } label: {
                        HStack {
                            Image("google")
                                .resizable()
                                .scaledToFit()
                                .font(.title3)
                            
                            Text("Continuar com Google")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .disabled(viewModel.isLoading)
                    
                    // Login com Email

                        Button{
                            Task {
                                LoginView()
                            }
                          
                        } label: {
                            HStack {
                                Image(systemName: "envelope")
                                    .font(.title3)
                                
                                Text("Continuar com e-mail")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.white)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                ProgressView("Conectando...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func loginWithGoogle() async {
        let success = await viewModel.signInWithGoogle()
        if success {
            // Marcar que o usuário já viu o onboarding
            hasSeenOnboarding = true
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 30)
            
            Text(text)
                .foregroundColor(.white)
                .font(.body)
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}
