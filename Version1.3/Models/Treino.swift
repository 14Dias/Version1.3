import Foundation

struct Treino: Identifiable, Codable, Hashable {
    let id: String
    var nome: String
    var data: Date
    var exercicios: [Exercicio]
    var userUID: String
    var isFavorito: Bool = false // Adicionado para facilitar UI local
    
    // Init padrão
    init(id: String = UUID().uuidString, nome: String, data: Date = Date(), exercicios: [Exercicio] = [], userUID: String) {
        self.id = id
        self.nome = nome
        self.data = data
        self.exercicios = exercicios
        self.userUID = userUID
    }
}
