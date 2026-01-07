import Foundation

struct HistoricoExecucao: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    let treinoID: String
    let treinoNome: String
    let userUID: String
    let dataExecucao: Date
    let completado: Bool
    let notas: String
    let duracaoSegundos: Int
    
    init(id: String = UUID().uuidString, treinoID: String, treinoNome: String, userUID: String, dataExecucao: Date = Date(), completado: Bool = true, notas: String = "", duracaoSegundos: Int = 0) {
        self.id = id
        self.treinoID = treinoID
        self.treinoNome = treinoNome
        self.userUID = userUID
        self.dataExecucao = dataExecucao
        self.completado = completado
        self.notas = notas
        self.duracaoSegundos = duracaoSegundos
    }
}
