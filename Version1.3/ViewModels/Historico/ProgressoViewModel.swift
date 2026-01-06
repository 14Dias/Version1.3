import SwiftUI
import RealmSwift
import Charts
import Combine
@MainActor
class ProgressoViewModel: ObservableObject {
    @Published var totalTreinos: Int = 0
    @Published var frequenciaSemanal: [DadosFrequencia] = []
    @Published var dadosCalendario: [DadosCalendario] = []
    @Published var isLoading = false
    
    private var userUID: String
    
    init(userUID: String) {
        self.userUID = userUID
    }
    
    func carregarDados() {
        isLoading = true
        
        guard let realm = try? Realm() else { return }
        let execucoes = realm.objects(HistoricoExecucao.self)
            .filter("userUID == %@", userUID)
        
        // 1. Total
        self.totalTreinos = execucoes.count
        
        // 2. Frequência Semanal (Últimos 7 dias)
        processarFrequencia(execucoes)
        
        // 3. Calendário (Mapa de calor básico)
        processarCalendario(execucoes)
        
        isLoading = false
    }
    
    private func processarFrequencia(_ execucoes: Results<HistoricoExecucao>) {
        var counts = [String: Int]()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE" // Seg, Ter...
        
        // Inicializar com 0
        let diasOrdem = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
        for dia in diasOrdem { counts[dia] = 0 }
        
        for exec in execucoes {
            let dia = dateFormatter.string(from: exec.dataExecucao).capitalized.replacingOccurrences(of: ".", with: "")
            counts[dia, default: 0] += 1
        }
        
        self.frequenciaSemanal = diasOrdem.map { dia in
            DadosFrequencia(diaSemana: dia, quantidade: counts[dia] ?? 0)
        }
    }
    
    private func processarCalendario(_ execucoes: Results<HistoricoExecucao>) {
        let calendar = Calendar.current
        // Agrupar por dia
        let agrupado = Dictionary(grouping: execucoes) { exec in
            calendar.startOfDay(for: exec.dataExecucao)
        }
        
        self.dadosCalendario = agrupado.map { (date, items) in
            DadosCalendario(data: date, count: items.count)
        }
    }
}
