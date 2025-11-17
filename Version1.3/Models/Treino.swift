// Models/Treino.swift
import Foundation
import Combine

class Treino: Identifiable, ObservableObject {
    var id: UUID
    var nome: String
    var data: Date
    var exercicios: [Exercicio]
    var userUID: String
    
    init(id: UUID = UUID(), nome: String, data: Date = Date(), exercicios: [Exercicio] = [], userUID: String) {
        self.id = id
        self.nome = nome
        self.data = data
        self.exercicios = exercicios
        self.userUID = userUID
    }
}
