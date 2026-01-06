import Foundation

// Resposta padrão da API (paginação)
struct WgerResponse<T: Codable>: Codable {
    let count: Int
    let next: String?
    let results: [T]
}

// Modelo do Exercício
struct WgerExercise: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let language: Int
    
    // Imagem será populada depois, pois vem de outra chamada
    var mainImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, language
    }
}

// Modelo da Imagem
struct WgerImage: Codable {
    let id: Int
    let exerciseId: Int
    let image: String // URL da imagem
    
    enum CodingKeys: String, CodingKey {
        case id, image
        case exerciseId = "exercise_base"
    }
}
