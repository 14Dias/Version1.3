// ViewModels/MenuViewModel.swift - VERIFIQUE SE ESTÁ ASSIM
import SwiftUI
import Combine

@MainActor
class MenuViewModel: ObservableObject {
    @Published var selectedSection = "Em Alta"
    @Published var showSideMenu = false
    @Published var showingProfileView = false
    @Published var isLoading = false
    @Published var treinos: [Treino] = []
    
    private let firestoreService = FirestoreService()
    private var userUID: String = "" {
        didSet {
            if !userUID.isEmpty && oldValue != userUID {
                print("🟢 MenuViewModel - UserUID atualizado: \(userUID)")
                loadTreinos()
            }
        }
    }
    
    let sections = ["Em Alta", "Novidades", "Recomendados", "Favoritos"]
    let menuItems = [
        ("house.fill", "Início"),
        ("figure.strengthtraining.traditional", "Meus Treinos"),
        ("heart.fill", "Favoritos"),
        ("clock.fill", "Histórico"),
        ("gearshape.fill", "Configurações")
    ]
    
    var mediaItems: [MediaItem] {
        [
            MediaItem(title: "Técnica de Levantamento", duration: "15 min", thumbnail: "dumbbell.fill", category: "Força"),
            MediaItem(title: "Respiração \nno Yoga", duration: "10 min", thumbnail: "figure.yoga", category: "Flexibilidade"),
            MediaItem(title: "Aquecimento Completo", duration: "8 min", thumbnail: "figure.run", category: "Cardio")
        ]
    }
    
    init(userUID: String) {
        print("🟡 MenuViewModel inicializado com UserUID: '\(userUID)'")
        if !userUID.isEmpty {
            self.userUID = userUID
            loadTreinos()
        }
    }
    
    func atualizarUserUID(_ novoUserUID: String) {
        guard !novoUserUID.isEmpty, novoUserUID != userUID else {
            print("🟡 MenuViewModel - UserUID igual ou vazio: '\(novoUserUID)'")
            return
        }
        self.userUID = novoUserUID
    }
    
    func loadTreinos() {
        guard !userUID.isEmpty else {
            print("🔴 MenuViewModel - UserUID vazio, não é possível carregar treinos")
            return
        }
        
        print("🟢 MenuViewModel - Carregando treinos para UserUID: \(userUID)")
        isLoading = true
        
        Task {
            do {
                treinos = try await firestoreService.fetchTreinos(userUID: userUID)
                isLoading = false
                print("🟢 MenuViewModel: Carregados \(treinos.count) treinos do Firestore para usuário: \(userUID)")
            } catch {
                print("❌ Erro ao carregar treinos no MenuViewModel: \(error)")
                isLoading = false
            }
        }
        
        
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
}
