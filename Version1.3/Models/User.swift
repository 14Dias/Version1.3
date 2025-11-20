// Models/User.swift - ATUALIZAR
import Foundation

struct User {
    let username: String
    let email: String
    let userUID: String
    let isHealthProfessional: Bool // ADICIONAR ESTA LINHA
    
    // ADICIONAR INICIALIZADOR CONVENIENCE
    init(username: String, email: String, userUID: String, isHealthProfessional: Bool = false) {
        self.username = username
        self.email = email
        self.userUID = userUID
        self.isHealthProfessional = isHealthProfessional
    }
}
