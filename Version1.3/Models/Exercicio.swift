// Models/Exercicio.swift - VERSÃO CORRIGIDA
import Foundation
import Combine

class Exercicio: Identifiable, ObservableObject {
    var id: UUID
    var nome: String
    var series: Int
    var repeticoes: String
    var tempoDescanso: Int // em segundos
    var observacoes: String
    var peso: Int // kg
    // REMOVER: weak var treino: Treino? - Causa referência circular
    
    init(id: UUID = UUID(), nome: String, series: Int = 3, repeticoes: String = "10", tempoDescanso: Int = 60, observacoes: String = "", peso: Int = 10) {
        self.id = id
        self.nome = nome
        self.series = series
        self.repeticoes = repeticoes
        self.tempoDescanso = tempoDescanso
        self.observacoes = observacoes
        self.peso = peso
    }
}
