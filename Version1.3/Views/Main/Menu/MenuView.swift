// Views/Main/Menu/MenuView.swift - VERSÃO FINAL CORRIGIDA
import SwiftUI

struct MenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: MenuViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: MenuViewModel(userUID: ""))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        headerView
                        
                        if viewModel.isLoading {
                            LoadingView()
                        } else {
                            TrendingListView()
                            mediaSectionView
                        }
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    viewModel.loadTreinos()
                }
            }
            .navigationTitle("Trainar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    UserMenuButton()
                }
            }
            .onAppear {
                if let uid = authViewModel.currentUserUID {
                    viewModel.atualizarUserUID(uid)
                }
            }
            .onChange(of: authViewModel.currentUserUID) { newUID in
                if let uid = newUID {
                    viewModel.atualizarUserUID(uid)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(viewModel.selectedSection)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            SectionScrollView(selectedSection: $viewModel.selectedSection, sections: viewModel.sections)
        }
        .padding(.horizontal)
    }
    
    private var mediaSectionView: some View {
        MediaSectionView(mediaItems: viewModel.mediaItems)
    }
}

// MARK: - Componentes Separados

struct SectionScrollView: View {
    @Binding var selectedSection: String
    let sections: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(sections, id: \.self) { section in
                    SectionButton(
                        section: section,
                        isSelected: selectedSection == section,
                        action: {
                            // CORREÇÃO: Atualizar diretamente a propriedade
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSection = section
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

struct SectionButton: View {
    let section: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(section)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(background)
                .cornerRadius(20)
        }
    }
    
    private var background: some View {
        Group {
            if isSelected {
                LinearGradient(
                    colors: [.blue.opacity(0.9), .blue.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                Color.gray.opacity(0.2)
            }
        }
    }
}

struct UserMenuButton: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationLink {
            PerfilView()
                .environmentObject(authViewModel)
        } label: {
            if let user = authViewModel.user, !user.username.isEmpty {
                Text(user.username.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            colors: [.blue.opacity(0.9), .blue.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
}

// As outras structs permanecem iguais...
struct TrendingListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var treinosFavoritos: [Treino] = []
    
    private let firestoreService = FirestoreService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Treinos em Destaque")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            if !treinosFavoritos.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(treinosFavoritos) { treino in
                        TrendingItemView(treino: treino)
                    }
                }
                .padding(.horizontal)
            } else {
                emptyFavoritosView
            }
        }
        .onAppear {
            carregarTreinosFavoritos()
        }
        .onChange(of: authViewModel.currentUserUID) { _ in
            carregarTreinosFavoritos()
        }
    }
    
    private var emptyFavoritosView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Nenhum treino em destaque")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Toque no ícone de estrela nos treinos para adicioná-los aos destaques")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func carregarTreinosFavoritos() {
        guard let userUID = authViewModel.currentUserUID, !userUID.isEmpty else {
            print("🔴 TrendingListView: UserUID não disponível")
            return
        }
        
        Task {
            do {
                let favoritos = try await firestoreService.fetchTreinosFavoritos(userUID: userUID)
                await MainActor.run {
                    self.treinosFavoritos = favoritos
                }
            } catch {
                print("❌ Erro ao carregar treinos favoritos: \(error)")
            }
        }
    }
}

struct TrendingItemView: View {
    let treino: Treino
    
    var body: some View {
        NavigationLink {
            DetalhesTreinoView(treino: treino)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(treino.nome)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TreinoTagsView(treino: treino)
                    
                    Text(treino.data.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TreinoTagsView: View {
    let treino: Treino
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(treino.exercicios.count) ex.")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            
            if Calendar.current.isDateInToday(treino.data) {
                Text("Hoje")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .cornerRadius(4)
            }
            
            if treino.exercicios.count > 4 {
                Text("Longo")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
            }
        }
    }
}

struct MediaSectionView: View {
    let mediaItems: [MediaItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Vídeos e Cursos")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(mediaItems) { item in
                        MediaCardView(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct MediaCardView: View {
    let item: MediaItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.9), .blue.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 160, height: 90)
                
                Image(systemName: item.thumbnail)
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(item.duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(item.category)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
            }
            .frame(width: 160)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            Text("Carregando...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    let authViewModel = AuthViewModel()
    return MenuView()
        .environmentObject(authViewModel)
}
