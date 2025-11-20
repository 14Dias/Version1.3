import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    private let firestoreService = FirestoreService()
    
    private init() {}
    
    // MARK: - Authentication Methods
    func signUp(username: String, email: String, password: String, isHealthProfessional: Bool = false) async throws {
        print("🟡 AuthService: Iniciando signUp")
        print("📧 Email: \(email)")
        print("👤 Username: \(username)")
        print("🔐 Password length: \(password.count)")
        print ("👩‍⚕️ Health Professional: \(isHealthProfessional)")
        
        // Verificar se o Firebase está configurado
        guard FirebaseApp.app() != nil else {
            print("🔴 ERRO CRÍTICO: Firebase não está configurado")
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase não configurado"])
        }
        
        // Validação de email
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        guard emailPred.evaluate(with: email) else {
            print("🔴 Email inválido: \(email)")
            throw NSError(domain: "AuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Email inválido"])
        }
        
        // Validação de senha
        guard password.count >= 6 else {
            print("🔴 Senha muito curta: \(password.count) caracteres")
            throw NSError(domain: "AuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Senha deve ter pelo menos 6 caracteres"])
        }
        
        do {
            print("🟡 Tentando criar usuário no Firebase Auth...")
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = result.user
            print("🟢 Usuário criado no Auth: \(user.uid)")
            
            // Atualizar display name
            print("🟡 Atualizando display name...")
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()
            print("🟢 Display name atualizado: \(username)")
            
            // Salvar informações adicionais no Firestore
            print("🟡 Salvando dados no Firestore...")
            let userData = User(
                username: username,
                email: email,
                userUID: user.uid
            )
            try await firestoreService.saveUserData(user: userData)
            print("🟢 Dados do usuário salvos no Firestore")
            
            print("🟢 SignUp concluído com sucesso!")
            
        } catch {
            print("🔴 ERRO no signUp: \(error.localizedDescription)")
            print("Código de erro: \((error as NSError).code)")
            print("Domínio: \((error as NSError).domain)")
            print("Detalhes completos: \(error)")
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("🟡 AuthService: Iniciando signIn para \(email)")
        
        // Validações básicas
        guard !email.isEmpty, !password.isEmpty else {
            throw NSError(domain: "AuthService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Email e senha são obrigatórios"])
        }
        
        do {
            print("🟡 Tentando fazer login no Firebase Auth...")
            try await Auth.auth().signIn(withEmail: email, password: password)
            print("🟢 Login bem-sucedido no Firebase Auth")
        } catch {
            print("🔴 ERRO no signIn: \(error.localizedDescription)")
            print("Código de erro: \((error as NSError).code)")
            print("Domínio: \((error as NSError).domain)")
            throw error
        }
    }
    
    func signOut() throws {
        print("🟡 AuthService: Iniciando signOut")
        try Auth.auth().signOut()
        print("🟢 SignOut bem-sucedido")
    }
    
    func resetPassword(email: String) async throws {
        print("🟡 AuthService: Iniciando resetPassword para \(email)")
        try await Auth.auth().sendPasswordReset(withEmail: email)
        print("🟢 Email de reset enviado")
    }
    
    // MARK: - User Management
    func getCurrentAppUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else {
            print("🔴 Nenhum usuário autenticado")
            return nil
        }
        
        print("🟢 Usuário atual: \(firebaseUser.uid)")
        return User(
            username: firebaseUser.displayName ?? firebaseUser.email?.components(separatedBy: "@").first ?? "Usuário",
            email: firebaseUser.email ?? "",
            userUID: firebaseUser.uid
        )
    }
}
// Services/AuthService.swift - ADIÇÕES
extension AuthService {
    
    // MARK: - Profile Update Methods
    func updateUserProfile(username: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado"])
        }
        
        print("🟡 Atualizando perfil do usuário: \(currentUser.uid)")
        
        // Atualizar display name no Firebase Auth
        let changeRequest = currentUser.createProfileChangeRequest()
        changeRequest.displayName = username
        try await changeRequest.commitChanges()
        
        print("✅ Display name atualizado no Auth: \(username)")
        
        // Atualizar dados no Firestore
        let userData: [String: Any] = [
            "username": username,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await Firestore.firestore().collection("users").document(currentUser.uid).updateData(userData)
        print("✅ Dados do usuário atualizados no Firestore")
    }
    
    func updateUserEmail(newEmail: String, password: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado"])
        }
        
