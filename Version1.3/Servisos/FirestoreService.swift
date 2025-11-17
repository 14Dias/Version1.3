// Services/FirestoreService.swift - VERSÃO CORRIGIDA
import Foundation
import FirebaseFirestore
import Combine

class FirestoreService {
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    // MARK: - User Methods
    func saveUserData(user: User) async throws {
        guard !user.userUID.isEmpty else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "UserUID não pode ser vazio"])
        }
        
        let userData: [String: Any] = [
            "username": user.username,
            "email": user.email,
            "userUID": user.userUID,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("users").document(user.userUID).setData(userData)
            print("✅ Dados do usuário salvos no Firestore: \(user.username)")
        } catch {
            print("🔴 Erro ao salvar dados do usuário: \(error)")
            throw error
        }
    }
    
    func fetchUserData(userUID: String) async throws -> User? {
        guard !userUID.isEmpty else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "UserUID não pode ser vazio"])
        }
        
        do {
            let document = try await db.collection("users").document(userUID).getDocument()
            
            guard document.exists,
                  let data = document.data(),
                  let username = data["username"] as? String,
                  let email = data["email"] as? String else {
                return nil
            }
            
            return User(username: username, email: email, userUID: userUID)
            
        } catch {
            print("🔴 Erro ao buscar dados do usuário: \(error)")
            throw error
        }
    }
    
    // MARK: - Treino Methods
    func saveTreino(_ treino: Treino) async throws {
        guard !treino.userUID.isEmpty else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "UserUID não pode ser vazio"])
        }
        
        guard !treino.nome.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(domain: "FirestoreService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Nome do treino não pode ser vazio"])
        }
        
        print("🟡 Salvando treino: \(treino.nome) para usuário: \(treino.userUID)")
        
        let treinoData: [String: Any] = [
            "id": treino.id.uuidString,
            "nome": treino.nome,
            "data": Timestamp(date: treino.data),
            "userUID": treino.userUID,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("treinos").document(treino.id.uuidString).setData(treinoData)
            print("✅ Treino salvo com sucesso: \(treino.nome)")
            
            // Salvar exercícios
            for (index, exercicio) in treino.exercicios.enumerated() {
                do {
                    try await saveExercicio(exercicio, treinoID: treino.id.uuidString)
                    print("✅ Exercício \(index + 1) salvo: \(exercicio.nome)")
                } catch {
                    print("🔴 Erro ao salvar exercício \(index + 1): \(error)")
                    // Continuar salvando outros exercícios
                }
            }
            
        } catch {
            print("🔴 Erro ao salvar treino no Firestore: \(error)")
            throw error
        }
    }
    
    private func saveExercicio(_ exercicio: Exercicio, treinoID: String) async throws {
            let exercicioData: [String: Any] = [
                "id": exercicio.id.uuidString,
                "nome": exercicio.nome,
                "series": exercicio.series,
                "repeticoes": exercicio.repeticoes,
                "tempoDescanso": exercicio.tempoDescanso,
                "observacoes": exercicio.observacoes,
                "peso": exercicio.peso,
                "treinoID": treinoID,
                "createdAt": Timestamp(date: Date())
            ]
            
            try await db.collection("exercicios").document(exercicio.id.uuidString).setData(exercicioData)
        }
    
    func fetchTreinos(userUID: String) async throws -> [Treino] {
        guard !userUID.isEmpty else {
            print("🔴🔴🔴 ERRO CRÍTICO: fetchTreinos chamado com UserUID vazio")
            // Log mais detalhado para identificar a origem
            print("🔴 Call Stack:")
            for symbol in Thread.callStackSymbols.prefix(5) {
                print("   \(symbol)")
            }
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "UserUID não pode ser vazio"])
        }
        
        print("🟢 fetchTreinos iniciado para UserUID: \(userUID)")
        
        do {
            let snapshot = try await db.collection("treinos")
                .whereField("userUID", isEqualTo: userUID)
                .order(by: "data", descending: true)
                .getDocuments()
            
            var treinos: [Treino] = []
            
            for document in snapshot.documents {
                let data = document.data()
                if let treino = await parseTreino(from: data, documentID: document.documentID) {
                    treinos.append(treino)
                }
            }
            
            print("✅ fetchTreinos concluído: \(treinos.count) treinos")
            return treinos
            
        } catch {
            print("🔴 Erro no fetchTreinos: \(error)")
            throw error
        }
    }
    
    private func parseTreino(from data: [String: Any], documentID: String) async -> Treino? {
        guard let idString = data["id"] as? String,
              let uuid = UUID(uuidString: idString),
              let nome = data["nome"] as? String,
              let timestamp = data["data"] as? Timestamp,
              let userUID = data["userUID"] as? String else {
            return nil
        }
        
        let data = timestamp.dateValue()
        let treino = Treino(id: uuid, nome: nome, data: data, exercicios: [], userUID: userUID)
        
        // Carregar exercícios deste treino
        do {
            let exercicios = try await fetchExercicios(treinoID: documentID)
            treino.exercicios = exercicios
        } catch {
            print("⚠️ Erro ao carregar exercícios do treino \(nome): \(error)")
        }
        
        return treino
    }
    
    private func fetchExercicios(treinoID: String) async throws -> [Exercicio] {
        let snapshot = try await db.collection("exercicios")
            .whereField("treinoID", isEqualTo: treinoID)
            .getDocuments()
        
        var exercicios: [Exercicio] = []
        
        for document in snapshot.documents {
            let data = document.data()
            if let exercicio = parseExercicio(from: data) {
                exercicios.append(exercicio)
            }
        }
        
        return exercicios
    }
    
    private func parseExercicio(from data: [String: Any]) -> Exercicio? {
        guard let idString = data["id"] as? String,
              let uuid = UUID(uuidString: idString),
              let nome = data["nome"] as? String else {
            return nil
        }
        
        let series = data["series"] as? Int ?? 3
        let repeticoes = data["repeticoes"] as? String ?? "10"
        let tempoDescanso = data["tempoDescanso"] as? Int ?? 60
        let observacoes = data["observacoes"] as? String ?? ""
        let peso = data["peso"] as? Int ?? 10
        
        return Exercicio(
            id: uuid,
            nome: nome,
            series: series,
            repeticoes: repeticoes,
            tempoDescanso: tempoDescanso,
            observacoes: observacoes,
            peso: peso
        )
    }
    
    func deleteTreino(_ treino: Treino) async throws {
        do {
            // Primeiro deletar todos os exercícios do treino
            let exerciciosSnapshot = try await db.collection("exercicios")
                .whereField("treinoID", isEqualTo: treino.id.uuidString)
                .getDocuments()
            
            for document in exerciciosSnapshot.documents {
                try await document.reference.delete()
            }
            
            // Depois deletar o treino
            try await db.collection("treinos").document(treino.id.uuidString).delete()
            print("✅ Treino deletado: \(treino.nome)")
            
        } catch {
            print("🔴 Erro ao deletar treino: \(error)")
            throw error
        }
    }
    
    // MARK: - Listener Methods
    func startTreinosListener(userUID: String, completion: @escaping ([Treino]) -> Void) {
        guard !userUID.isEmpty else { return }
        
        let listener = db.collection("treinos")
            .whereField("userUID", isEqualTo: userUID)
            .order(by: "data", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("🔴 Erro no listener de treinos: \(error)")
                    return
                }
                
                Task {
                    var treinos: [Treino] = []
                    
                    if let documents = querySnapshot?.documents {
                        for document in documents {
                            let data = document.data()
                            if let treino = await self.parseTreino(from: data, documentID: document.documentID) {
                                treinos.append(treino)
                            }
                        }
                    }
                    
                    completion(treinos)
                }
            }
        
        listeners.append(listener)
    }
    
    func stopListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        print("🟡 Listeners do Firestore parados")
    }
}

