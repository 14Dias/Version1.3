// ViewModels/UserViewModel.swift
import Foundation
import FirebaseAuth
import Combine

@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    
    init() {
        if let firebaseUser = Auth.auth().currentUser {
            self.user = User(
                username: firebaseUser.displayName ?? "",
                email: firebaseUser.email ?? "",
                userUID: firebaseUser.uid
            )
        }
    }
    
    func updateUserProfile(username: String) async -> Bool {
        // Implementar atualização de perfil
        return true
    }
}
