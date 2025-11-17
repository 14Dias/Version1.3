// Views/Main/PaginaInicialView.swift
import SwiftUI
import Combine

// Views/Main/PaginaInicialView.swift - VERSÃO MELHORADA
struct PaginaInicialView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            // Aba 1: Menu Principal
            NavigationStack {
                MenuView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Início", systemImage: "house.fill")
            }
            
            // Aba 2: Montar Treino
            NavigationStack {
                MontarTreinoView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Criar", systemImage: "plus.circle.fill")
            }
            
            // Aba 3: Treinos Salvos
            NavigationStack {
                TreinosSalvosView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Meus Treinos", systemImage: "list.bullet.rectangle.portrait")
            }
            
            // Aba 4: Perfil
            NavigationStack {
                PerfilView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Perfil", systemImage: "person.circle.fill")
            }
        }
        .tint(.blue)
        .onAppear {
            let userUID = authViewModel.getCurrentUserUID()
            print("🟡 PaginaInicialView carregada - UserUID: \(userUID)")
        }
    }
}
