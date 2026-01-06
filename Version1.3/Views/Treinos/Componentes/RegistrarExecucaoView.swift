import SwiftUI

struct RegistrarExecucaoView: View {
    @Environment(\.dismiss) private var dismiss
    let treino: Treino
    let userUID: String
    
    @StateObject private var viewModel: HistoricoViewModel
    @State private var notas = ""
    @State private var duracao = 60 // minutos padrão estimado
    
    init(treino: Treino, userUID: String) {
        self.treino = treino
        self.userUID = userUID
        _viewModel = StateObject(wrappedValue: HistoricoViewModel(userUID: userUID))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Detalhes") {
                    Text(treino.nome)
                        .font(.headline)
                    
                    DatePicker("Data", selection: .constant(Date()), displayedComponents: [.date, .hourAndMinute])
                        .disabled(true) // Apenas registra o momento atual por simplificação
                }
                
                Section("Feedback") {
                    TextField("Notas sobre o treino (opcional)", text: $notas, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Stepper("Duração: \(duracao) min", value: $duracao, in: 10...180, step: 5)
                }
                
                Section {
                    Button {
                        Task {
                            await viewModel.registrarExecucao(
                                treino: treino,
                                notas: notas,
                                duracao: duracao * 60
                            )
                            dismiss()
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Concluir Treino")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .listRowBackground(Color.green)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Registrar Treino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