// Services/FirestoreService.swift - ADIÇÃO DO MÉTODO updateTreino
extension FirestoreService {
    
    func updateTreino(_ treino: Treino) async throws {
        guard !treino.userUID.isEmpty else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "UserUID não pode ser vazio"])
        }
        
        guard !treino.nome.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(domain: "FirestoreService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Nome do treino não pode ser vazio"])
        }
        
        print("🟡 Atualizando treino: \(treino.nome) para usuário: \(treino.userUID)")
        
        let treinoData: [String: Any] = [
            "id": treino.id.uuidString,
            "nome": treino.nome,
            "data": Timestamp(date: treino.data),
            "userUID": treino.userUID,
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            // Atualizar dados do treino
            try await db.collection("treinos").document(treino.id.uuidString).setData(treinoData, merge: true)
            print("✅ Treino atualizado com sucesso: \(treino.nome)")
            
            // Primeiro deletar exercícios antigos
            let exerciciosSnapshot = try await db.collection("exercicios")
                .whereField("treinoID", isEqualTo: treino.id.uuidString)
                .getDocuments()
            
            for document in exerciciosSnapshot.documents {
                try await document.reference.delete()
            }
            
            // Salvar novos exercícios
            for (index, exercicio) in treino.exercicios.enumerated() {
                do {
                    try await saveExercicio(exercicio, treinoID: treino.id.uuidString)
                    print("✅ Exercício \(index + 1) salvo: \(exercicio.nome)")
                } catch {
                    print("🔴 Erro ao salvar exercício \(index + 1): \(error)")
                    // Continuar salvando outros exercícios
                }
            }
            
        } catch {
            print("🔴 Erro ao atualizar treino no Firestore: \(error)")
            throw error
        }
    }
}

