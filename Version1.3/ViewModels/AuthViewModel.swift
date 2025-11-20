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
    
    // MARK: - Google Sign In (NOVO)
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
    
    func updateUserProfileFromService() async {
        if let currentUser = authService.getCurrentAppUser() {
            await MainActor.run {
                self.user = currentUser
            }
        }
    }
    
    func getCurrentUserUID() -> String {
        guard let uid = currentUserUID, !uid.isEmpty else {
            if let firebaseUser = Auth.auth().currentUser {
                return firebaseUser.uid
            }
            return ""
        }
        return uid
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
