import SwiftUI
import RealmSwift
import Combine
import Realm

@MainActor
class HistoricoViewModel: ObservableObject {
    @Published var execucoes: [HistoricoExecucao] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var token: NotificationToken?
    private var userUID: String
    
    init(userUID: String) {
        self.userUID = userUID
        setupObserver()
    }
    
    deinit {
        token?.invalidate()
    }
    
    // MARK: - Observer Realm
    private func setupObserver() {
        do {
            let realm = try Realm()
            let results = realm.objects(HistoricoExecucao.self)
                .filter("userUID == %@", userUID)
                .sorted(byKeyPath: "dataExecucao", ascending: false)
            
            token = results.observe { [weak self] changes in
                guard let self = self else { return }
                switch changes {
                case .initial(let items), .update(let items, _, _, _):
                    self.execucoes = Array(items)
                case .error(let error):
                    self.errorMessage = "Erro no Realm: \(error.localizedDescription)"
                }
            }
        } catch {
            errorMessage = "Falha ao iniciar Realm: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Ações
    func registrarExecucao(treino: Treino, notas: String, duracao: Int) async {
        isLoading = true
        
        // Operação de escrita em background (nonisolated logic)
        await performBackgroundWrite(
            treinoID: treino.id,
            nome: treino.nome,
            userUID: self.userUID,
            notas: notas,
            duracao: duracao
        )
        
        isLoading = false
        
        // Gatilho para sync (Sistema 2)
        Task {
            await FirebaseSyncManager.shared.sincronizarPendentes()
        }
    }
    
    // Lógica fora da MainActor para não travar UI
    nonisolated private func performBackgroundWrite(treinoID: String, nome: String, userUID: String, notas: String, duracao: Int) async {
        do {
            let realm = try await Realm(actor: MainActor.shared) // Acesso seguro thread-safe
            // Nota: Em versões recentes do Realm Swift com actors, é melhor abrir uma instância local na thread
            // Para simplificar e garantir segurança:
            let config = Realm.Configuration.defaultConfiguration
            
            try await Task.detached {
                let bgRealm = try Realm(configuration: config)
                let execucao = HistoricoExecucao()
                execucao.treinoID = treinoID
                execucao.treinoNome = nome
                execucao.userUID = userUID
                execucao.dataExecucao = Date()
                execucao.notas = notas
                execucao.duracaoSegundos = duracao
                execucao.pendingSync = true // Marca para sync
                
                try bgRealm.write {
                    bgRealm.add(execucao)
                }
            }.value
        } catch {
            print("❌ Erro ao salvar execução: \(error)")
        }
    }
}
