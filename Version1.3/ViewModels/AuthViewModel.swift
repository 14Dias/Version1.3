// ViewModels/AuthViewModel.swift
import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // NOVO: Propriedade para acessar o userUID facilmente
    var currentUserUID: String? {
        return user?.userUID
    }
    
    // NOVO: Propriedade para verificar se temos um usuário válido
    var hasValidUser: Bool {
        return isAuthenticated && currentUserUID != nil
    }
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let authService = AuthService.shared
    
    init() {
        setupAuthListener()
        checkCurrentUser()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Auth State Management
    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    self?.user = self?.authService.getCurrentAppUser()
                    self?.isAuthenticated = true
                    self?.errorMessage = ""
                    print("🟢 AuthListener: Usuário autenticado - \(firebaseUser.uid)")
                } else {
                    self?.user = nil
                    self?.isAuthenticated = false
                    print("🟢 AuthListener: Usuário não autenticado")
                }
            }
        }
    }
    
    private func checkCurrentUser() {
        if let currentUser = authService.getCurrentAppUser() {
            self.user = currentUser
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Auth Methods - CORREÇÃO COMPLETA
    func signUp(username: String, email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = ""
        
        print("🟡 AuthViewModel: Iniciando signUp para \(email)")
        
        // Validações básicas
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Todos os campos são obrigatórios"
            isLoading = false
            return false
        }
        
        guard password.count >= 6 else {
            errorMessage = "A senha deve ter pelo menos 6 caracteres"
            isLoading = false
            return false
        }
        
        do {
            // CORREÇÃO: Chamar o método real do AuthService
            try await authService.signUp(username: username, email: email, password: password)
            isLoading = false
            print("🟢 AuthViewModel: SignUp bem-sucedido")
            return true
        } catch {
            errorMessage = handleAuthError(error)
            isLoading = false
            print("🔴 AuthViewModel: Erro no signUp - \(errorMessage)")
            return false
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = ""
        
        print("🟡 AuthViewModel: Iniciando signIn para \(email)")
        
        do {
            try await authService.signIn(email: email, password: password)
            isLoading = false
            print("🟢 AuthViewModel: SignIn bem-sucedido")
            return true
        } catch {
            errorMessage = handleAuthError(error)
            isLoading = false
            print("🔴 AuthViewModel: Erro no signIn - \(errorMessage)")
            return false
        }
    }
    
    func signOut() {
        isLoading = true
        errorMessage = ""
        
        do {
            try authService.signOut()
            isLoading = false
            print("🟢 AuthViewModel: SignOut bem-sucedido")
        } catch {
            errorMessage = handleAuthError(error)
            isLoading = false
            print("🔴 AuthViewModel: Erro no signOut - \(errorMessage)")
        }
    }
    
    func resetPassword(email: String) async -> Bool {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.resetPassword(email: email)
            isLoading = false
            print("🟢 AuthViewModel: ResetPassword bem-sucedido")
            return true
        } catch {
            errorMessage = handleAuthError(error)
            isLoading = false
            print("🔴 AuthViewModel: Erro no resetPassword - \(errorMessage)")
            return false
        }
    }
    
    // MARK: - Error Handling
    private func handleAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Senha incorreta"
        case AuthErrorCode.userNotFound.rawValue:
            return "Usuário não encontrado"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Email já está em uso"
        case AuthErrorCode.weakPassword.rawValue:
            return "Senha muito fraca"
        case AuthErrorCode.networkError.rawValue:
            return "Erro de conexão com a internet"
        case AuthErrorCode.invalidEmail.rawValue:
            return "Email inválido"
        case AuthErrorCode.userDisabled.rawValue:
            return "Conta desativada"
        case 17004: // The supplied auth credential is malformed or has expired
            return "Credenciais inválidas ou expiradas. Verifique seu email e senha."
        default:
            return "Erro de autenticação: \(error.localizedDescription)"
        }
    }
}
extension AuthViewModel {
        // MARK: - Profile Management
        func updateUserProfile(username: String) async -> Bool {
            isLoading = true
            errorMessage = ""
            
            do {
                try await authService.updateUserProfile(username: username)
                
                // Atualizar o usuário local
                if let currentUser = authService.getCurrentAppUser() {
                    self.user = currentUser
                }
                
                isLoading = false
                return true
            } catch {
                errorMessage = handleAuthError(error)
                isLoading = false
                return false
            }
        }
        
        func updateUserPassword(currentPassword: String, newPassword: String) async -> Bool {
            isLoading = true
            errorMessage = ""
            
            do {
                try await authService.updateUserPassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                
                isLoading = false
                return true
            } catch {
                errorMessage = handleAuthError(error)
                isLoading = false
                return false
            }
        }
    }

// ViewModels/AuthViewModel.swift - ADICIONAR ESTE MÉTODO
extension AuthViewModel {
    func deleteCurrentUserAccount(password: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado"])
        }
        
        print("🟡 AuthViewModel: Iniciando exclusão da conta")
        
        // Reautenticar o usuário
        let credential = EmailAuthProvider.credential(withEmail: currentUser.email ?? "", password: password)
        try await currentUser.reauthenticate(with: credential)
        
        // Deletar dados do Firestore primeiro
        try await AuthService.shared.deleteUserData(userUID: currentUser.uid)
        
        // Deletar conta do Auth
        try await currentUser.delete()
        
        print("✅ Conta deletada com sucesso via AuthViewModel")
    }
    func updateUserProfileFromService() async {
            // Atualizar o usuário a partir do AuthService
            if let currentUser = authService.getCurrentAppUser() {
                await MainActor.run {
                    self.user = currentUser
                }
            }
        }
}
extension AuthViewModel {
    func getCurrentUserUID() -> String {
        guard let uid = currentUserUID, !uid.isEmpty else {
            print("❌ ERRO CRÍTICO: UserUID não disponível no AuthViewModel")
            // Tentar recuperar do Firebase Auth diretamente
            if let firebaseUser = Auth.auth().currentUser {
                let uid = firebaseUser.uid
                print("🟢 UserUID recuperado do Firebase Auth: \(uid)")
                return uid
            }
            return ""
        }
        return uid
    }
}