// Services/FirestoreService.swift - ADIÇÕES PARA FAVORITOS
extension FirestoreService {
    
    // MARK: - Favoritos Methods
    func adicionarFavorito(treinoID: String, userUID: String) async throws {
        guard !treinoID.isEmpty, !userUID.isEmpty else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "IDs não podem ser vazios"])
        }
        
        // Verificar limite de 3 favoritos
        let favoritosAtuais = try await fetchFavoritos(userUID: userUID)
        if favoritosAtuais.count >= 3 {
            throw NSError(domain: "FirestoreService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Limite de 3 treinos favoritos atingido"])
        }
        
        // Verificar se já é favorito
        if favoritosAtuais.contains(where: { $0.treinoID == treinoID }) {
            throw NSError(domain: "FirestoreService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Treino já está nos favoritos"])
        }
        
        let favorito = Favorito(treinoID: treinoID, userUID: userUID)
        
        let favoritoData: [String: Any] = [
            "id": favorito.id,
            "treinoID": favorito.treinoID,
            "userUID": favorito.userUID,
            "dataAdicionado": Timestamp(date: favorito.dataAdicionado)
        ]
        
        try await db.collection("favoritos").document(favorito.id).setData(favoritoData)
        print("✅ Favorito adicionado: \(treinoID)")
    }
    
    func removerFavorito(treinoID: String, userUID: String) async throws {
        guard !treinoID.isEmpty, !userUID.isEmpty else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "IDs não podem ser vazios"])
        }
        
        let snapshot = try await db.collection("favoritos")
            .whereField("treinoID", isEqualTo: treinoID)
            .whereField("userUID", isEqualTo: userUID)
            .getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
        
        print("✅ Favorito removido: \(treinoID)")
    }
    
    func fetchFavoritos(userUID: String) async throws -> [Favorito] {
        guard !userUID.isEmpty else {
            throw NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "UserUID não pode ser vazio"])
        }
        
        let snapshot = try await db.collection("favoritos")
            .whereField("userUID", isEqualTo: userUID)
            .order(by: "dataAdicionado", descending: true)
            .getDocuments()
        
        var favoritos: [Favorito] = []
        
        for document in snapshot.documents {
            let data = document.data()
            if let favorito = parseFavorito(from: data) {
                favoritos.append(favorito)
            }
        }
        
        return favoritos
    }
    
    func fetchTreinosFavoritos(userUID: String) async throws -> [Treino] {
        let favoritos = try await fetchFavoritos(userUID: userUID)
        var treinosFavoritos: [Treino] = []
        
        for favorito in favoritos {
            // Buscar o treino completo pelo ID
            let document = try await db.collection("treinos").document(favorito.treinoID).getDocument()
            if let data = document.data(), let treino = await parseTreino(from: data, documentID: favorito.treinoID) {
                treinosFavoritos.append(treino)
            }
        }
        
        return treinosFavoritos
    }
    
    func isTreinoFavorito(treinoID: String, userUID: String) async throws -> Bool {
        let favoritos = try await fetchFavoritos(userUID: userUID)
        return favoritos.contains(where: { $0.treinoID == treinoID })
    }
    
    // ADICIONAR: Método para limpar favoritos órfãos
    func limparFavoritosOrfaos(userUID: String) async throws {
        guard !userUID.isEmpty else { return }
        
        print("🟡 Verificando favoritos órfãos para UserUID: \(userUID)")
        
        let favoritos = try await fetchFavoritos(userUID: userUID)
        var favoritosParaRemover: [String] = []
        
        for favorito in favoritos {
            let treinoDocument = try await db.collection("treinos").document(favorito.treinoID).getDocument()
            if !treinoDocument.exists {
                print("🟡 Encontrado favorito órfão: \(favorito.treinoID)")
                favoritosParaRemover.append(favorito.treinoID)
            }
        }
        
        // Remover favoritos órfãos
        for treinoID in favoritosParaRemover {
            try await removerFavorito(treinoID: treinoID, userUID: userUID)
            print("✅ Favorito órfão removido: \(treinoID)")
        }
        
        print("✅ Limpeza de favoritos órfãos concluída")
    }
    
    private func parseFavorito(from data: [String: Any]) -> Favorito? {
        guard let id = data["id"] as? String,
              let treinoID = data["treinoID"] as? String,
              let userUID = data["userUID"] as? String,
              let timestamp = data["dataAdicionado"] as? Timestamp else {
            return nil
        }
        return Favorito(
            treinoID: treinoID,
            userUID: userUID
        )
    }
}
