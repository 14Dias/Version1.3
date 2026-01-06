import Foundation

struct DadosFrequencia: Identifiable {
    let id = UUID()
    let diaSemana: String
    let quantidade: Int
}

struct DadosCalendario: Identifiable {
    let id = UUID()
    let data: Date
    let count: Int
}
