import SwiftUI
import Combine
import UIKit // Necessário para configurar a aparência da TabBar

struct PaginaInicialView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // MARK: - Configuração da Aparência da TabBar
    init() {
        let appearance = UITabBarAppearance()
        
        // 1. Configura o fundo para ser transparente com efeito de vidro (Blur)
        appearance.configureWithTransparentBackground()
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            // Aba 1: Menu Principal (Início)
            NavigationStack {
                MenuView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Início", systemImage: "house.fill")
            }
            
            // Aba 2: Meus Treinos
            NavigationStack {
                TreinosSalvosView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Meus Treinos", systemImage: "dumbbell.fill")
            }
            
            // Aba 3: Progresso
            if let uid = authViewModel.currentUserUID {
                NavigationStack {
                    ProgressoView(userUID: uid)
                }
                .tabItem {
                    Label("Progresso", systemImage: "chart.xyaxis.line")
                }
            }
        }
        .tint(.blue)
        .onAppear {
            let userUID = authViewModel.getCurrentUserUID()
            print("🟡 PaginaInicialView carregada - UserUID: \(userUID)")
        }
    }
}
