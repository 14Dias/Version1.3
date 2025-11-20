// Services/FirestoreService.swift
import Foundation
import FirebaseFirestore
import Combine

class FirestoreService {
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    // MARK: - User Methods
    func saveUserData(user: User) async throws {
        guard !user.userUID.isEmpty else { return }
        
        let userData: [String: Any] = [
            "username": user.username,
            "email": user.email,
            "userUID": user.userUID,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(user.userUID).setData(userData, merge: true)
        print("✅ Dados do usuário salvos/atualizados: \(user.username)")
    }
    
    func fetchUserData(userUID: String) async throws -> User? {
        guard !userUID.isEmpty else { return nil }
        let document = try await db.collection("users").document(userUID).getDocument()
        
        guard let data = document.data(),
              let username = data["username"] as? String,
              let email = data["email"] as? String else {
            return nil
        }
        
        return User(username: username, email: email, userUID: userUID)
    }
    
    // MARK: - Treino Methods (Embedded)
    
    func saveTreino(_ treino: Treino) async throws {
        guard !treino.userUID.isEmpty else { throw NSError(domain: "App", code: -1, userInfo: [NSLocalizedDescriptionKey: "UserUID vazio"]) }
        
        let data: [String: Any] = [
            "id": treino.id,
            "nome": treino.nome,
            "data": Timestamp(date: treino.data),
            "userUID": treino.userUID,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "exercicios": treino.exercicios.map { $0.toDictionary() }
        ]
        
        try await db.collection("treinos").document(treino.id).setData(data)
        print("✅ Treino salvo (Embedded): \(treino.nome)")
    }
    
    func updateTreino(_ treino: Treino) async throws {
        guard !treino.userUID.isEmpty else { return }
        
        let data: [String: Any] = [
            "id": treino.id,
            "nome": treino.nome,
            "data": Timestamp(date: treino.data),
            "userUID": treino.userUID,
            "updatedAt": Timestamp(date: Date()),
            "exercicios": treino.exercicios.map { $0.toDictionary() }
        ]
        
        try await db.collection("treinos").document(treino.id).setData(data, merge: true)
        print("✅ Treino atualizado: \(treino.nome)")
    }
    
    func fetchTreinos(userUID: String) async throws -> [Treino] {
        guard !userUID.isEmpty else { return [] }
        
        let snapshot = try await db.collection("treinos")
            .whereField("userUID", isEqualTo: userUID)
            .order(by: "data", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { parseTreino(from: $0.data(), documentID: $0.documentID) }
    }
    
    func deleteTreino(_ treino: Treino) async throws {
        try await db.collection("treinos").document(treino.id).delete()
        print("✅ Treino deletado: \(treino.nome)")
    }
    
    // MARK: - Listeners
    
    func startTreinosListener(userUID: String, completion: @escaping ([Treino]) -> Void) {
        guard !userUID.isEmpty else { return }
        
        stopListeners()
        
        print("🟡 Iniciando listener de treinos para: \(userUID)")
        let listener = db.collection("treinos")
            .whereField("userUID", isEqualTo: userUID)
            .order(by: "data", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("🔴 Erro no listener: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion([])
                    return
                }
                
                let treinos = documents.compactMap { self.parseTreino(from: $0.data(), documentID: $0.documentID) }
                completion(treinos)
            }
        
        listeners.append(listener)
    }
    
    func stopListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        print("🟡 Listeners parados")
    }
    
    // MARK: - Profissional (NOVO)
    
    func enviarSolicitacaoProfissional(userUID: String, nomeCompleto: String, cref: String, especialidade: String, biografia: String) async throws {
        let data: [String: Any] = [
            "userUID": userUID,
            "nomeCompleto": nomeCompleto,
            "cref": cref,
            "especialidade": especialidade,
            "biografia": biografia,
            "status": "pendente",
            "dataSolicitacao": Timestamp(date: Date())
        ]
        
        try await db.collection("solicitacoes_profissionais").document(userUID).setData(data)
    }
    
    // MARK: - Helpers
    
    private func parseTreino(from data: [String: Any], documentID: String) -> Treino? {
        guard let idString = data["id"] as? String,
              let nome = data["nome"] as? String,
              let timestamp = data["data"] as? Timestamp,
              let userUID = data["userUID"] as? String else {
            return nil
        }
        
        let exerciciosData = data["exercicios"] as? [[String: Any]] ?? []
        let exercicios = exerciciosData.compactMap { Exercicio(dictionary: $0) }
        
        return Treino(id: idString, nome: nome, data: timestamp.dateValue(), exercicios: exercicios, userUID: userUID)
    }
    
    // MARK: - Favoritos
    
    func adicionarFavorito(treinoID: String, userUID: String) async throws {
        let favoritosAtuais = try await fetchFavoritos(userUID: userUID)
        if favoritosAtuais.count >= 3 {
            throw NSError(domain: "App", code: -2, userInfo: [NSLocalizedDescriptionKey: "Limite de favoritos atingido"])
        }
        if favoritosAtuais.contains(where: { $0.treinoID == treinoID }) { return }
        
        let favorito = Favorito(treinoID: treinoID, userUID: userUID)
        let data: [String: Any] = [
            "id": favorito.id,
            "treinoID": favorito.treinoID,
            "userUID": favorito.userUID,
            "dataAdicionado": Timestamp(date: favorito.dataAdicionado)
        ]
        try await db.collection("favoritos").document(favorito.id).setData(data)
    }
    
    func removerFavorito(treinoID: String, userUID: String) async throws {
        let snapshot = try await db.collection("favoritos")
            .whereField("treinoID", isEqualTo: treinoID)
            .whereField("userUID", isEqualTo: userUID)
            .getDocuments()
        
        for doc in snapshot.documents {
            try await doc.reference.delete()
        }
    }
    
    func fetchFavoritos(userUID: String) async throws -> [Favorito] {
        guard !userUID.isEmpty else { return [] }
        let snapshot = try await db.collection("favoritos")
            .whereField("userUID", isEqualTo: userUID)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let tID = data["treinoID"] as? String, let uID = data["userUID"] as? String else { return nil }
            let id = data["id"] as? String ?? doc.documentID
            return Favorito(id: id, treinoID: tID, userUID: uID)
        }
    }
    
    func fetchTreinosFavoritos(userUID: String) async throws -> [Treino] {
        let favoritos = try await fetchFavoritos(userUID: userUID)
        var treinos: [Treino] = []
        
        for fav in favoritos {
            let doc = try await db.collection("treinos").document(fav.treinoID).getDocument()
            if let data = doc.data(), let treino = parseTreino(from: data, documentID: fav.treinoID) {
                treinos.append(treino)
            }
        }
        return treinos
    }
}

extension Exercicio {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "nome": nome,
            "series": series,
            "repeticoes": repeticoes,
            "peso": peso,
            "tempoDescanso": tempoDescanso,
            "observacoes": observacoes
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let idStr = dictionary["id"] as? String,
              let nome = dictionary["nome"] as? String else { return nil }
        
        self.init(
            id: idStr,
            nome: nome,
            series: dictionary["series"] as? Int ?? 3,
            repeticoes: dictionary["repeticoes"] as? String ?? "10",
            tempoDescanso: dictionary["tempoDescanso"] as? Int ?? 60,
            observacoes: dictionary["observacoes"] as? String ?? "",
            peso: dictionary["peso"] as? Int ?? 0
        )
    }
}

extension Favorito {
    init(id: String = UUID().uuidString, treinoID: String, userUID: String) {
        self.id = id
        self.treinoID = treinoID
        self.userUID = userUID
        self.dataAdicionado = Date()
    }
}
