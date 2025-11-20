import Foundation

struct Exercicio: Identifiable, Codable, Hashable {
    let id: String
    var nome: String
    var series: Int
    var repeticoes: String
    var tempoDescanso: Int // segundos
    var observacoes: String
    var peso: Int // kg
    
    init(id: String = UUID().uuidString, nome: String, series: Int = 3, repeticoes: String = "10", tempoDescanso: Int = 60, observacoes: String = "", peso: Int = 10) {
        self.id = id
        self.nome = nome
        self.series = series
        self.repeticoes = repeticoes
        self.tempoDescanso = tempoDescanso
        self.observacoes = observacoes
        self.peso = peso
    }
}
