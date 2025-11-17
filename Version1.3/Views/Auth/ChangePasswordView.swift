// Views/Profile/ChangePasswordView.swift - NOVO ARQUIVO
import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChangePasswordViewModel()
    @State private var showSuccessAlert = false
    
    var body: some View {
        Form {
            Section("Alteração de Senha") {
                SecureField("Senha Atual", text: $viewModel.currentPassword)
                
                SecureField("Nova Senha", text: $viewModel.newPassword)
                
                SecureField("Confirmar Nova Senha", text: $viewModel.confirmPassword)
            }
            
            Section {
                if !viewModel.newPassword.isEmpty {
                    PasswordStrengthView(password: viewModel.newPassword)
                }
                
                Button("Alterar Senha") {
                    Task {
                        await changePassword()
                    }
                }
                .disabled(!viewModel.canSubmit || viewModel.isLoading)
                .frame(maxWidth: .infinity)
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            
            Section("Requisitos da Senha") {
                VStack(alignment: .leading, spacing: 6) {
                    RequirementRow(met: viewModel.newPassword.count >= 6, text: "Pelo menos 6 caracteres")
                    RequirementRow(met: viewModel.newPassword == viewModel.confirmPassword && !viewModel.newPassword.isEmpty, text: "Senhas coincidem")
                    RequirementRow(met: viewModel.newPassword != viewModel.currentPassword && !viewModel.newPassword.isEmpty, text: "Diferente da senha atual")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Alterar Senha")
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
    }
    
    private func changePassword() async {
        let success = await viewModel.changePassword()
        if success {
            showSuccessAlert = true
        }
    }
}

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: (color: Color, text: String) {
        if password.count < 6 {
            return (.red, "Fraca")
        } else if password.count < 8 {
            return (.orange, "Média")
        } else {
            return (.green, "Forte")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Força da senha:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(strength.text)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(strength.color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(strength.color)
                        .frame(width: progressWidth(width: geometry.size.width), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    private func progressWidth(width: CGFloat) -> CGFloat {
        let progress = min(Double(password.count) / 12.0, 1.0)
        return width * CGFloat(progress)
    }
}

struct RequirementRow: View {
    let met: Bool
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .gray)
            Text(text)
                .foregroundColor(met ? .primary : .secondary)
        }
    }
}
