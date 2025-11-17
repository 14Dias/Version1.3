// Utilities/ErrorHandler.swift - NOVO ARQUIVO
import Foundation
import Combine


enum AppError: LocalizedError, Identifiable {
    case networkError(Error)
    case authError(String)
    case firestoreError(String)
    case validationError(String)
    case unknownError
    
    var id: String {
        switch self {
        case .networkError: return "networkError"
        case .authError: return "authError"
        case .firestoreError: return "firestoreError"
        case .validationError: return "validationError"
        case .unknownError: return "unknownError"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Problema de conexão: \(error.localizedDescription)"
        case .authError(let message):
            return "Erro de autenticação: \(message)"
        case .firestoreError(let message):
            return "Erro no banco de dados: \(message)"
        case .validationError(let message):
            return "Dados inválidos: \(message)"
        case .unknownError:
            return "Erro desconhecido. Tente novamente."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Verifique sua conexão com a internet e tente novamente."
        case .authError:
            return "Faça login novamente ou verifique suas credenciais."
        case .firestoreError:
            return "Os dados podem estar temporariamente indisponíveis. Tente novamente em alguns instantes."
        case .validationError:
            return "Verifique os dados informados e tente novamente."
        case .unknownError:
            return "Reinicie o aplicativo e tente novamente."
        }
    }
}

@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    
    func handle(_ error: Error, context: String = "") {
        print("🔴 Erro em \(context): \(error)")
        
        let appError: AppError
        
        if let firestoreError = error as NSError? {
            switch firestoreError.code {
            case 7: // Network error
                appError = .networkError(error)
            case 3: // Invalid argument
                appError = .validationError("Dados inválidos enviados")
            case 13: // Internal error
                appError = .firestoreError("Erro interno do servidor")
            default:
                appError = .firestoreError(error.localizedDescription)
            }
        } else {
            appError = .unknownError
        }
        
        currentError = appError
        showErrorAlert = true
    }
    
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
}
