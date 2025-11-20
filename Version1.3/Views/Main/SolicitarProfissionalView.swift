
import SwiftUI

struct SolicitarProfissionalView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var nomeCompleto = ""
    @State private var cref = ""
    @State private var especialidade = "Musculação"
    @State private var biografia = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    
    private let firestoreService = FirestoreService()
    
    let especialidades = ["Musculação", "Crossfit", "Yoga", "Pilates", "Funcional", "Corrida", "Outro"]
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Torne-se um Profissional")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Profissionais podem criar treinos públicos e gerenciar alunos na plataforma.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Dados Profissionais") {
                TextField("Nome Completo", text: $nomeCompleto)
                    .textInputAutocapitalization(.words)
                
                TextField("Registro Profissional (CREF/Outros)", text: $cref)
                    .textInputAutocapitalization(.characters)
                
                Picker("Especialidade Principal", selection: $especialidade) {
                    ForEach(especialidades, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
            }
            
            Section("Apresentação") {
                TextField("Conte um pouco sobre sua experiência...", text: $biografia, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section {
                Button {
                    enviarSolicitacao()
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Enviar Solicitação")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(Color.blue)
                .disabled(isLoading || nomeCompleto.isEmpty || cref.isEmpty)
            }
            
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Área Profissional")
        .alert("Solicitação Enviada!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Sua solicitação foi recebida. Nossa equipe analisará seus dados e entraremos em contato em breve.")
        }
    }
    
    private func enviarSolicitacao() {
        guard let uid = authViewModel.currentUserUID else { return }
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await firestoreService.enviarSolicitacaoProfissional(
                    userUID: uid,
                    nomeCompleto: nomeCompleto,
                    cref: cref,
                    especialidade: especialidade,
                    biografia: biografia
                )
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Erro ao enviar: \(error.localizedDescription)"
                }
            }
        }
    }
}
