import SwiftUI
import FirebaseAuth
import Combine
import FirebaseFirestore

@MainActor
class ProfessionalTreinoViewModel: ObservableObject {
    @Published var nomeTreino = ""
    @Published var exercicios: [Exercicio] = []
    @Published var emailAluno = "" // Profissional digita o email do aluno
    @Published var isLoading = false
    @Published var message = ""
    @Published var showSuccess = false
    
    private let firestoreService = FirestoreService()
    private let db = Firestore.firestore() // Acesso direto para buscar UID pelo email
    
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
            // 1. Buscar o UID do aluno pelo email
            let snapshot = try await db.collection("users")
                .whereField("email", isEqualTo: emailAluno.lowercased())
                .getDocuments()
            
            guard let document = snapshot.documents.first else {
                message = "Aluno não encontrado com este e-mail."
                isLoading = false
                return
            }
            
            let studentUID = document.documentID // O ID do documento é o UID do usuário
            
            // 2. Criar o objeto Treino
            let novoTreino = Treino(
                nome: nomeTreino,
                data: Date(),
                exercicios: exercicios,
                userUID: studentUID, // O DONO do treino é o aluno
                professionalUID: professionalUID // Quem criou foi o profissional
            )
            
            // 3. Salvar
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
        // emailAluno mantemos caso ele queira mandar outro treino pro mesmo aluno
    }
}
