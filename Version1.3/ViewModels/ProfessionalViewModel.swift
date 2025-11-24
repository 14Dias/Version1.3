// Arquivo: Version1.3/ViewModels/ProfessionalViewModel.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ProfessionalViewModel: ObservableObject {
    @Published var nomeTreino = ""
    @Published var exercicios: [Exercicio] = []
    @Published var emailAluno = ""
    @Published var isLoading = false
    @Published var message = ""
    @Published var showSuccess = false
    
    private let firestoreService = FirestoreService()
    private let db = Firestore.firestore()
    
    func enviarTreinoParaAluno() async {
        guard !nomeTreino.isEmpty, !exercicios.isEmpty, !emailAluno.isEmpty else {
            message = "Preencha todos os campos."
            return
        }
        
        guard let professionalUID = Auth.auth().currentUser?.uid else {
            message = "Erro: Profissional não autenticado."
            return
        }
        
        isLoading = true
        message = "Buscando aluno..."
        
        do {
            // 1. Busca o aluno pelo email (Case insensitive é difícil no Firestore simples, então forçamos lowercase)
            let snapshot = try await db.collection("users")
                .whereField("email", isEqualTo: emailAluno.trimmingCharacters(in: .whitespaces).lowercased())
                .getDocuments()
            
            guard let document = snapshot.documents.first else {
                message = "Aluno não encontrado com este e-mail."
                isLoading = false
                return
            }
            
            let studentUID = document.documentID // O ID do documento é o UID do usuário
            
            // 2. Cria o objeto Treino
            // O 'userUID' é o ID do ALUNO (quem vai receber/fazer o treino)
            // O 'professionalUID' é o seu ID (quem criou)
            let novoTreino = Treino(
                nome: nomeTreino,
                data: Date(),
                exercicios: exercicios,
                userUID: studentUID,
                professionalUID: professionalUID
            )
            
            // 3. Salva usando o serviço existente
            try await firestoreService.saveTreino(novoTreino)
            
            message = "Treino enviado com sucesso para o aluno!"
            showSuccess = true
            limparCampos()
            
        } catch {
            message = "Erro: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func adicionarExercicio(_ exercicio: Exercicio) {
        exercicios.append(exercicio)
    }
    
    func limparCampos() {
        nomeTreino = ""
        exercicios = []
        // emailAluno mantemos caso queira mandar outro para o mesmo
    }
}
