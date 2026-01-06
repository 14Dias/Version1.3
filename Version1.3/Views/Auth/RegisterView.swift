// Views/Auth/RegisterView.swift - VERSÃO CORRIGIDA
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isHealthProfessional = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Criar Conta")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Campos (mantenha como estava)
                        TextField("Nome de usuário", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .autocorrectionDisabled()
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                        
                        SecureField("Senha", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("Confirmar Senha", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        /* //Toggle Profissional de Saúde
                        Toggle("Sou profissional da saúde", isOn: $isHealthProfessional)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .padding()*/
                        
                        if !authViewModel.errorMessage.isEmpty {
                            Text(authViewModel.errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button("Criar Conta") {
                            Task {
                                await registerUser()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canRegister)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .navigationTitle("Registro")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if authViewModel.isLoading {
                    ProgressView("Criando conta...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private var canRegister: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func registerUser() async {
        // Verificação de senha
        guard password == confirmPassword else {
            authViewModel.errorMessage = "As senhas não coincidem"
            return
        }
        
        // Verificação de comprimento da senha
        guard password.count >= 6 else {
            authViewModel.errorMessage = "A senha deve ter pelo menos 6 caracteres"
            return
        }
        
        // Verificação de email válido
        guard isValidEmail(email) else {
            authViewModel.errorMessage = "Por favor, insira um email válido"
            return
        }
        
        // CORREÇÃO: Chamada simplificada - removendo isHealthProfessional temporariamente
        let success = await authViewModel.signUp(
            username: username,
            email: email,
            password: password
            // Removido temporariamente: isHealthProfessional: isHealthProfessional
        )
        
        if success {
            print("🟢 Registro bem-sucedido, fazendo dismiss...")
            dismiss()
        } else {
            print("🔴 Falha no registro: \(authViewModel.errorMessage)")
        }
    }
}
