import Foundation
import FirebaseFirestore

struct Conteudo: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let ativo: Bool
    let categoria: String
    let descricao: String
    let duracao: String
    let ordem: Int
    let thumbnail: String
    let titulo: String
    let urlVideo: String
}
