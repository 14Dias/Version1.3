// ViewModels/TreinoListViewModel.swift
import SwiftUI
import Combine

@MainActor
class TreinoListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var treinos: [Treino] = []
    @Published var favoritosIds: Set<String> = [] // Armazena IDs dos favoritos para acesso rápido
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var ultimaAtualizacao = Date()
    @Published var mostrarLimiteAlert = false // Controla o alerta de limite na View
    
    private let firestoreService = FirestoreService()
    private var listenerAtivo = false
    
    // MARK: - UserUID Logic
    private var _userUID: String = "" {
        didSet {
            if !_userUID.isEmpty && oldValue != _userUID {
                print("🟢 UserUID atualizado no ViewModel: \(_userUID)")
                iniciarListener()
                carregarFavoritos()
            }
        }
    }
    
    var userUID: String {
        return _userUID
    }
    
    init(userUID: String = "") {
        print("🟡 TreinoListViewModel inicializado")
        if !userUID.isEmpty {
            self._userUID = userUID
            iniciarListener()
            carregarFavoritos()
        }
    }
    
    // Alias para manter compatibilidade com a View
    func setup(userUID: String) {
        atualizarUserUID(userUID)
    }
    
    func atualizarUserUID(_ novoUserUID: String) {
        guard !novoUserUID.isEmpty else { return }
        self._userUID = novoUserUID
    }
    
    // MARK: - Listeners & Loading
    func iniciarListener() {
        guard !_userUID.isEmpty else { return }
        
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
                self.isLoading = false
                self.sincronizarFavoritos() // Atualiza os ícones de estrela
                print("✅ Listener atualizado: \(treinosAtualizados.count) treinos")
            }
        }
    }
    
    func carregarTreinos() {
        guard !_userUID.isEmpty else {
            errorMessage = "Usuário não autenticado"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let treinosCarregados = try await firestoreService.fetchTreinos(userUID: _userUID)
                await MainActor.run {
                    self.treinos = treinosCarregados
                    self.isLoading = false
                    self.sincronizarFavoritos()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erro ao carregar: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Favoritos Logic
    func carregarFavoritos() {
        guard !_userUID.isEmpty else { return }
        
        Task {
            do {
                let favoritos = try await firestoreService.fetchFavoritos(userUID: _userUID)
                await MainActor.run {
                    // Mapeia apenas os IDs dos treinos favoritados
                    self.favoritosIds = Set(favoritos.map { $0.treinoID })
                    self.sincronizarFavoritos()
                }
            } catch {
                print("❌ Erro ao carregar favoritos: \(error)")
            }
        }
    }
    
    func toggleFavorito(_ treino: Treino) {
        guard !_userUID.isEmpty else { return }
        let treinoID = treino.id
        
        Task {
            do {
                if favoritosIds.contains(treinoID) {
                    // Remover
                    try await firestoreService.removerFavorito(treinoID: treinoID, userUID: _userUID)
                    await MainActor.run {
                        self.favoritosIds.remove(treinoID)
                        self.sincronizarFavoritos()
                    }
                } else {
                    // Adicionar (com verificação de limite)
                    if favoritosIds.count >= 3 {
                        await MainActor.run { self.mostrarLimiteAlert = true }
                        return
                    }
                    
                    try await firestoreService.adicionarFavorito(treinoID: treinoID, userUID: _userUID)
                    await MainActor.run {
                        self.favoritosIds.insert(treinoID)
                        self.sincronizarFavoritos()
                    }
                }
            } catch {
                print("❌ Erro ao alternar favorito: \(error)")
                // Se o erro for de limite vindo do backend
                let nsError = error as NSError
                if nsError.code == -2 {
                    await MainActor.run { self.mostrarLimiteAlert = true }
                }
            }
        }
    }
    
    // Atualiza a propriedade isFavorito dentro da lista de treinos para a UI reagir
    private func sincronizarFavoritos() {
        // Como Treino é uma struct (Value Type), precisamos recriar o array com as alterações
        // Mas como a View usa o ID do treino para verificar se é favorito na hora de renderizar (via favoritosIds),
        // essa função é mais para garantir consistência se você tiver uma propriedade 'isFavorito' no modelo Treino.
        // Se não tiver, a View deve verificar usando: viewModel.favoritosIds.contains(treino.id)
    }
    
    // MARK: - Actions
    func deletarTreino(_ treino: Treino) {
        print("🟡 Deletando treino: \(treino.nome)")
        Task {
            do {
                try await firestoreService.deleteTreino(treino)
                // Listener atualiza automaticamente, mas podemos remover localmente para feedback instantâneo
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erro ao deletar: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Método plural para compatibilidade com .onDelete do List (IndexSet)
    func deletarTreinos(na posicoes: IndexSet) {
        for index in posicoes {
            let treino = treinos[index]
            deletarTreino(treino)
        }
    }
}
