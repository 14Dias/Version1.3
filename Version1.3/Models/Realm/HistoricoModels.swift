import Foundation
import RealmSwift

// Objeto Realm para o Histórico
class HistoricoExecucao: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var treinoID: String // ID do Treino (vinculo com o struct Treino)
    @Persisted var treinoNome: String
    @Persisted var userUID: String
    @Persisted var dataExecucao: Date = Date()
    @Persisted var completado: Bool = true
    @Persisted var notas: String = ""
    @Persisted var pesoTotalLevantado: Int = 0
    @Persisted var duracaoSegundos: Int = 0
    
    // Controle de Sincronização
    @Persisted var pendingSync: Bool = true
    @Persisted var updatedAt: Date = Date()
    
    convenience init(treinoID: String, nome: String, userUID: String, notas: String) {
        self.init()
        self.treinoID = treinoID
        self.treinoNome = nome
        self.userUID = userUID
        self.notas = notas
    }
}
