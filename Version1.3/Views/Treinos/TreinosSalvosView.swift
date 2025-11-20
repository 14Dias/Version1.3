// Views/Treinos/TreinosSalvosView.swift
import SwiftUI
import Combine

struct TreinosSalvosView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = TreinoListViewModel()
    @State private var mostrarError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fundo (se tiver o Theme definido, senão usa cor padrão)
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.treinos.isEmpty {
                    ProgressView("Carregando...")
                } else if viewModel.treinos.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("Meus Treinos")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupUserUID()
            }
            .onChange(of: authViewModel.currentUserUID) { newUID in
                if let uid = newUID {
                    viewModel.setup(userUID: uid)
                }
            }
            // Alertas
            .alert("Erro", isPresented: $mostrarError) {
                Button("OK", role: .cancel) { }
                Button("Tentar Novamente") { viewModel.carregarTreinos() }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Limite de Favoritos", isPresented: $viewModel.mostrarLimiteAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Você só pode ter até 3 treinos nos destaques. Remova um dos treinos atuais para adicionar este.")
            }
            .onChange(of: viewModel.errorMessage) { error in
                mostrarError = !error.isEmpty
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Nenhum treino salvo",
            systemImage: "figure.strengthtraining.traditional",
            description: Text("Crie seu primeiro treino na aba \"Criar\"")
        )
    }
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.treinos) { treino in
                    NavigationLink {
                        DetalhesTreinoView(treino: treino)
                    } label: {
                        // Card Customizado
                        TreinoCardView(
                            treino: treino,
                            // Passamos se é favorito verificando no Set do ViewModel
                            isFavorito: viewModel.favoritosIds.contains(treino.id),
                            onFavoritar: {
                                viewModel.toggleFavorito(treino)
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.deletarTreino(treino)
                        } label: {
                            Label("Deletar Treino", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.carregarTreinos()
            viewModel.carregarFavoritos()
        }
    }
    
    private func setupUserUID() {
        if let uid = authViewModel.currentUserUID {
            viewModel.setup(userUID: uid)
        }
    }
}

