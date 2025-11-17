// ViewModels/CreateTreinoViewModel.swift - VERSÃO MELHORADA
import SwiftUI
import Combine

@MainActor
class CreateTreinoViewModel: ObservableObject {
    @Published var nomeTreino = ""
    @Published var exercicios: [Exercicio] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var mostrarSucesso = false
    
    var userUID: String = "" {
        didSet {
            print("🟡 CreateTreinoViewModel - UserUID atualizado: \(userUID)")
        }
    }
    
    private let firestoreService = FirestoreService()
    
    func adicionarExercicio(_ exercicio: Exercicio) {
        exercicios.append(exercicio)
        print("✅ Exercício adicionado: \(exercicio.nome)")
    }
    
    func removerExercicio(na posicoes: IndexSet) {
        exercicios.remove(atOffsets: posicoes)
    }
    
    func salvarTreino() async -> Bool {
        // Validações robustas
        guard !userUID.isEmpty else {
            errorMessage = "Erro de autenticação. Faça login novamente."
            print("🔴 UserUID vazio ao salvar treino")
            return false
        }
        
        guard !nomeTreino.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Digite um nome para o treino"
            return false
        }
        
        guard !exercicios.isEmpty else {
            errorMessage = "Adicione pelo menos um exercício"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        
        print("🟡 Iniciando salvamento do treino: \(nomeTreino)")
        print("📊 Detalhes: \(exercicios.count) exercícios, UserUID: \(userUID)")
        
        let treino = Treino(
            nome: nomeTreino.trimmingCharacters(in: .whitespacesAndNewlines),
            data: Date(),
            exercicios: exercicios,
            userUID: userUID
        )
        
        do {
            try await firestoreService.saveTreino(treino)
            isLoading = false
            mostrarSucesso = true
            print("✅ Treino salvo com sucesso: \(treino.nome)")
            return true
        } catch {
            errorMessage = "Erro ao salvar treino: \(error.localizedDescription)"
            isLoading = false
            print("🔴 Erro ao salvar treino: \(error)")
            return false
        }
    }
    
    func limparCampos() {
        nomeTreino = ""
        exercicios = []
        errorMessage = ""
        print("🟡 Campos limpos - pronto para novo treino")
    }
    
    var podeSalvar: Bool {
        !nomeTreino.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !exercicios.isEmpty &&
        !userUID.isEmpty
    }
}
