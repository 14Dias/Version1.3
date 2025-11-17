// ViewModels/EditProfileViewModel.swift - VERSÃO CORRIGIDA
import SwiftUI
import Combine

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var username: String
    @Published var email: String
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    // MUDANÇA: Remover 'private' para tornar acessível
    let authService = AuthService.shared
    private let originalUsername: String
    private let originalEmail: String
    
    init(user: User) {
        self.username = user.username
        self.email = user.email
        self.originalUsername = user.username
        self.originalEmail = user.email
    }
    
    var hasChanges: Bool {
        username != originalUsername || email != originalEmail
    }
    
    func updateProfile() async -> Bool {
        guard hasChanges else {
            errorMessage = "Nenhuma alteração foi feita"
            return false
        }
        
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "O nome de usuário não pode estar vazio"
            return false
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Por favor, insira um email válido"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        do {
            // Atualizar username se mudou
            if username != originalUsername {
                try await authService.updateUserProfile(username: username)
            }
            
            // Atualizar email se mudou (será implementado depois com reautenticação)
            if email != originalEmail {
                successMessage = "Username atualizado com sucesso! Para alterar o email, é necessário confirmar sua senha."
            } else {
                successMessage = "Perfil atualizado com sucesso!"
            }
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Erro ao atualizar perfil: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
   
    }
    
}

