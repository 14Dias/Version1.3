// ViewModels/ChangePasswordViewModel.swift - VERSÃO CORRIGIDA
import SwiftUI
import Combine
import FirebaseAuth // ADIÇÃO IMPORTANTE: Importar FirebaseAuth

@MainActor
class ChangePasswordViewModel: ObservableObject {
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    private let authService = AuthService.shared
    
    func changePassword() async -> Bool {
        // Validações
        guard !currentPassword.isEmpty else {
            errorMessage = "Digite sua senha atual"
            return false
        }
        
        guard !newPassword.isEmpty else {
            errorMessage = "Digite a nova senha"
            return false
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "A nova senha deve ter pelo menos 6 caracteres"
            return false
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "As senhas não coincidem"
            return false
        }
        
        guard newPassword != currentPassword else {
            errorMessage = "A nova senha deve ser diferente da atual"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        do {
            try await authService.updateUserPassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            successMessage = "Senha alterada com sucesso!"
            isLoading = false
            clearFields()
            return true
            
        } catch {
            errorMessage = handlePasswordError(error)
            isLoading = false
            return false
        }
    }
    
    private func handlePasswordError(_ error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Senha atual incorreta"
        case AuthErrorCode.weakPassword.rawValue:
            return "A nova senha é muito fraca"
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return "Por segurança, faça login novamente antes de alterar a senha"
        default:
            return "Erro ao alterar senha: \(error.localizedDescription)"
        }
    }
    
    private func clearFields() {
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
    }
    
    var canSubmit: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }
}
