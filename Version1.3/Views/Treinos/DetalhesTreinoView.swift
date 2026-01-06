import SwiftUI

struct DetalhesTreinoView: View {
    let treino: Treino
    // MARK: - Propriedades Adicionadas
    @EnvironmentObject var authViewModel: AuthViewModel // Necessário para acessar o ID do usuário
    @State private var showingEditView = false
    @State private var showRegistrarSheet = false // Controla a abertura da tela de registro
    
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
            // MARK: - Botão de Ação (Novo)
            Section {
                Button {
                    showRegistrarSheet = true
                } label: {
                    Label("Concluir Treino Agora", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.headline)
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
        // Sheet de Edição (Existente)
        .sheet(isPresented: $showingEditView) {
            NavigationStack {
                EditarTreinoView(
                    treino: treino,
                    onSave: {
                        showingEditView = false
                    },
                    onCancel: {
                        showingEditView = false
                    }
                )
            }
        }
        // MARK: - Sheet de Registro (Novo)
        .sheet(isPresented: $showRegistrarSheet) {
            if let uid = authViewModel.currentUserUID {
                // Certifique-se de ter criado o arquivo 'RegistrarExecucaoView.swift' anteriormente
                RegistrarExecucaoView(treino: treino, userUID: uid)
            } else {
                VStack {
                    Text("Erro: Usuário não identificado")
                    Button("Fechar") { showRegistrarSheet = false }
                }
            }
            
        }
        
    }
}
