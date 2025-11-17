// ViewModels/TreinoListViewModel.swift
import SwiftUI
import Combine

@MainActor
class TreinoListViewModel: ObservableObject {
    @Published var treinos: [Treino] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var ultimaAtualizacao = Date()
    
    private let firestoreService = FirestoreService()
    private var listenerAtivo = false
    private var _userUID: String = "" {
        didSet {
            if !_userUID.isEmpty && oldValue != _userUID {
                print("🟢 UserUID atualizado no ViewModel: \(_userUID)")
                iniciarListener()
            }
        }
    }
    
    // Propriedade computada para acesso seguro
    var userUID: String {
        return _userUID
    }
    
    init(userUID: String) {
        print("🟡 TreinoListViewModel inicializado")
        if !userUID.isEmpty {
            self._userUID = userUID
            iniciarListener()
        }
    }
    
    func atualizarUserUID(_ novoUserUID: String) {
        guard !novoUserUID.isEmpty else {
            print("🔴 UserUID vazio recebido - ignorando")
            return
        }
        
        // SEMPRE atualizar, mesmo se for o mesmo (para casos de inicialização vazia)
        print("🟢 Atualizando UserUID de '\(_userUID)' para '\(novoUserUID)'")
        self._userUID = novoUserUID
    }
    
    func iniciarListener() {
        guard !_userUID.isEmpty else {
            print("🔴 UserUID vazio - não é possível iniciar listener")
            return
        }
        
        print("🟢 INICIANDO LISTENER para UserUID: \(_userUID)")
        
        if listenerAtivo {
            firestoreService.stopListeners()
            listenerAtivo = false
        }
        
        listenerAtivo = true
        firestoreService.startTreinosListener(userUID: _userUID) { [weak self] treinosAtualizados in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.treinos = treinosAtualizados
                self.ultimaAtualizacao = Date()
                print("✅ Listener atualizado: \(treinosAtualizados.count) treinos")
            }
        }
    }
    
    func carregarTreinos() {
        guard !_userUID.isEmpty else {
            print("🔴 UserUID vazio - não é possível carregar treinos")
            errorMessage = "Usuário não autenticado"
            return
        }
        
        print("🟢 CARREGANDO TREINOS para UserUID: \(_userUID)")
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let treinosCarregados = try await firestoreService.fetchTreinos(userUID: _userUID)
                await MainActor.run {
                    self.treinos = treinosCarregados
                    self.isLoading = false
                    self.ultimaAtualizacao = Date()
                    print("✅ Carregados \(treinosCarregados.count) treinos do Firestore")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erro ao carregar treinos: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Filtro local
    func treinosFiltrados(por texto: String) -> [Treino] {
        guard !texto.isEmpty else { return treinos }
        return treinos.filter { treino in
            treino.nome.localizedCaseInsensitiveContains(texto)
        }
    }
    
    // MARK: - Deletar treino
    func deletarTreinos(na posicoes: IndexSet) {
        for index in posicoes {
            let treino = treinos[index]
            print("🟡 Iniciando deleção do treino: \(treino.nome)")
            
            Task {
                do {
                    try await firestoreService.deleteTreino(treino)
                    await MainActor.run {
                        self.treinos.remove(atOffsets: posicoes)
                        print("✅ Treino deletado com sucesso: \(treino.nome)")
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Erro ao deletar treino: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
}
