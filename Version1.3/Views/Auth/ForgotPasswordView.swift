// Views/Auth/ForgotPasswordView.swift
import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var showSuccessAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Recuperar Senha")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Digite seu email para redefinir a senha")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // Form
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    if !authViewModel.errorMessage.isEmpty {
                        Text(authViewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button("Enviar Link de Redefinição") {
                        Task {
                            // CORREÇÃO: Use await e capture o resultado
                            let success = await authViewModel.resetPassword(email: email)
                            if success {
                                showSuccessAlert = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(authViewModel.isLoading || email.isEmpty)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Recuperar Senha")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Email Enviado", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Enviamos um link de redefinição de senha para o seu email.")
            }
            .overlay {
                if authViewModel.isLoading {
                    ProgressView("Enviando...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthViewModel())
}
