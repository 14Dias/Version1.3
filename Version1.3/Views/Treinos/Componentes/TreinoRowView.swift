// Views/Treinos/Components/TreinoRowView.swift - VERSÃO COM FAVORITOS
import SwiftUI

struct TreinoRowView: View {
    let treino: Treino
    let onFavoritar: (() -> Void)?
    let isFavorito: Bool
    let podeFavoritar: Bool
    
    @State private var showingLimiteAlert = false
    
    init(treino: Treino, isFavorito: Bool, podeFavoritar: Bool = true, onFavoritar: (() -> Void)? = nil) {
        self.treino = treino
        self.isFavorito = isFavorito
        self.podeFavoritar = podeFavoritar
        self.onFavoritar = onFavoritar
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(treino.nome)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Label("\(treino.exercicios.count) ex", systemImage: "dumbbell")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(treino.data.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Botão de favoritar
                if podeFavoritar {
                    Button(action: {
                        if !isFavorito {
                            onFavoritar?()
                        } else {
                            // Remover favorito
                            onFavoritar?()
                        }
                    }) {
                        Image(systemName: isFavorito ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(isFavorito ? .yellow : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Tags do treino
            if !treino.exercicios.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(treino.exercicios.prefix(3)), id: \.id) { exercicio in
                            Text(exercicio.nome)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if treino.exercicios.count > 3 {
                            Text("+\(treino.exercicios.count - 3) mais")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Badge de favorito
            if isFavorito {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("Nos Destaques")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .alert("Limite Atingido", isPresented: $showingLimiteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Você só pode ter até 3 treinos nos destaques. Remova um para adicionar este.")
        }
    }
}
