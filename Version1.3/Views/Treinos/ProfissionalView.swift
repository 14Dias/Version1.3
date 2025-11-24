import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - 1. ViewModel para o Painel (CRIAR TREINO)
@MainActor
class ProfessionalViewModel: ObservableObject {
    @Published var nomeTreino = ""
    @Published var exercicios: [Exercicio] = []
    @Published var emailAluno = ""
    @Published var isLoading = false
    @Published var message = ""
    @Published var showSuccess = false
    
    private let firestoreService = FirestoreService()
    private let db = Firestore.firestore()
    
    func enviarTreinoParaAluno() async {
        guard !nomeTreino.isEmpty, !exercicios.isEmpty, !emailAluno.isEmpty else {
            message = "Preencha todos os campos."
            return
        }
        
        guard let professionalUID = Auth.auth().currentUser?.uid else {
            message = "Erro: Profissional não autenticado."
            return
        }
        
        isLoading = true
        message = "Buscando aluno..."
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("email", isEqualTo: emailAluno.trimmingCharacters(in: .whitespaces).lowercased())
                .getDocuments()
            
            guard let document = snapshot.documents.first else {
                message = "Aluno não encontrado com este e-mail."
                isLoading = false
                return
            }
            
            let studentUID = document.documentID
            
            let novoTreino = Treino(
                nome: nomeTreino,
                data: Date(),
                exercicios: exercicios,
                userUID: studentUID,
                professionalUID: professionalUID
            )
            
            try await firestoreService.saveTreino(novoTreino)
            
            message = "Treino enviado com sucesso para o aluno!"
            showSuccess = true
            limparCampos()
            
        } catch {
            message = "Erro: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func adicionarExercicio(_ exercicio: Exercicio) {
        exercicios.append(exercicio)
    }
    
    func limparCampos() {
        nomeTreino = ""
        exercicios = []
        emailAluno = ""
    }
}

// MARK: - 2. ViewModel para a Solicitação (FORMULÁRIO)
// Esta classe estava faltando ou sendo confundida
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
    
    let especialidades = ["Personal Trainer", "Nutricionista", "Fisioterapeuta", "Médico do Esporte", "Outro"]
    
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
            
            message = "Sua solicitação foi enviada e aprovada automaticamente para testes!"
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

// MARK: - 3. View do Painel (CRIAR TREINO)
struct ProfissionalView: View {
    @StateObject private var viewModel = ProfessionalViewModel()
    @State private var showingAddExercicio = false
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Destinatário") {
                    TextField("E-mail do Aluno", text: $viewModel.emailAluno)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    Text("O treino aparecerá automaticamente na conta deste aluno.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Detalhes do Treino") {
                    TextField("Nome do Treino (ex: Hipertrofia A)", text: $viewModel.nomeTreino)
                }
                
                Section("Exercícios") {
                    if viewModel.exercicios.isEmpty {
                        Text("Nenhum exercício adicionado")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(viewModel.exercicios) { exercicio in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercicio.nome)
                                    .font(.headline)
                                Text("\(exercicio.series)x \(exercicio.repeticoes) • \(exercicio.peso)kg")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            viewModel.exercicios.remove(atOffsets: indexSet)
                        }
                    }
                    
                    Button {
                        showingAddExercicio = true
                    } label: {
                        Label("Adicionar Exercício", systemImage: "plus.circle.fill")
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await viewModel.enviarTreinoParaAluno()
                            if !viewModel.message.isEmpty && !viewModel.showSuccess {
                                showingErrorAlert = true
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Enviar Treino")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.emailAluno.isEmpty || viewModel.exercicios.isEmpty)
                }
            }
            .navigationTitle("Painel do Personal")
            .sheet(isPresented: $showingAddExercicio) {
                AdicionarExercicioView { novoExercicio in
                    viewModel.adicionarExercicio(novoExercicio)
                }
            }
            .alert("Sucesso", isPresented: $viewModel.showSuccess) {
                Button("OK") { }
            } message: {
                Text(viewModel.message)
            }
            .alert("Atenção", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.message)
            }
        }
    }
}

// MARK: - 4. View da Solicitação (FORMULÁRIO)
struct SolicitarProfissionalView: View {
    // CORREÇÃO: Usar a ViewModel de Solicitação aqui
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
                        ProgressView()
                    } else {
                        Text("Enviar Solicitação")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                .disabled(!viewModel.isValid || viewModel.isLoading)
            } footer: {
                Text("Ao enviar, você confirma que possui as credenciais informadas.")
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
