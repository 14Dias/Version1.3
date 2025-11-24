import SwiftUI
import FirebaseAuth
import Combine

// MARK: - ViewModel
@MainActor
class SolicitarProfissionalViewModel: ObservableObject {
    @Published var nomeCompleto = ""
    @Published var cref = ""
    @Published var especialidade = "Personal Trainer"
    @Published var biografia = ""
    @Published var isLoading = false
    @Published var message = ""
    @Published var showSuccess = false
    @Published var showError = false
    
    private let firestoreService = FirestoreService()
    
    let especialidades = [
        "Personal Trainer",
        "Nutricionista",
        "Fisioterapeuta",
        "Médico do Esporte",
        "Outro"
    ]
    
    var isValid: Bool {
        !nomeCompleto.isEmpty && !cref.isEmpty && !biografia.isEmpty
    }
    
    func enviarSolicitacao() async {
        guard let userUID = Auth.auth().currentUser?.uid else {
            message = "Erro: Usuário não identificado."
            showError = true
            return
        }
        
        isLoading = true
        
        do {
            try await firestoreService.enviarSolicitacaoProfissional(
                userUID: userUID,
                nomeCompleto: nomeCompleto,
                cref: cref,
                especialidade: especialidade,
                biografia: biografia
            )
            
            message = "Sua solicitação foi enviada! Nossa equipe analisará seus dados em breve."
            showSuccess = true
            limparCampos()
            
        } catch {
            message = "Erro ao enviar: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    func limparCampos() {
        nomeCompleto = ""
        cref = ""
        biografia = ""
    }
}

// MARK: - View
struct SolicitarProfissionalView: View {
    @StateObject private var viewModel = SolicitarProfissionalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Dados Profissionais") {
                TextField("Nome Completo", text: $viewModel.nomeCompleto)
                    .textContentType(.name)
                
                TextField("Registro Profissional (CREF/CRM)", text: $viewModel.cref)
                    .textInputAutocapitalization(.characters)
                
                Picker("Especialidade", selection: $viewModel.especialidade) {
                    ForEach(viewModel.especialidades, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
            }
            
            Section("Sobre Você") {
                TextEditor(text: $viewModel.biografia)
                    .frame(height: 100)
                    .overlay(
                        Text(viewModel.biografia.isEmpty ? "Conte um pouco sobre sua experiência..." : "")
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 8)
                            .padding(.leading, 4),
                        alignment: .topLeading
                    )
            }
            
            Section {
                Button {
                    Task { await viewModel.enviarSolicitacao() }
                } label: {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Text("Enviar Solicitação")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                .disabled(!viewModel.isValid || viewModel.isLoading)
                .listRowBackground(
                    (!viewModel.isValid || viewModel.isLoading) ? Color.gray.opacity(0.2) : Color.blue
                )
                .foregroundColor((!viewModel.isValid || viewModel.isLoading) ? .gray : .white)
            } footer: {
                Text("Ao enviar, você confirma que possui as credenciais informadas. O uso indevido pode resultar em suspensão da conta.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Sou Profissional")
        .alert("Solicitação Enviada", isPresented: $viewModel.showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text(viewModel.message)
        }
        .alert("Erro", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.message)
        }
    }
}

#Preview {
    NavigationStack {
        SolicitarProfissionalView()
    }
}
