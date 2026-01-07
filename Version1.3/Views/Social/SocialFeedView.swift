import SwiftUI

struct SocialFeedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = SocialViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Carregando feed...")
                } else if viewModel.posts.isEmpty {
                    ContentUnavailableView(
                        "Feed Vazio",
                        systemImage: "person.2.slash",
                        description: Text("Ninguém postou treinos públicos ainda.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.posts) { treino in
                                SocialPostCard(
                                    treino: treino,
                                    currentUserUID: authViewModel.currentUserUID ?? "",
                                    onLike: {
                                        viewModel.toggleLike(treino: treino)
                                    },
                                    onSaveCopy: {
                                        // Futuro: Implementar cópia do treino
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        viewModel.carregarFeed()
                    }
                }
            }
            .navigationTitle("Comunidade")
            .onAppear {
                if let uid = authViewModel.currentUserUID {
                    viewModel.setup(userUID: uid)
                }
            }
        }
    }
}

// Componente do Cartão do Post
struct SocialPostCard: View {
    let treino: Treino
    let currentUserUID: String
    let onLike: () -> Void
    let onSaveCopy: () -> Void
    
    var isLiked: Bool {
        treino.likes.contains(currentUserUID)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Autor
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(Text(treino.authorName.prefix(1)).bold())
                
                VStack(alignment: .leading) {
                    Text(treino.authorName)
                        .font(.headline)
                    Text("Compartilhou um treino")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Badge se for Profissional (lógica simples)
                if treino.professionalUID != nil {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            // Conteúdo do Treino
            VStack(alignment: .leading, spacing: 8) {
                Text(treino.nome)
                    .font(.title3)
                    .bold()
                
                Text("\(treino.exercicios.count) Exercícios")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Preview dos primeiros 3 exercícios
                ForEach(treino.exercicios.prefix(3)) { ex in
                    HStack {
                        Image(systemName: "dumbbell.fill")
                            .font(.caption2)
                        Text(ex.nome)
                            .font(.caption)
                        Spacer()
                        Text("\(ex.series)x\(ex.repeticoes)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                if treino.exercicios.count > 3 {
                    Text("+ \(treino.exercicios.count - 3) outros...")
                        .font(.caption2)
                        .italic()
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            
            Divider()
            
            // Ações
            HStack {
                Button(action: onLike) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .primary)
                        Text("\(treino.likes.count)")
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                Button(action: onSaveCopy) {
                    Label("Salvar", systemImage: "arrow.down.doc")
                        .font(.caption)
                }
                .disabled(true) // Habilitar em futura versão
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
