// Views/Treinos/DetalhesExercicioView.swift - VERSÃO CORRIGIDA
import SwiftUI

struct DetalhesExercicioView: View {
    let exercicio: Exercicio 
    
    var body: some View {
        Form {
            Section("Informações do Exercício") {
                LabeledContent("Nome", value: exercicio.nome)
                LabeledContent("Séries", value: "\(exercicio.series)")
                LabeledContent("Repetições", value: exercicio.repeticoes)
                LabeledContent("Peso", value: "\(exercicio.peso) kg")
                LabeledContent("Descanso", value: formatarTempo(exercicio.tempoDescanso))
            }
            
            if !exercicio.observacoes.isEmpty {
                Section("Observações") {
                    Text(exercicio.observacoes)
                }
            }
        }
        .navigationTitle(exercicio.nome)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatarTempo(_ segundos: Int) -> String {
        if segundos < 60 {
            return "\(segundos) seg"
        } else {
            let minutos = segundos / 60
            let segs = segundos % 60
            return segs == 0 ? "\(minutos) min" : "\(minutos):\(String(format: "%02d", segs)) min"
        }
    }
}
