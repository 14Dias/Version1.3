import Foundation
import RealmSwift
import Realm // IMPORTANTE: Necessário para acessar 'stringValue' do ObjectId
import FirebaseFirestore
import Combine

@MainActor
class FirebaseSyncManager: ObservableObject {
    static let shared = FirebaseSyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Upload (Realm -> Firestore)
    func sincronizarPendentes() async {
        guard !isSyncing else { return }
        isSyncing = true
        
        do {
            let realm = try await Realm()
            // Filtra objetos pendentes
            let pendentes = realm.objects(HistoricoExecucao.self).filter("pendingSync == true")
            
            if pendentes.isEmpty {
                isSyncing = false
                return
            }
            
            // Cria um array desconectado do Realm para iterar com segurança
            // (Congela os objetos para serem thread-safe na leitura)
            let itemsParaSync = Array(pendentes.freeze())
            
            for item in itemsParaSync {
                try await uploadItem(item)
            }
            
            lastSyncDate = Date()
            
        } catch {
            print("❌ Erro no Sync: \(error.localizedDescription)")
        }
        
        isSyncing = false
    }
    
    private func uploadItem(_ item: HistoricoExecucao) async throws {
        // Captura o ID e dados antes da tarefa assíncrona
        let idString = item._id.stringValue
        let idObjectId = item._id
        
        // Preparar dados
        let dados: [String: Any] = [
            "id": idString,
            "treinoID": item.treinoID,
            "treinoNome": item.treinoNome,
            "userUID": item.userUID,
            "dataExecucao": Timestamp(date: item.dataExecucao),
            "notas": item.notas,
            "duracaoSegundos": item.duracaoSegundos,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Salvar no Firestore
        try await db.collection("historico_execucoes").document(idString).setData(dados)
        
        // Captura a configuração na thread atual (sem await)
        let config = Realm.Configuration.defaultConfiguration
        
        // Atualizar Realm local em BACKGROUND (sem @MainActor)
        try await Task.detached {
            // Reabre o Realm na thread de background
            let bgRealm = try Realm(configuration: config)
            
            // Busca o objeto pelo ID
            if let obj = bgRealm.object(ofType: HistoricoExecucao.self, forPrimaryKey: idObjectId) {
                try bgRealm.write {
                    obj.pendingSync = false
                }
            }
        }.value
        
        print("✅ Item sincronizado: \(item.treinoNome)")
    }
    
    // MARK: - Download (Firestore -> Realm)
    func baixarHistoricoRemoto(userUID: String) async {
        guard !userUID.isEmpty else { return }
        isSyncing = true
        
        do {
            let snapshot = try await db.collection("historico_execucoes")
                .whereField("userUID", isEqualTo: userUID)
                .getDocuments()
            
            // Captura a configuração na thread atual (sem await)
            let config = Realm.Configuration.defaultConfiguration
            
            // Processar em BACKGROUND (sem @MainActor)
            try await Task.detached {
                let bgRealm = try Realm(configuration: config)
                
                try bgRealm.write {
                    for document in snapshot.documents {
                        let data = document.data()
                        let idStr = data["id"] as? String ?? document.documentID
                        
                        // Tenta converter string para ObjectId
                        guard let objectId = try? ObjectId(string: idStr) else { continue }
                        
                        let execucao = bgRealm.object(ofType: HistoricoExecucao.self, forPrimaryKey: objectId) ?? HistoricoExecucao()
                        
                        // Se for novo, define o ID
                        if execucao._id != objectId { execucao._id = objectId }
                        
                        execucao.treinoID = data["treinoID"] as? String ?? ""
                        execucao.treinoNome = data["treinoNome"] as? String ?? ""
                        execucao.userUID = userUID
                        if let timestamp = data["dataExecucao"] as? Timestamp {
                            execucao.dataExecucao = timestamp.dateValue()
                        }
                        execucao.notas = data["notas"] as? String ?? ""
                        execucao.duracaoSegundos = data["duracaoSegundos"] as? Int ?? 0
                        execucao.pendingSync = false
                        
                        bgRealm.add(execucao, update: .modified)
                    }
                }
            }.value
            
        } catch {
            print("❌ Erro ao baixar histórico: \(error)")
        }
        
        isSyncing = false
    }
}
