// Views/Auth/DeleteAccountView.swift - VERSÃO CORRIGIDA
import SwiftUI
import FirebaseAuth

struct DeleteAccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showFinalConfirmation = false
    
    private var canDelete: Bool {
        !password.isEmpty &&
        confirmationText.lowercased() == "deletar minha conta"
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text("Excluir Conta Permanentemente")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Esta ação não pode ser desfeita. Todos os seus dados, treinos e histórico serão permanentemente removidos.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Confirmação de Segurança") {
                SecureField("Digite sua senha", text: $password)
                    .textContentType(.password)
                
            }
            
            Section {
                Button("Excluir Minha Conta", role: .destructive) {
                    if canDelete {
                        showFinalConfirmation = true
                    }
                }
                .disabled(!canDelete || isDeleting)
                .frame(maxWidth: .infinity)
                
                if isDeleting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }

            if let message = errorMessage {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Excluir Conta")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Tem certeza que deseja excluir sua conta permanentemente?",
            isPresented: $showFinalConfirmation,
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Esta ação não pode ser desfeita. Todos os seus dados serão permanentemente removidos.")
        }
    }

    @MainActor
    private func deleteAccount() async {
        guard !isDeleting else { return }
        isDeleting = true
        errorMessage = nil
        
        do {
            try await authViewModel.deleteCurrentUserAccount(password: password)
            dismiss()
        } catch {
            errorMessage = handleDeleteError(error)
        }
        isDeleting = false
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
}
