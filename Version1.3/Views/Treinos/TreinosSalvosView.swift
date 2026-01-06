import SwiftUI
import Combine

struct TreinosSalvosView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = TreinoListViewModel()
    
    // MARK: - Estados
    @State private var mostrarError = false
    @State private var showCreateSheet = false // Controla a tela de criar treino
    
    var body: some View {
        // Nota: Se a PaginaInicialView já tiver uma NavigationStack envolvendo esta view,
        // remova o NavigationStack interno abaixo. Se não, mantenha.
        // Assumindo que pode ser usado isoladamente, manteremos aqui.
        ZStack {
            // Fundo
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
        // MARK: - Botão de Criar (Toolbar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { // ou .navigationBarTrailing
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        // MARK: - Sheet de Criação
        .sheet(isPresented: $showCreateSheet) {
            NavigationStack {
                MontarTreinoView()
                    .environmentObject(authViewModel)
            }
        }
        // MARK: - Ciclo de Vida e Lógica
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
    
    // MARK: - Views Auxiliares
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Nenhum treino salvo", systemImage: "dumbbell.fill")
        } description: {
            Text("Comece criando seu primeiro treino personalizado.")
        } actions: {
            Button {
                showCreateSheet = true
            } label: {
                Text("Criar Treino")
                    .bold()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    
            }
            .padding(.top, 10)
        }
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
#Preview {
    TreinosSalvosView()
}
