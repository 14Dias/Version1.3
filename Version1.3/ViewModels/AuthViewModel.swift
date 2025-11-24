// ViewModels/AuthViewModel.swift
import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // Propriedades computadas auxiliares
    var currentUserUID: String? {
        return user?.userUID
    }
    
    var hasValidUser: Bool {
        return isAuthenticated && currentUserUID != nil
    }
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let authService = AuthService.shared
    private let firestoreService = FirestoreService()
    
    init() {
        setupAuthListener()
        // checkCurrentUser() -> Removido pois o listener já dispara ao iniciar
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Auth State Management
    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let firebaseUser = firebaseUser {
                    // MUDANÇA PRINCIPAL:
                    // Em vez de apenas pegar os dados do Auth, buscamos no Firestore
                    // para garantir que temos o 'isHealthProfessional'
                    await self.fetchFirestoreUser(uid: firebaseUser.uid)
                } else {
                    self.user = nil
                    self.isAuthenticated = false
                    self.errorMessage = ""
                    print("🟢 AuthListener: Usuário não autenticado")
                }
            }
        }
    }
    
    // NOVA FUNÇÃO: Busca os dados completos no Firestore
    func fetchFirestoreUser(uid: String) async {
        do {
            // Tenta buscar o documento completo do usuário
            if let userCompleto = try await firestoreService.fetchUserData(userUID: uid) {
                self.user = userCompleto
                self.isAuthenticated = true
                print("🟢 AuthViewModel: Dados carregados do Firestore (Profissional: \(userCompleto.isHealthProfessional))")
            } else {
                // Fallback: Se não achar no banco, usa os dados básicos do Auth
                self.user = authService.getCurrentAppUser()
                self.isAuthenticated = true
                print("⚠️ AuthViewModel: Usuário não encontrado no Firestore, usando dados básicos.")
            }
        } catch {
            print("🔴 Erro ao buscar no Firestore: \(error.localizedDescription)")
            // Fallback em caso de erro
            self.user = authService.getCurrentAppUser()
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Email/Password Auth Methods
    func signUp(username: String, email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = ""
        
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
            try await authService.signUp(username: username, email: email, password: password)
            // O Listener vai pegar a mudança automaticamente
            isLoading = false
            return true
        } catch {
            errorMessage = handleAuthError(error)
            isLoading = false
            return false
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.signIn(email: email, password: password)
            // O Listener cuida do resto
            isLoading = false
            return true
        } catch {
            errorMessage = handleAuthError(error)
            isLoading = false
            return false
        }
    }
    
    func signOut() {
        isLoading = true
        errorMessage = ""
        
        do {
            try authService.signOut()
            isLoading = false
            // Listener atualizará o estado para nil
        } catch {
            errorMessage = handleAuthError(error)
            isLoading = false
        }
    }
    
    func resetPassword(email: String) async -> Bool {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.resetPassword(email: email)
            isLoading = false
            return true
        } catch {
            errorMessage = handleAuthError(error)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async -> Bool {
        isLoading = true
        errorMessage = ""
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Erro de configuração do Firebase"
            isLoading = false
            return false
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Erro interno de UI"
            isLoading = false
            return false
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user
            guard let idToken = user.idToken?.tokenString else {
                throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erro no token do Google"])
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Se for novo usuário, salvar no Firestore
            if let additionalUserInfo = authResult.additionalUserInfo, additionalUserInfo.isNewUser {
                let appUser = User(
                    username: user.profile?.name ?? "Usuário Google",
                    email: user.profile?.email ?? "",
                    userUID: authResult.user.uid
                )
                try await firestoreService.saveUserData(user: appUser)
            }
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Erro no Login Google: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Profile Management
    func updateUserProfile(username: String) async -> Bool {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.updateUserProfile(username: username)
            // Após atualizar, recarregamos os dados para manter tudo sincronizado
            await refreshUserData()
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
            try await authService.updateUserPassword(currentPassword: currentPassword, newPassword: newPassword)
            isLoading = false
            return true
        } catch {
            errorMessage = handleAuthError(error)
            isLoading = false
            return false
        }
    }
    
    func deleteCurrentUserAccount(password: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado"])
        }
        
        let credential = EmailAuthProvider.credential(withEmail: currentUser.email ?? "", password: password)
        try await currentUser.reauthenticate(with: credential)
        try await AuthService.shared.deleteUserData(userUID: currentUser.uid)
        try await currentUser.delete()
    }
    
    // Método auxiliar para forçar atualização (usado na PerfilView ou após edições)
    func refreshUserData() async {
        if let uid = currentUserUID {
            await fetchFirestoreUser(uid: uid)
        }
    }
    
    // Substitui o método antigo e usa a nova lógica
    func updateUserProfileFromService() async {
        await refreshUserData()
    }
    
    func getCurrentUserUID() -> String {
        return currentUserUID ?? ""
    }
    
    // MARK: - Error Handling
    private func handleAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue: return "Senha incorreta"
        case AuthErrorCode.userNotFound.rawValue: return "Usuário não encontrado"
        case AuthErrorCode.emailAlreadyInUse.rawValue: return "Email já está em uso"
        case AuthErrorCode.weakPassword.rawValue: return "Senha muito fraca"
        case AuthErrorCode.networkError.rawValue: return "Erro de conexão com a internet"
        case AuthErrorCode.invalidEmail.rawValue: return "Email inválido"
        case AuthErrorCode.userDisabled.rawValue: return "Conta desativada"
        default: return "Erro: \(error.localizedDescription)"
        }
    }
}
