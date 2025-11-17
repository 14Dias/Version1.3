// Views/Treinos/TreinosSalvosView.swift - VERSÃO CORRIGIDA
import SwiftUI
import Combine

struct TreinosSalvosView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: TreinoListViewModel
    @State private var treinosFavoritos: [String] = []
    @State private var mostrarError = false
    @State private var mostrarLimiteAlert = false
    
    private let firestoreService = FirestoreService()
    
    init() {
        _viewModel = StateObject(wrappedValue: TreinoListViewModel(userUID: ""))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.treinos.isEmpty {
                ShimmerLoadingView(message: "Carregando seus treinos...")
            } else if viewModel.treinos.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                listView
            }
        }
        .navigationTitle("Treinos Salvos")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            print("🟡 TreinosSalvosView aparecendo")
            setupUserUID()
        }
        .onChange(of: authViewModel.currentUserUID) { newUID in
            print("🟡 onChange - UserUID: \(newUID ?? "nil")")
            if let uid = newUID, !uid.isEmpty {
                viewModel.atualizarUserUID(uid)
                carregarFavoritos()
            }
        }
        .alert("Erro", isPresented: $mostrarError) {
            Button("OK", role: .cancel) { }
            Button("Tentar Novamente") {
                viewModel.carregarTreinos()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Limite de Favoritos", isPresented: $mostrarLimiteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Você só pode ter até 3 treinos nos destaques. Remova um dos treinos atuais para adicionar este.")
        }
        .onChange(of: viewModel.errorMessage) { error in
            mostrarError = !error.isEmpty
        }
        .refreshable {
            await refreshTreinos()
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
        List {
            ForEach(viewModel.treinos) { treino in
                NavigationLink {
                    DetalhesTreinoView(treino: treino)
                } label: {
                    TreinoRowView(
                        treino: treino,
                        isFavorito: treinosFavoritos.contains(treino.id.uuidString),
                        onFavoritar: {
                            toggleFavorito(treino: treino)
                        }
                    )
                }
            }
            .onDelete(perform: viewModel.deletarTreinos)
        }
    }
    
    private func setupUserUID() {
        if let uid = authViewModel.currentUserUID, !uid.isEmpty {
            print("🟢 Setup UserUID: \(uid)")
            viewModel.atualizarUserUID(uid)
            // FORÇAR o carregamento após um pequeno delay para garantir que o UserUID foi atualizado
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.viewModel.carregarTreinos()
            }
            carregarFavoritos()
        } else {
            print("🔴 Setup UserUID: UserUID não disponível")
        }
    }
    private func refreshTreinos() async {
        print("🟡 Refresh manual acionado")
        viewModel.carregarTreinos()
        carregarFavoritos()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func carregarFavoritos() {
        guard let userUID = authViewModel.currentUserUID, !userUID.isEmpty else {
            print("🔴 UserUID vazio - não é possível carregar favoritos")
            return
        }
        
        print("🟢 Carregando favoritos para UserUID: \(userUID)")
        Task {
            do {
                let favoritos = try await firestoreService.fetchFavoritos(userUID: userUID)
                await MainActor.run {
                    treinosFavoritos = favoritos.map { $0.treinoID }
                    print("✅ Favoritos carregados: \(treinosFavoritos.count) treinos")
                }
            } catch {
                print("❌ Erro ao carregar favoritos: \(error)")
            }
        }
    }
    
    private func toggleFavorito(treino: Treino) {
        guard let userUID = authViewModel.currentUserUID else { return }
        
        Task {
            do {
                let treinoID = treino.id.uuidString
                
                if treinosFavoritos.contains(treinoID) {
                    try await firestoreService.removerFavorito(treinoID: treinoID, userUID: userUID)
                    await MainActor.run {
                        treinosFavoritos.removeAll { $0 == treinoID }
                    }
                } else {
                    if treinosFavoritos.count >= 3 {
                        await MainActor.run {
                            mostrarLimiteAlert = true
                        }
                        return
                    }
                    
                    try await firestoreService.adicionarFavorito(treinoID: treinoID, userUID: userUID)
                    await MainActor.run {
                        treinosFavoritos.append(treinoID)
                    }
                }
                
                carregarFavoritos()
                
            } catch {
                print("❌ Erro ao alternar favorito: \(error)")
                if (error as NSError).code == -2 {
                    await MainActor.run {
                        mostrarLimiteAlert = true
                    }
                }
            }
        }
    }
}
