// Views/Treinos/MontarTreinoView.swift - VERSÃO CORRIGIDA
import SwiftUI

struct MontarTreinoView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = CreateTreinoViewModel() // CORREÇÃO: Inicialização direta
    @State private var mostrarAdicionarExercicio = false // CORREÇÃO: Adicionar estado faltante
    @State private var mostrarAlertaSucesso = false // CORREÇÃO: Adicionar estado faltante
    
    var body: some View {
        List {
            Section("Nome do Treino") {
                TextField("Ex: Treino A - Peito e Tríceps", text: $viewModel.nomeTreino)
                    .textInputAutocapitalization(.sentences)
            }
            
            Section("Exercícios") {
                if viewModel.exercicios.isEmpty {
                    Text("Nenhum exercício adicionado")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(viewModel.exercicios) { exercicio in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercicio.nome)
                                .font(.headline)
                            Text("\(exercicio.series) Séries × \(exercicio.repeticoes) Reps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Peso: \(exercicio.peso) Kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: viewModel.removerExercicio)
                }
                
                Button {
                    mostrarAdicionarExercicio = true // CORREÇÃO: Usar estado correto
                } label: {
                    Label("Adicionar Exercício", systemImage: "plus.circle.fill")
                }
            }
            
            Section {
                Button {
                    salvarTreino()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                            Text("Salvando...")
                                .fontWeight(.semibold)
                                .padding(.leading, 8)
                        } else {
                            Text("Salvar Treino")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!viewModel.podeSalvar || viewModel.isLoading)
                .listRowBackground(buttonBackground)
                .foregroundColor((!viewModel.podeSalvar || viewModel.isLoading) ? .gray : .white)
            }
        }
        .navigationTitle("Montar Treino")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // CORREÇÃO: Garantir que o ViewModel tem o userUID atual
            if viewModel.userUID.isEmpty, let userUID = authViewModel.currentUserUID {
                viewModel.userUID = userUID
            }
        }
        .sheet(isPresented: $mostrarAdicionarExercicio) { // CORREÇÃO: Usar binding correto
            AdicionarExercicioView { novoExercicio in
                viewModel.adicionarExercicio(novoExercicio)
            }
        }
        .alert("Treino Salvo!", isPresented: $mostrarAlertaSucesso) { // CORREÇÃO: Usar binding correto
            Button("OK") {
                viewModel.limparCampos()
            }
        } message: {
            if !viewModel.nomeTreino.isEmpty {
                Text("Seu treino \"\(viewModel.nomeTreino)\" foi salvo com sucesso!")
            } else {
                Text("Seu treino foi salvo com sucesso!")
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Salvando...")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
            }
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        if !viewModel.podeSalvar || viewModel.isLoading {
            Color.gray.opacity(0.3)
        } else {
            LinearGradient(
                colors: [.blue.opacity(0.9), .blue.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private func salvarTreino() {
        Task {
            let sucesso = await viewModel.salvarTreino()
            if sucesso {
                mostrarAlertaSucesso = true // CORREÇÃO: Usar estado correto
            }
        }
    }
}
