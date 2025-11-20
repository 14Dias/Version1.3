import Combine
import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    func signInWithGoogle() async -> Bool {
        isLoading = true
        errorMessage = ""
        
        guard let clientID = FirebaseApp.app()?.options.clientID,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Erro de configuração do app"
            isLoading = false
            return false
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                throw NSError(domain: "GoogleSignIn", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Falha ao obter token do Google"])
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            // Login rápido com Firebase
            try await Auth.auth().signIn(with: credential)
            
            // Verificação rápida
            if Auth.auth().currentUser != nil {
                isLoading = false
                return true
            } else {
                throw NSError(domain: "GoogleSignIn", code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "Falha na autenticação com Firebase"])
            }
            
        } catch {
            errorMessage = "Erro ao fazer login com Google: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
