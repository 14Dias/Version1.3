import SwiftUI
import Charts

struct ProgressoView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProgressoViewModel
    @StateObject private var syncManager = FirebaseSyncManager.shared
    
    init(userUID: String) {
        _viewModel = StateObject(wrappedValue: ProgressoViewModel(userUID: userUID))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Header Status
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total de Treinos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.totalTreinos)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        
                        if syncManager.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button {
                                Task { await syncManager.baixarHistoricoRemoto(userUID: viewModel.totalTreinos > 0 ? "" : (authViewModel.currentUserUID ?? "")) }
                                viewModel.carregarDados()
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Gráfico 1: Barras Semanais
                    VStack(alignment: .leading) {
                        Text("Frequência Semanal")
                            .font(.headline)
                        
                        Chart(viewModel.frequenciaSemanal) { item in
                            BarMark(
                                x: .value("Dia", item.diaSemana),
                                y: .value("Treinos", item.quantidade)
                            )
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .purple], startPoint: .bottom, endPoint: .top)
                            )
                            .annotation(position: .top) {
                                if item.quantidade > 0 {
                                    Text("\(item.quantidade)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(height: 200)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Gráfico 2: Heatmap (Calendário Simplificado)
                    VStack(alignment: .leading) {
                        Text("Histórico Recente")
                            .font(.headline)
                        
                        if viewModel.dadosCalendario.isEmpty {
                            Text("Nenhum dado registrado")
                                .font(.caption)
                                .padding()
                        } else {
                            Chart(viewModel.dadosCalendario) { item in
                                PointMark(
                                    x: .value("Data", item.data),
                                    y: .value("Qtd", item.count)
                                )
                                .symbolSize(100)
                                .foregroundStyle(item.count > 0 ? Color.green : Color.gray)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day))
                            }
                            .frame(height: 150)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progresso")
            .onAppear {
                viewModel.carregarDados()
            }
        }
    }
}
