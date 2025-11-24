// ViewModels/MenuViewModel.swift
import SwiftUI
import Combine

@MainActor
class MenuViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedSection = "Em Alta"
    @Published var showSideMenu = false
    @Published var showingProfileView = false
    @Published var isLoading = false
    
    // Dados do Firebase
    @Published var treinos: [Treino] = []
    @Published var conteudos: [Conteudo] = [] // ✅ NOVO: Lista de conteúdos
    
    // MARK: - Private Properties
    private let firestoreService = FirestoreService()
    
    private var userUID: String = "" {
        didSet {
            if !userUID.isEmpty && oldValue != userUID {
                print("🟢 MenuViewModel - UserUID atualizado: \(userUID)")
                loadData() // ✅ Carrega tudo quando o usuário muda
            }
        }
    }
    
    // MARK: - Constants
    let sections = ["Em Alta", "Novidades", "Recomendados", "Favoritos"]
    let menuItems = [
        ("house.fill", "Início"),
        ("figure.strengthtraining.traditional", "Meus Treinos"),
        ("heart.fill", "Favoritos"),
        ("clock.fill", "Histórico"),
        ("gearshape.fill", "Configurações")
    ]
    
    // Mantemos 'mediaItems' vazio ou computado para não quebrar códigos antigos que ainda o chamem,
    // mas a View agora deve usar 'conteudos'.
    var mediaItems: [MediaItem] { [] }
    
    // MARK: - Init
    init(userUID: String) {
        print("🟡 MenuViewModel inicializado com UserUID: '\(userUID)'")
        if !userUID.isEmpty {
            self.userUID = userUID
            loadData()
        }
    }
    
    // MARK: - Public Methods
    
    func atualizarUserUID(_ novoUserUID: String) {
        guard !novoUserUID.isEmpty, novoUserUID != userUID else {
            // print("🟡 MenuViewModel - UserUID igual ou vazio: '\(novoUserUID)'")
            return
        }
        self.userUID = novoUserUID
        // O didSet de userUID chamará loadData() automaticamente
    }
    
    // ✅ Função central para carregar todos os dados da tela
    func loadData() {
        loadTreinos()
        loadConteudos()
    }
    
    func loadTreinos() {
        guard !userUID.isEmpty else {
            print("🔴 MenuViewModel - UserUID vazio, não é possível carregar treinos")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let treinosCarregados = try await firestoreService.fetchTreinos(userUID: userUID)
                self.treinos = treinosCarregados
                self.isLoading = false
                print("🟢 MenuViewModel: Carregados \(treinosCarregados.count) treinos.")
            } catch {
                print("❌ Erro ao carregar treinos no MenuViewModel: \(error)")
                self.isLoading = false
            }
        }
    }
    
    // ✅ Nova função para buscar os vídeos/cursos
    func loadConteudos() {
        Task {
            do {
                let itens = try await firestoreService.fetchConteudos()
                self.conteudos = itens
                print("🟢 MenuViewModel: Carregados \(itens.count) conteúdos de mídia.")
            } catch {
                print("❌ Erro ao carregar conteúdos: \(error)")
            }
        }
    }
    
    // MARK: - UI Helper Methods
    // (Estas funções estavam incorretamente dentro de loadTreinos no seu código original)
    
    func selectSection(_ section: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedSection = section
        }
    }
    
    func toggleSideMenu() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showSideMenu.toggle()
        }
    }
    
    func navigateToProfile() {
        toggleSideMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showingProfileView = true
        }
    }
    
    var trendingTreinos: [Treino] {
        Array(treinos.prefix(4))
    }
    
    var hasTreinos: Bool {
        !treinos.isEmpty
    }
}
