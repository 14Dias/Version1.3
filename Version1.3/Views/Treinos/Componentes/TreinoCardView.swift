// Views/Treinos/Componentes/TreinoCardView.swift
import SwiftUI

struct TreinoCardView: View {
    let treino: Treino
    let isFavorito: Bool // ✅ Este parâmetro precisa existir
    var onFavoritar: () -> Void
    
    // Inicializador explícito para evitar dúvidas do compilador
    init(treino: Treino, isFavorito: Bool = false, onFavoritar: @escaping () -> Void) {
        self.treino = treino
        self.isFavorito = isFavorito
        self.onFavoritar = onFavoritar
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cabeçalho
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(treino.nome)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(treino.data.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                
                Spacer()
                
                Button(action: onFavoritar) {
                    Image(systemName: isFavorito ? "star.fill" : "star")
                        .foregroundStyle(isFavorito ? .yellow : .gray.opacity(0.3))
                        .font(.title3)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.2))
            
            // Rodapé com Stats
            HStack(spacing: 20) {
                Label("\(treino.exercicios.count) Exercícios", systemImage: "dumbbell.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Exemplo de cálculo de volume total (opcional)
                if let volume = treino.exercicios.map({ $0.peso * $0.series }).reduce(0, +) as? Int, volume > 0 {
                    Label("\(volume)kg Vol.", systemImage: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
