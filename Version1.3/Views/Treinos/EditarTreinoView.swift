// Views/Treinos/EditarTreinoView.swift - VERSÃO CORRIGIDA
import SwiftUI
import Combine

struct EditarTreinoView: View {
    @Environment(\.dismiss) private var dismiss
    let treino: Treino
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var nomeTreino: String
    @State private var exercicios: [Exercicio]
    @State private var mostrarAdicionarExercicio = false
    @State private var exercicioParaEditar: Exercicio?
    @State private var mostrarDeletarConfirmacao = false
    @State private var mostrarSucessoAlert = false
    @State private var isLoading = false
    @State private var errorMessage = "" // ADICIONAR ESTA LINHA
    
    private let firestoreService = FirestoreService()
    
    init(treino: Treino, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.treino = treino
        self.onSave = onSave
        self.onCancel = onCancel
        self._nomeTreino = State(initialValue: treino.nome)
        self._exercicios = State(initialValue: treino.exercicios)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informações do Treino") {
                    TextField("Nome do treino", text: $nomeTreino)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section("Exercícios") {
                    if exercicios.isEmpty {
                        ContentUnavailableView(
                            "Nenhum exercício",
                            systemImage: "figure.strengthtraining.traditional",
                            description: Text("Adicione exercícios ao seu treino")
                        )
                    } else {
                        ForEach(exercicios) { exercicio in
                            ExercicioRowView(
                                exercicio: exercicio,
                                onEdit: {
                                    exercicioParaEditar = exercicio
                                }
                            )
                        }
                        .onDelete(perform: deletarExercicios)
                    }
                    
                    Button {
                        mostrarAdicionarExercicio = true
                    } label: {
                        Label("Adicionar Exercício", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                // ADICIONAR SEÇÃO DE ERRO
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("Salvar Alterações", role: .none) {
                        salvarAlteracoes()
                    }
                    .disabled(!podeSalvar || isLoading)
                    .frame(maxWidth: .infinity)
                    
                    Button("Cancelar", role: .cancel) {
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button("Deletar Treino", role: .destructive) {
                        mostrarDeletarConfirmacao = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Editar Treino")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $mostrarAdicionarExercicio) {
                AdicionarExercicioView { novoExercicio in
                    adicionarExercicio(novoExercicio)
                }
            }
            .sheet(item: $exercicioParaEditar) { exercicio in
                EditarExercicioView(
                    exercicio: exercicio,
                    onSave: { exercicioEditado in
                        // CORREÇÃO: Receber o exercício editado e atualizar a lista
                        if let index = exercicios.firstIndex(where: { $0.id == exercicioEditado.id }) {
                            exercicios[index] = exercicioEditado
                        }
                        exercicioParaEditar = nil
                    },
                    onCancel: {
                        exercicioParaEditar = nil
                    }
                )
            }
            .alert("Deletar Treino", isPresented: $mostrarDeletarConfirmacao) {
                Button("Cancelar", role: .cancel) { }
                Button("Deletar", role: .destructive) {
                    deletarTreino()
                }
            } message: {
                Text("Tem certeza que deseja deletar \"\(treino.nome)\"? Esta ação não pode ser desfeita.")
            }
            .alert("Treino Salvo", isPresented: $mostrarSucessoAlert) {
                Button("OK", role: .cancel) {
                    onSave()
                    dismiss()
                }
            } message: {
                Text("Seu treino \"\(nomeTreino)\" foi salvo com sucesso!")
            }
            .overlay {
                if isLoading {
                    ProgressView("Salvando...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private var podeSalvar: Bool {
        !nomeTreino.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // CORREÇÃO: Remover 'mutating' e corrigir a lógica
    private func salvarAlteracoes() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Criar treino atualizado com os dados atuais
                let treinoAtualizado = Treino(
                    id: treino.id,
                    nome: nomeTreino,
                    data: treino.data,
                    exercicios: exercicios,
                    userUID: treino.userUID
                )
                
                try await firestoreService.updateTreino(treinoAtualizado)
                
                await MainActor.run {
                    isLoading = false
                    mostrarSucessoAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Erro ao atualizar treino: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func adicionarExercicio(_ exercicio: Exercicio) {
        exercicios.append(exercicio)
    }
    
    private func deletarExercicios(na offsets: IndexSet) {
        exercicios.remove(atOffsets: offsets)
    }
    
    private func deletarTreino() {
        isLoading = true
        Task {
            do {
                try await firestoreService.deleteTreino(treino)
                await MainActor.run {
                    isLoading = false
                    onCancel()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Erro ao deletar treino: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ExercicioRowView: View {
    let exercicio: Exercicio
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercicio.nome)
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Label("\(exercicio.series)s", systemImage: "repeat")
                    Label("\(exercicio.repeticoes)r", systemImage: "number")
                    Label("\(exercicio.peso)kg", systemImage: "weight")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}
