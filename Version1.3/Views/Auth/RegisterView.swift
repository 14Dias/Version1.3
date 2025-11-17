// Views/Auth/RegisterView.swift - VERSÃO COM OUTLINES
import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Environment(\.dismiss) private var dismiss
    
    // Estados para controlar o foco e outlines
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Criar Conta")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    // Campo Nome de Usuário
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nome de usuário")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Digite seu nome de usuário", text: $username)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(borderColor(for: .username), lineWidth: 2)
                            )
                            .focused($focusedField, equals: .username)
                            .onSubmit {
                                focusedField = .email
                            }
                    }
                    
                    // Campo Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Digite seu email", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(borderColor(for: .email), lineWidth: 2)
                            )
                            .focused($focusedField, equals: .email)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    
                    // Campo Senha
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Senha")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("Digite sua senha", text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(borderColor(for: .password), lineWidth: 2)
                            )
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                focusedField = .confirmPassword
                            }
                    }
                    
                    // Campo Confirmar Senha
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirmar Senha")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("Confirme sua senha", text: $confirmPassword)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(borderColor(for: .confirmPassword), lineWidth: 2)
                            )
                            .focused($focusedField, equals: .confirmPassword)
                            .onSubmit {
                                focusedField = nil
                                Task {
                                    await registerUser()
                                }
                            }
                    }
                    
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
                
                Spacer()
            }
            .padding()
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
            .onAppear {
                // Focar no primeiro campo quando a view aparecer
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .username
                }
            }
        }
    }
    
    // Função para determinar a cor da borda baseada no estado do campo
    private func borderColor(for field: Field) -> Color {
        if focusedField == field {
            return .blue // Cor quando focado
        } else if hasError(in: field) {
            return .red // Cor quando há erro
        } else {
            return .gray.opacity(0.3) // Cor padrão
        }
    }
    
    // Função para verificar se há erro relacionado ao campo
    private func hasError(in field: Field) -> Bool {
        guard !authViewModel.errorMessage.isEmpty else { return false }
        
        switch field {
        case .username:
            return username.isEmpty
        case .email:
            return email.isEmpty || !isValidEmail(email)
        case .password:
            return password.isEmpty || password.count < 6
        case .confirmPassword:
            return confirmPassword.isEmpty || password != confirmPassword
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
            focusedField = .confirmPassword
            return
        }
        
        // Verificação de comprimento da senha
        guard password.count >= 6 else {
            authViewModel.errorMessage = "A senha deve ter pelo menos 6 caracteres"
            focusedField = .password
            return
        }
        
        // Verificação de email válido
        guard isValidEmail(email) else {
            authViewModel.errorMessage = "Por favor, insira um email válido"
            focusedField = .email
            return
        }
        
        let success = await authViewModel.signUp(
            username: username,
            email: email,
            password: password
        )
        
        if success {
            print("🟢 Registro bem-sucedido, fazendo dismiss...")
            dismiss()
        } else {
            print("🔴 Falha no registro: \(authViewModel.errorMessage)")
            // Focar no campo apropriado baseado no erro
            if authViewModel.errorMessage.contains("email") {
                focusedField = .email
            } else if authViewModel.errorMessage.contains("senha") {
                focusedField = .password
            }
        }
    }
}
