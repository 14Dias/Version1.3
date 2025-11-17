// Views/Components/AdicionarExercicioView.swift
import SwiftUI

struct AdicionarExercicioView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var nome = ""
    @State private var series = 3
    @State private var repeticoes = "10"
    @State private var tempoDescanso = 60
    @State private var observacoes = ""
    @State private var peso = 10
    
    let onAdicionar: (Exercicio) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informações Básicas") {
                    TextField("Nome do exercício", text: $nome)
                    
                    Stepper("Séries: \(series)", value: $series, in: 1...10)
                    Stepper("Peso: \(peso) kg", value: $peso, in: 1...100)
                    
                    Picker("Repetições", selection: $repeticoes) {
                        Text("8").tag("8")
                        Text("10").tag("10")
                        Text("12").tag("12")
                        Text("14").tag("14")
                        Text("16").tag("16")
                        Text("18").tag("18")
                    }
                    
                    Picker("Tempo de descanso", selection: $tempoDescanso) {
                        Text("30 seg").tag(30)
                        Text("45 seg").tag(45)
                        Text("1 min").tag(60)
                        Text("1:30 min").tag(90)
                        Text("2 min").tag(120)
                        Text("3 min").tag(180)
                    }
                }
                
                Section("Observações") {
                    TextEditor(text: $observacoes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Novo Exercício")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Adicionar") {
                        let exercicio = Exercicio(
                            nome: nome,
                            series: series,
                            repeticoes: repeticoes,
                            tempoDescanso: tempoDescanso,
                            observacoes: observacoes,
                            peso: peso
                        )
                        onAdicionar(exercicio)
                        dismiss()
                    }
                    .disabled(nome.isEmpty)
                }
            }
        }
    }
}
