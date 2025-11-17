// Views/Treinos/Components/EditarExercicioView.swift - VERSÃO CORRIGIDA
import SwiftUI

struct EditarExercicioView: View {
    @Environment(\.dismiss) private var dismiss
    let exercicio: Exercicio
    let onSave: (Exercicio) -> Void // CORREÇÃO: Agora recebe o exercício editado
    let onCancel: () -> Void
    
    @State private var nome: String
    @State private var series: Int
    @State private var repeticoes: String
    @State private var tempoDescanso: Int
    @State private var observacoes: String
    @State private var peso: Int
    @State private var mostrarSucessoAlert = false
    
    // CORREÇÃO: Atualizar o inicializador para o novo tipo de onSave
    init(exercicio: Exercicio, onSave: @escaping (Exercicio) -> Void, onCancel: @escaping () -> Void) {
        self.exercicio = exercicio
        self.onSave = onSave
        self.onCancel = onCancel
        self._nome = State(initialValue: exercicio.nome)
        self._series = State(initialValue: exercicio.series)
        self._repeticoes = State(initialValue: exercicio.repeticoes)
        self._tempoDescanso = State(initialValue: exercicio.tempoDescanso)
        self._observacoes = State(initialValue: exercicio.observacoes)
        self._peso = State(initialValue: exercicio.peso)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informações Básicas") {
                    TextField("Nome do exercício", text: $nome)
                        .textInputAutocapitalization(.sentences)
                    
                    Stepper("Séries: \(series)", value: $series, in: 1...10)
                    
                    Picker("Repetições", selection: $repeticoes) {
                        ForEach(repeticoesOptions, id: \.self) { reps in
                            Text(reps).tag(reps)
                        }
                    }
                    
                    Stepper("Peso: \(peso) kg", value: $peso, in: 0...200)
                }
                
                Section("Descanso") {
                    Picker("Tempo de descanso", selection: $tempoDescanso) {
                        ForEach(tempoDescansoOptions, id: \.self) { tempo in
                            Text(formatarTempo(tempo)).tag(tempo)
                        }
                    }
                }
                
                Section("Observações") {
                    TextEditor(text: $observacoes)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Section {
                    Button("Salvar", role: .none) {
                        salvarAlteracoes()
                    }
                    .disabled(!podeSalvar)
                    .frame(maxWidth: .infinity)
                    
                    Button("Cancelar", role: .cancel) {
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Editar Exercício")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Exercício Salvo", isPresented: $mostrarSucessoAlert) {
                Button("OK", role: .cancel) {
                    // CORREÇÃO: Criar exercício editado e passar para onSave
                    let exercicioEditado = Exercicio(
                        id: exercicio.id,
                        nome: nome.trimmingCharacters(in: .whitespaces),
                        series: series,
                        repeticoes: repeticoes,
                        tempoDescanso: tempoDescanso,
                        observacoes: observacoes,
                        peso: peso
                    )
                    onSave(exercicioEditado)
                    dismiss()
                }
            } message: {
                Text("As alterações no exercício foram salvas com sucesso!")
            }
        }
    }
    
    private var repeticoesOptions: [String] {
        ["8", "10", "12", "15", "20", "Até a falha"]
    }
    
    private var tempoDescansoOptions: [Int] {
        [30, 45, 60, 90, 120, 180]
    }
    
    private var podeSalvar: Bool {
        !nome.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // CORREÇÃO: Remover a lógica de atualização direta do exercício original
    private func salvarAlteracoes() {
        mostrarSucessoAlert = true
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
