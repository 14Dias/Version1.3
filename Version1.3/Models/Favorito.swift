// Models/Favorito.swift - NOVO ARQUIVO
import Foundation

struct Favorito: Codable, Identifiable {
    let id: String
    let treinoID: String
    let userUID: String
    let dataAdicionado: Date
    
    init(treinoID: String, userUID: String) {
        self.id = UUID().uuidString
        self.treinoID = treinoID
        self.userUID = userUID
        self.dataAdicionado = Date()
    }
}
