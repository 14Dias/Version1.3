// Views/Profile/EditProfileView.swift - VERSÃO CORRIGIDA
import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditProfileViewModel
    @State private var showSuccessAlert = false
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(user: user))
    }
    
    var body: some View {
        Form {
            Section("Informações do Perfil") {
                TextField("Nome de usuário", text: $viewModel.username)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                
                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .disabled(true) // Email será editável em versão futura com reautenticação
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button("Salvar Alterações") {
                    Task {
                        await saveProfile()
                    }
                }
                .disabled(!viewModel.hasChanges || viewModel.isLoading)
                .frame(maxWidth: .infinity)
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            
            Section("Sobre as Alterações") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("O nome de usuário é visível para você", systemImage: "person.fill")
                    Label("Alteração de email requer confirmação de senha", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Editar Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sucesso", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage)
        }
        .alert("Erro", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
            Button("OK") {
                viewModel.errorMessage = ""
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Salvando...")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
            }
        }
    }
    
    private func saveProfile() async {
        let success = await viewModel.updateProfile()
        if success {
            // CORREÇÃO: Usar o método público do AuthViewModel para atualizar o usuário
            await authViewModel.updateUserProfileFromService()
            showSuccessAlert = true
        }
    }
}
