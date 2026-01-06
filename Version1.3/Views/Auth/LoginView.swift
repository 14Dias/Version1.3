// Views/Auth/LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var showingForgotPassword = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)
                    
                    Text("Trainar")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    SecureField("Senha", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Botão Entrar (Email)
                    Button(action: {
                        Task { await authViewModel.signIn(email: email, password: password) }
                    }) {
                        Text("Entrar")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                    .opacity((authViewModel.isLoading || email.isEmpty || password.isEmpty) ? 0.7 : 1.0)
                    
                    /* Divisor
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                        Text("OU").font(.caption).foregroundColor(.secondary)
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.vertical, 5)
                    
                   // Botão Google (NOVO)
                    Button {
                        Task { await authViewModel.signInWithGoogle() }
                    } label: {
                        HStack {
                            Image("google")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30) 
                                .font(.title3)
                            
                            Text("Entrar com Google")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }*/
                }
                .padding(.horizontal, 30)
                
                // Links
                VStack(spacing: 15) {
                    Button("Criar uma conta") {
                        showingRegister = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Esqueci minha senha") {
                        showingForgotPassword = true
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $showingRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
            .overlay {
                if authViewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Processando...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}
#Preview {
    LoginView()
}
