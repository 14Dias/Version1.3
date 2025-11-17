// Services/TreinoManager.swift - NOVO ARQUIVO
import Foundation
import Combine

@MainActor
class TreinoManager: ObservableObject {
    @Published var todosTreinos: [Treino] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let firestoreService = FirestoreService()
    private var currentUserUID: String = ""
    
    func setup(userUID: String) {
        guard !userUID.isEmpty, userUID != currentUserUID else { return }
        
        self.currentUserUID = userUID
        print("🟡 TreinoManager configurado para UserUID: \(userUID)")
        
        // Iniciar listener em tempo real
        firestoreService.startTreinosListener(userUID: userUID) { [weak self] treinos in
            self?.todosTreinos = treinos
            self?.isLoading = false
            print("✅ TreinoManager - Lista atualizada: \(treinos.count) treinos")
        }
        
        // Carregamento inicial
        carregarTreinos()
    }
    
    func carregarTreinos() {
        guard !currentUserUID.isEmpty else {
            errorMessage = "Usuário não autenticado"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let treinos = try await firestoreService.fetchTreinos(userUID: currentUserUID)
                self.todosTreinos = treinos
                self.isLoading = false
                print("✅ TreinoManager - Carregamento inicial: \(treinos.count) treinos")
            } catch {
                self.errorMessage = "Erro ao carregar treinos: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func cleanup() {
        firestoreService.stopListeners()
        currentUserUID = ""
        todosTreinos = []
        print("🟡 TreinoManager limpo")
    }
}
