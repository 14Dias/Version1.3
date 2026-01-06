import Foundation

class WgerService {
    // URL Base da API v2
    private let baseURL = "https://wger.de/1aa73ca6fb56baed85f94c2386a360d19b8edd74/v2"
    
    // Busca exercícios (Filtrando por idioma: 2 = Inglês. PT-BR às vezes é incompleto, mas você pode tentar language=5)
    func fetchExercises() async throws -> [WgerExercise] {
        // limit=20 para pegar 20 por vez. status=2 significa "aceito/verificado"
        guard let url = URL(string: "\(baseURL)/exercise/?language=5&limit=20&status=2") else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WgerResponse<WgerExercise>.self, from: data)
        
        var exercises = response.results
        
        // Passo extra: Buscar imagens para estes exercícios
        // Nota: Isso é uma simplificação. Em produção, idealmente buscamos imagens sob demanda ou em cache.
        let images = try await fetchImages()
        
        // Associar imagem ao exercício correto
        for i in 0..<exercises.count {
            if let match = images.first(where: { $0.exerciseId == exercises[i].id }) {
                exercises[i].mainImageUrl = match.image
            }
        }
        
        return exercises
    }
    
    // Busca lista de imagens públicas
    private func fetchImages() async throws -> [WgerImage] {
        guard let url = URL(string: "\(baseURL)/exerciseimage/?limit=50") else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WgerResponse<WgerImage>.self, from: data)
        
        return response.results
    }
}