        print("🟡 Atualizando email do usuário: \(currentUser.uid)")
        
        // Reautenticar o usuário antes de mudar o email
        let credential = EmailAuthProvider.credential(withEmail: currentUser.email ?? "", password: password)
        try await currentUser.reauthenticate(with: credential)
        
        // Atualizar email
        try await currentUser.updateEmail(to: newEmail)
        
        // Atualizar no Firestore
        let userData: [String: Any] = [
            "email": newEmail,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await Firestore.firestore().collection("users").document(currentUser.uid).updateData(userData)
        print("✅ Email atualizado para: \(newEmail)")
    }
    
    func updateUserPassword(currentPassword: String, newPassword: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado"])
        }
        
        print("🟡 Atualizando senha do usuário: \(currentUser.uid)")
        
        // Reautenticar o usuário
        let credential = EmailAuthProvider.credential(withEmail: currentUser.email ?? "", password: currentPassword)
        try await currentUser.reauthenticate(with: credential)
        
        // Atualizar senha
        try await currentUser.updatePassword(to: newPassword)
        print("✅ Senha atualizada com sucesso")
    }
    
    func deleteUserAccount(password: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado"])
        }
        
        print("🟡 Iniciando exclusão da conta: \(currentUser.uid)")
        
        // Reautenticar o usuário
        let credential = EmailAuthProvider.credential(withEmail: currentUser.email ?? "", password: password)
        try await currentUser.reauthenticate(with: credential)
        
        // Primeiro deletar todos os dados do usuário no Firestore
        try await deleteUserData(userUID: currentUser.uid)
        
        // Depois deletar a conta no Auth
        try await currentUser.delete()
        print("✅ Conta deletada com sucesso")
    }
    
     func deleteUserData(userUID: String) async throws {
        let db = Firestore.firestore()
        
        // Deletar todos os treinos do usuário
        let treinosSnapshot = try await db.collection("treinos")
            .whereField("userUID", isEqualTo: userUID)
            .getDocuments()
        
        for document in treinosSnapshot.documents {
            // Deletar exercícios deste treino
            let exerciciosSnapshot = try await db.collection("exercicios")
                .whereField("treinoID", isEqualTo: document.documentID)
                .getDocuments()
            
            for exercicioDoc in exerciciosSnapshot.documents {
                try await exercicioDoc.reference.delete()
            }
            
            // Deletar o treino
            try await document.reference.delete()
        }
        
        // Deletar dados do usuário
        try await db.collection("users").document(userUID).delete()
        
        print("✅ Todos os dados do usuário deletados do Firestore")
    }
        func signInWithGoogle(idToken: String, accessToken: String) async throws {
            print("🟡 AuthService: Iniciando signIn com Google")
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            let result = try await Auth.auth().signIn(with: credential)
            let user = result.user
            
            print("🟢 Login com Google bem-sucedido: \(user.uid)")
            
            // Verificar se é um novo usuário
            if let additionalUserInfo = result.additionalUserInfo, additionalUserInfo.isNewUser {
                print("🟢 Novo usuário do Google - salvando dados")
                
                // Criar usuário no Firestore
                let username = user.displayName ?? user.email?.components(separatedBy: "@").first ?? "Usuário"
                let appUser = User(
                    username: username,
                    email: user.email ?? "",
                    userUID: user.uid
                )
                
                try await firestoreService.saveUserData(user: appUser)
                print("✅ Dados do usuário Google salvos no Firestore")
            }
        }
    // Services/AuthService.swift - OTIMIZAÇÕES
   
        func quickSignIn(email: String, password: String) async throws {
            // Método simplificado e rápido
            try await Auth.auth().signIn(withEmail: email, password: password)
        }
        
        func quickSignUp(username: String, email: String, password: String, isHealthProfessional: Bool = false) async throws {
            // Criação rápida de usuário
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = result.user
            
            // Atualização do display name de forma assíncrona
            async let profileUpdate: Void = {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = username
                try await changeRequest.commitChanges()
            }()
            
            // Salvamento no Firestore de forma assíncrona
            async let firestoreSave: Void = {
                let userData = User(
                    username: username,
                    email: email,
                    userUID: user.uid,
                    isHealthProfessional: isHealthProfessional
                )
                try await firestoreService.saveUserData(user: userData)
            }()
            
            // Aguarda ambas as operações
            _ = try await (profileUpdate, firestoreSave)
        }
    }
    


