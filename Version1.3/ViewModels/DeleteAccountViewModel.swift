// ViewModels/DeleteAccountViewModel.swift
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
class DeleteAccountViewModel: ObservableObject {
    @Published var password = ""
    @Published var confirmationText = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showConfirmation = false
    
    private let authService = AuthService.shared
    
    func deleteAccount() async -> Bool {
        guard !password.isEmpty else {
            errorMessage = "Digite sua senha para confirmar"
            return false
        }
        
        guard confirmationText.lowercased() == "deletar minha conta" else {
            errorMessage = "Digite exatamente 'deletar minha conta' para confirmar"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.deleteUserAccount(password: password)
            isLoading = false
            return true
        } catch {
            errorMessage = handleDeleteError(error)
            isLoading = false
            return false
        }
    }
    
    private func handleDeleteError(_ error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Senha incorreta"
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return "Por segurança, faça login novamente antes de deletar a conta"
        default:
            return "Erro ao deletar conta: \(error.localizedDescription)"
        }
    }
    
    var canDelete: Bool {
        !password.isEmpty &&
        confirmationText.lowercased() == "deletar minha conta"
    }
}
