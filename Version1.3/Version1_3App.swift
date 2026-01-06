import SwiftUI
import FirebaseCore
import FirebaseAuth

// MARK: - 1. AppDelegate para configuração do Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        print("🔥 Firebase Configurado via AppDelegate")
        
        return true
    }
}

@main
struct Version1_3App: App {
    // MARK: - 2. Conexão do AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // ViewModels Globais
    @StateObject var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            // CORREÇÃO: Usar 'isAuthenticated' em vez de 'isUserLoggedIn'
            if authViewModel.isAuthenticated {
                PaginaInicialView()
                    .environmentObject(authViewModel)
            } else {
                NavigationStack {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}
