import Foundation

struct Treino: Identifiable, Codable, Hashable {
    let id: String
    var nome: String
    var data: Date
    var exercicios: [Exercicio]
    var userUID: String      // ID do dono do treino (o Aluno que vai treinar)
    var professionalUID: String? // NOVO: ID do profissional que criou (opcional)
    var isFavorito: Bool = false
    
    // Init atualizado
    init(id: String = UUID().uuidString,
         nome: String,
         data: Date = Date(),
         exercicios: [Exercicio] = [],
         userUID: String,
         professionalUID: String? = nil) { // Parâmetro opcional
        self.id = id
        self.nome = nome
        self.data = data
        self.exercicios = exercicios
        self.userUID = userUID
        self.professionalUID = professionalUID
    }
}
