// Views/Treinos/DetalhesTreinoView.swift - VERSÃO CORRIGIDA
import SwiftUI

struct DetalhesTreinoView: View {
    let treino: Treino
    @State private var showingEditView = false
    
    var body: some View {
        List {
            Section("Informações") {
                LabeledContent("Nome", value: treino.nome)
                LabeledContent("Data", value: treino.data.formatted(date: .long, time: .shortened))
                LabeledContent("Total de exercícios", value: "\(treino.exercicios.count)")
            }
            
            Section("Exercícios") {
                ForEach(treino.exercicios) { exercicio in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercicio.nome)
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            Label("\(exercicio.series) séries", systemImage: "repeat")
                            Label("\(exercicio.repeticoes) Reps", systemImage: "number")
                            Label("\(exercicio.peso) Kg's", systemImage: "scalemass")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Detalhes do Treino")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Editar") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            NavigationStack {
                EditarTreinoView(
                    treino: treino,
                    onSave: {
                        // Atualizar a view após salvar
                        showingEditView = false
                    },
                    onCancel: {
                        showingEditView = false
                    }
                )
            }
        }
    }
}
