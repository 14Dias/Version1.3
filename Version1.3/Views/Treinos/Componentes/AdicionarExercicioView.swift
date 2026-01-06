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

struct WgerExerciseListView: View {
    @State private var exercises: [WgerExercise] = []
    @State private var isLoading = true
    private let service = WgerService()
    
    // Callback para quando o usuário escolher um exercício
    var onSelect: (WgerExercise) -> Void
    
    var body: some View {
        NavigationStack {
            List(exercises) { exercise in
                Button {
                    onSelect(exercise)
                } label: {
                    HStack {
                        // Exibir imagem se existir
                        if let urlString = exercise.mainImageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                        } else {
                            // Placeholder se não tiver imagem
                            Image(systemName: "dumbbell.fill")
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)
                            // Remove tags HTML da descrição se necessário (Wger retorna HTML)
                            Text("Toque para selecionar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Exercícios Wger")
            .task {
                do {
                    exercises = try await service.fetchExercises()
                    isLoading = false
                } catch {
                    print("Erro Wger: \(error)")
                    isLoading = false
                }
            }
            .overlay {
                if isLoading { ProgressView() }
            }
        }
    }
}
